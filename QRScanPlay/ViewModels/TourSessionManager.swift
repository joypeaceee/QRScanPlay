//
//  TourSessionManager.swift
//  QRScanPlay
//
//  Manages the museum tour session state and coordinates voice → scan → play flow.
//

import AVFoundation
import Combine
import MWDATCamera
import MWDATCore
import SwiftUI
import Vision

enum TourState: Equatable {
    case idle
    case connecting
    case listening
    case scanning
    case loading
    case playing
    case error(String)

    var statusText: String {
        switch self {
        case .idle:
            return "Ready"
        case .connecting:
            return "Connecting to glasses..."
        case .listening:
            return "Say 'Scan this QR code' or tap Scan"
        case .scanning:
            return "Scanning..."
        case .loading:
            return "Loading audio..."
        case .playing:
            return "Playing audio"
        case .error(let message):
            return message
        }
    }

    var isSessionActive: Bool {
        switch self {
        case .listening, .scanning, .loading, .playing:
            return true
        default:
            return false
        }
    }
}

@MainActor
class TourSessionManager: ObservableObject {
    @Published var tourState: TourState = .idle
    @Published var currentURL: URL?
    @Published var currentVideoFrame: UIImage?
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var hasReceivedFirstFrame: Bool = false

    // StreamSession created lazily when tour starts (device must be connected first)
    private var streamSession: StreamSession?
    private var stateListenerToken: AnyListenerToken?
    private var videoFrameListenerToken: AnyListenerToken?
    private var errorListenerToken: AnyListenerToken?

    private let wearables: WearablesInterface
    private var qrDetectionRequest: VNDetectBarcodesRequest?
    private var lastDetectedQRCode: String?
    private var qrDetectionCooldown: Date = .distantPast

    init(wearables: WearablesInterface) {
        self.wearables = wearables
        setupQRDetection()
        // Don't create StreamSession here - wait until startTour() when device is connected
    }

    private func setupQRDetection() {
        qrDetectionRequest = VNDetectBarcodesRequest { [weak self] request, error in
            Task { @MainActor [weak self] in
                self?.handleQRDetectionResult(request: request, error: error)
            }
        }
        qrDetectionRequest?.symbologies = [.qr]
    }

    private func createStreamSession() {
        NSLog("[TourSession] Creating new StreamSession...")
        
        // Clean up old session if exists
        cleanupStreamSession()
        
        let deviceSelector = AutoDeviceSelector(wearables: wearables)
        let config = StreamSessionConfig(
            videoCodec: .raw,
            resolution: .low,
            frameRate: 24
        )
        let session = StreamSession(streamSessionConfig: config, deviceSelector: deviceSelector)
        streamSession = session
        
        setupStreamListeners(for: session)
        NSLog("[TourSession] StreamSession created and listeners attached")
    }
    
    private func cleanupStreamSession() {
        stateListenerToken = nil
        videoFrameListenerToken = nil
        errorListenerToken = nil
        streamSession = nil
    }
    
    private func setupStreamListeners(for session: StreamSession) {
        // Subscribe to session state changes
        stateListenerToken = session.statePublisher.listen { [weak self] state in
            Task { @MainActor [weak self] in
                NSLog("[TourSession] Stream state changed to: \(state)")
                self?.handleStreamStateChange(state)
            }
        }

        // Subscribe to video frames
        videoFrameListenerToken = session.videoFramePublisher.listen { [weak self] videoFrame in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let image = videoFrame.makeUIImage()
                self.currentVideoFrame = image
                
                if !self.hasReceivedFirstFrame {
                    self.hasReceivedFirstFrame = true
                    NSLog("[TourSession] Received first video frame")
                }
                
                if self.tourState == .scanning {
                    self.processFrameForQR(videoFrame)
                }
            }
        }

        // Subscribe to streaming errors
        errorListenerToken = session.errorPublisher.listen { [weak self] error in
            Task { @MainActor [weak self] in
                NSLog("[TourSession] Stream error: \(error)")
                self?.handleStreamError(error)
            }
        }
    }

    func startTour() async {
        // Allow starting from idle or any error state
        switch tourState {
        case .idle, .error:
            break
        default:
            return
        }

        tourState = .connecting
        hasReceivedFirstFrame = false

        // Check device connectivity first
        let devices = wearables.devices
        NSLog("[TourSession] Available devices: \(devices.count)")
        for device in devices {
            NSLog("[TourSession] Device: \(device)")
        }

        let permission = Permission.camera
        do {
            let status = try await wearables.checkPermissionStatus(permission)
            NSLog("[TourSession] Camera permission status: \(status)")
            if status != .granted {
                let requestStatus = try await wearables.requestPermission(permission)
                NSLog("[TourSession] Camera permission request result: \(requestStatus)")
                if requestStatus != .granted {
                    tourState = .error("Camera permission denied")
                    return
                }
            }

            // Create StreamSession now that we're about to start
            createStreamSession()
            
            guard let session = streamSession else {
                tourState = .error("Failed to create stream session")
                return
            }

            NSLog("[TourSession] Starting stream session...")
            await session.start()
            NSLog("[TourSession] Stream session start() completed, current state: \(session.state)")
            // State will be updated via the listener
        } catch {
            NSLog("[TourSession] Permission error: \(error)")
            tourState = .error("Permission error: \(error.localizedDescription)")
        }
    }

    func stopTour() {
        NSLog("[TourSession] Stopping tour...")
        
        if let session = streamSession {
            Task {
                await session.stop()
            }
        }
        
        currentURL = nil
        currentVideoFrame = nil
        lastDetectedQRCode = nil
        hasReceivedFirstFrame = false
        tourState = .idle
        
        // Clean up the session after stopping
        cleanupStreamSession()
    }

    func triggerScan() {
        guard tourState == .listening || tourState == .playing else { 
            NSLog("[TourSession] triggerScan ignored - state is \(tourState)")
            return 
        }
        NSLog("[TourSession] triggerScan - changing to scanning state")
        tourState = .scanning
        lastDetectedQRCode = nil
    }

    private func handleStreamStateChange(_ state: StreamSessionState) {
        switch state {
        case .stopped:
            if tourState.isSessionActive {
                tourState = .idle
            }
            currentVideoFrame = nil
        case .waitingForDevice:
            NSLog("[TourSession] Waiting for device...")
        case .streaming:
            NSLog("[TourSession] Now streaming - transitioning to listening")
            if tourState == .connecting {
                tourState = .listening
            }
        case .starting:
            NSLog("[TourSession] Stream starting...")
        case .stopping:
            NSLog("[TourSession] Stream stopping...")
        case .paused:
            NSLog("[TourSession] Stream paused")
        @unknown default:
            NSLog("[TourSession] Unknown stream state")
        }
    }

    private func handleStreamError(_ error: StreamSessionError) {
        let message: String
        switch error {
        case .deviceNotFound:
            message = "Glasses not found. Please ensure your glasses are connected."
        case .deviceNotConnected:
            message = "Glasses disconnected. Please reconnect your glasses."
        case .permissionDenied:
            message = "Camera permission denied"
        case .timeout:
            message = "Connection timed out. Please try again."
        case .internalError:
            message = "Internal streaming error. Please try again."
        case .videoStreamingError:
            message = "Video streaming error"
        @unknown default:
            message = "Streaming error occurred"
        }
        
        NSLog("[TourSession] Handling stream error: \(message)")
        
        // Only show error if we're in an active session state
        if tourState.isSessionActive || tourState == .connecting {
            showError = true
            errorMessage = message
            tourState = .error(message)
        }
    }

    private func processFrameForQR(_ videoFrame: VideoFrame) {
        guard let cgImage = videoFrame.makeUIImage()?.cgImage else { return }

        guard Date() > qrDetectionCooldown else { return }
        qrDetectionCooldown = Date().addingTimeInterval(0.3)

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        Task.detached { [weak self] in
            guard let request = await self?.qrDetectionRequest else { return }
            try? handler.perform([request])
        }
    }

    private func handleQRDetectionResult(request: VNRequest, error: Error?) {
        guard tourState == .scanning else { return }

        guard let results = request.results as? [VNBarcodeObservation],
              let firstQR = results.first,
              let payloadString = firstQR.payloadStringValue else {
            return
        }

        guard payloadString != lastDetectedQRCode else { return }
        lastDetectedQRCode = payloadString
        
        NSLog("[TourSession] QR Code detected: \(payloadString)")

        if let url = URL(string: payloadString), url.scheme?.hasPrefix("http") == true {
            tourState = .loading
            currentURL = url

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                if self?.tourState == .loading {
                    self?.tourState = .playing
                }
            }
        } else {
            tourState = .error("Invalid QR code - not a valid URL")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                if case .error = self?.tourState {
                    self?.tourState = .listening
                }
            }
        }
    }

    func onWebViewFinishedLoading() {
        if tourState == .loading {
            tourState = .playing
        }
    }

    func clearError() {
        if case .error = tourState {
            tourState = .listening
        }
        showError = false
    }
}
