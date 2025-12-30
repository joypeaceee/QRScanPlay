//
//  AudioPlayerView.swift
//  QRScanPlay
//
//  Native audio player for direct audio URLs (MP3, WAV, etc.)
//

import AVFoundation
import Combine
import SwiftUI

class AudioPlayerManager: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isLoading: Bool = true
    @Published var error: String?
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Use .playback category for background audio playback
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            NSLog("[AudioPlayer] Audio session configured for background playback")
        } catch {
            NSLog("[AudioPlayer] Failed to configure audio session: \(error)")
        }
    }
    
    func loadAudio(from url: URL) {
        NSLog("[AudioPlayer] Loading audio from: \(url.absoluteString)")
        
        // Ensure audio session is active
        setupAudioSession()
        
        isLoading = true
        error = nil
        currentTime = 0
        duration = 0
        
        // Clean up previous player
        stop()
        
        // Create player item and player
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Observe player item status
        playerItem?.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    self?.isLoading = false
                    self?.duration = self?.playerItem?.duration.seconds ?? 0
                    NSLog("[AudioPlayer] Ready to play, duration: \(self?.duration ?? 0)s")
                case .failed:
                    self?.isLoading = false
                    self?.error = self?.playerItem?.error?.localizedDescription ?? "Failed to load audio"
                    NSLog("[AudioPlayer] Failed: \(self?.error ?? "unknown")")
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Observe playback
        player?.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.isPlaying = status == .playing
            }
            .store(in: &cancellables)
        
        // Add time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
    }
    
    func play() {
        NSLog("[AudioPlayer] Play")
        player?.play()
    }
    
    func pause() {
        NSLog("[AudioPlayer] Pause")
        player?.pause()
    }
    
    func stop() {
        player?.pause()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        player = nil
        playerItem = nil
        cancellables.removeAll()
        isPlaying = false
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }
    
    deinit {
        stop()
    }
}

struct AudioPlayerView: View {
    let url: URL
    @StateObject private var playerManager = AudioPlayerManager()
    @State private var hasStartedPlaying = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Audio icon
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.blue)
            
            // Title
            Text("Audio Guide")
                .font(.system(size: 24, weight: .bold))
            
            // URL display
            Text(url.lastPathComponent)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            if playerManager.isLoading {
                ProgressView("Loading audio...")
                    .padding()
            } else if let error = playerManager.error {
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                // Progress bar
                VStack(spacing: 8) {
                    ProgressView(value: playerManager.currentTime, total: max(playerManager.duration, 1))
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    HStack {
                        Text(formatTime(playerManager.currentTime))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatTime(playerManager.duration))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Play/Pause button
                Button(action: {
                    if playerManager.isPlaying {
                        playerManager.pause()
                    } else {
                        playerManager.play()
                    }
                }) {
                    Image(systemName: playerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .onAppear {
            playerManager.loadAudio(from: url)
        }
        .onDisappear {
            playerManager.stop()
        }
        .onChange(of: playerManager.isLoading) { _, isLoading in
            // Auto-play when loaded
            if !isLoading && !hasStartedPlaying && playerManager.error == nil {
                hasStartedPlaying = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    playerManager.play()
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && !time.isNaN else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
