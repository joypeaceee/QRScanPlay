//
//  TourView.swift
//  QRScanPlay
//
//  Main tour interface with Start/Stop button and WebView for audio playback.
//

import MWDATCore
import SwiftUI

struct TourView: View {
    @ObservedObject var tourManager: TourSessionManager
    @ObservedObject var wearablesVM: WearablesViewModel
    @State private var showPlayOverlay: Bool = false
    @State private var webViewRef: WebViewReference = WebViewReference()
    @State private var nativeAudioURL: URL? = nil

    // Check if URL is a direct audio file
    private var isDirectAudioURL: Bool {
        guard let url = tourManager.currentURL else { return false }
        let audioExtensions = ["mp3", "wav", "m4a", "aac", "ogg", "flac", "aiff"]
        let pathExtension = url.pathExtension.lowercased()
        return audioExtensions.contains(pathExtension)
    }
    
    // Check if we should show native player (either direct URL or extracted from webpage)
    private var shouldShowNativePlayer: Bool {
        return isDirectAudioURL || nativeAudioURL != nil
    }
    
    private var audioURLToPlay: URL? {
        return nativeAudioURL ?? tourManager.currentURL
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            Text("Museum Tour Guide")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 16)
                .padding(.bottom, 8)

            // Content area
            ZStack {
                Color(.systemGray6)
                    .cornerRadius(12)

                if let url = tourManager.currentURL {
                    if shouldShowNativePlayer, let audioURL = audioURLToPlay {
                        // Use native AVPlayer for direct audio files or extracted audio URLs
                        AudioPlayerView(url: audioURL)
                            .cornerRadius(12)
                    } else {
                        // Use WebView for web pages
                        AudioWebView(
                            url: url,
                            webViewRef: webViewRef,
                            onFinishedLoading: {
                                tourManager.onWebViewFinishedLoading()
                                showPlayOverlay = true
                            }
                        )
                        .cornerRadius(12)
                        
                        // "Tap to Play" overlay for web pages
                        if showPlayOverlay {
                            Color.black.opacity(0.6)
                                .cornerRadius(12)
                                .overlay(
                                    VStack(spacing: 20) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 80))
                                            .foregroundColor(.white)
                                        
                                        Text("Tap to Play Audio")
                                            .font(.system(size: 22, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Text("Audio requires a tap to start")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        // Open in Safari fallback
                                        Button(action: {
                                            if let url = tourManager.currentURL {
                                                UIApplication.shared.open(url)
                                            }
                                        }) {
                                            HStack {
                                                Image(systemName: "safari")
                                                Text("Open in Safari")
                                            }
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.white.opacity(0.2))
                                            .cornerRadius(8)
                                        }
                                        .padding(.top, 8)
                                    }
                                )
                                .onTapGesture {
                                    showPlayOverlay = false
                                    webViewRef.triggerPlay()
                                }
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)

                        Text("Scan a QR code to start\nlistening to the audio guide")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                // Camera preview overlay when scanning
                if tourManager.tourState == .scanning {
                    if let frame = tourManager.currentVideoFrame {
                        Image(uiImage: frame)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 3)
                            )
                    }

                    VStack {
                        Spacer()
                        Text("Point at QR code...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                            .padding(.bottom, 16)
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity)

            Spacer()

            // Bottom control area
            VStack(spacing: 16) {
                // Status text
                HStack {
                    statusIcon
                    Text(tourManager.tourState.statusText)
                        .font(.system(size: 15))
                        .foregroundColor(statusColor)
                }
                .padding(.horizontal)

                // Action buttons
                HStack(spacing: 12) {
                    if tourManager.tourState.isSessionActive {
                        // Scan button
                        Button(action: {
                            tourManager.triggerScan()
                        }) {
                            HStack {
                                Image(systemName: "qrcode.viewfinder")
                                Text("Scan QR")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(tourManager.tourState == .scanning ? Color.gray : Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(tourManager.tourState == .scanning)

                        // Stop button
                        Button(action: {
                            tourManager.stopTour()
                        }) {
                            HStack {
                                Image(systemName: "stop.fill")
                                Text("Stop Tour")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                    } else {
                        // Start button
                        Button(action: {
                            Task {
                                await tourManager.startTour()
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text(tourManager.tourState == .connecting ? "Connecting..." : "Start Tour")
                            }
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(tourManager.tourState == .connecting ? Color.gray : Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(tourManager.tourState == .connecting)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemBackground))
        .onChange(of: tourManager.currentURL) { _, _ in
            showPlayOverlay = false
            nativeAudioURL = nil  // Reset when new URL is scanned
        }
        .onReceive(NotificationCenter.default.publisher(for: .playAudioNatively)) { notification in
            if let audioURL = notification.object as? URL {
                NSLog("[TourView] Received native audio URL: \(audioURL.absoluteString)")
                nativeAudioURL = audioURL
                showPlayOverlay = false
            }
        }
    }

    private var statusIcon: some View {
        Group {
            switch tourManager.tourState {
            case .idle:
                Image(systemName: "circle")
                    .foregroundColor(.secondary)
            case .connecting:
                ProgressView()
                    .scaleEffect(0.8)
            case .listening:
                Image(systemName: "ear.and.waveform")
                    .foregroundColor(.green)
            case .scanning:
                Image(systemName: "qrcode.viewfinder")
                    .foregroundColor(.blue)
            case .loading:
                ProgressView()
                    .scaleEffect(0.8)
            case .playing:
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(.green)
            case .error:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }

    private var statusColor: Color {
        switch tourManager.tourState {
        case .error:
            return .red
        case .playing:
            return .green
        case .scanning, .listening:
            return .blue
        default:
            return .secondary
        }
    }
}
