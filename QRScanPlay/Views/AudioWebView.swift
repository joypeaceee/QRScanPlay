//
//  AudioWebView.swift
//  QRScanPlay
//
//  WebView that loads audio guide pages and auto-plays audio content.
//

import Combine
import SwiftUI
import WebKit

// Notification to trigger native audio playback
extension Notification.Name {
    static let playAudioNatively = Notification.Name("playAudioNatively")
}

// Reference class to allow triggering play from outside the WebView
class WebViewReference: ObservableObject {
    weak var webView: WKWebView?
    
    func triggerPlay() {
        guard let webView = webView else { return }
        
        // First, try to extract the audio source URL and play natively
        let extractAudioScript = """
        (function() {
            // Look for audio sources
            var audioSources = [];
            
            // Check audio elements
            var audios = document.querySelectorAll('audio');
            audios.forEach(function(audio) {
                if (audio.src) audioSources.push(audio.src);
                if (audio.currentSrc) audioSources.push(audio.currentSrc);
                var sources = audio.querySelectorAll('source');
                sources.forEach(function(s) {
                    if (s.src) audioSources.push(s.src);
                });
            });
            
            // Check for data attributes that might contain audio URLs
            var dataElements = document.querySelectorAll('[data-audio-src], [data-src], [data-audio-url], [data-url]');
            dataElements.forEach(function(el) {
                var src = el.getAttribute('data-audio-src') || el.getAttribute('data-src') || el.getAttribute('data-audio-url') || el.getAttribute('data-url');
                if (src && (src.includes('.mp3') || src.includes('.m4a') || src.includes('.wav') || src.includes('audio'))) {
                    audioSources.push(src);
                }
            });
            
            // Check for links to audio files
            var links = document.querySelectorAll('a[href*=".mp3"], a[href*=".m4a"], a[href*=".wav"]');
            links.forEach(function(link) {
                audioSources.push(link.href);
            });
            
            // Look in script tags for audio URLs (common pattern)
            var scripts = document.querySelectorAll('script');
            scripts.forEach(function(script) {
                var text = script.textContent || '';
                var matches = text.match(/https?:\\/\\/[^"'\\s]+\\.(mp3|m4a|wav|aac)/gi);
                if (matches) {
                    matches.forEach(function(m) { audioSources.push(m); });
                }
            });
            
            // Return unique sources
            var unique = [...new Set(audioSources)];
            console.log('[QRScanPlay] Found audio sources:', JSON.stringify(unique));
            return JSON.stringify(unique);
        })();
        """
        
        webView.evaluateJavaScript(extractAudioScript) { [weak self] result, error in
            if let jsonString = result as? String,
               let data = jsonString.data(using: .utf8),
               let sources = try? JSONDecoder().decode([String].self, from: data),
               let firstSource = sources.first,
               let audioURL = URL(string: firstSource) {
                NSLog("[AudioWebView] Found audio source: \(firstSource)")
                // Post notification to play this URL natively
                NotificationCenter.default.post(name: .playAudioNatively, object: audioURL)
            } else {
                // Fall back to clicking play buttons
                NSLog("[AudioWebView] No direct audio source found, trying click approach")
                self?.triggerClickPlay()
            }
        }
    }
    
    func triggerClickPlay() {
        guard let webView = webView else { return }
        
        let playScript = """
        (function() {
            console.log('[QRScanPlay] User tapped - triggering audio play...');
            
            // Debug: Log all audio elements and their state
            var audios = document.querySelectorAll('audio');
            console.log('[QRScanPlay] Found ' + audios.length + ' audio elements');
            audios.forEach(function(audio, i) {
                console.log('[QRScanPlay] Audio ' + i + ': src=' + audio.src + ', currentSrc=' + audio.currentSrc + ', readyState=' + audio.readyState + ', networkState=' + audio.networkState + ', paused=' + audio.paused + ', error=' + (audio.error ? audio.error.message : 'none'));
                
                // Add event listeners to debug
                audio.addEventListener('error', function(e) {
                    console.log('[QRScanPlay] Audio error event:', e.target.error ? e.target.error.message : 'unknown');
                });
                audio.addEventListener('loadstart', function() { console.log('[QRScanPlay] Audio loadstart'); });
                audio.addEventListener('loadeddata', function() { console.log('[QRScanPlay] Audio loadeddata'); });
                audio.addEventListener('canplay', function() { console.log('[QRScanPlay] Audio canplay'); });
                audio.addEventListener('playing', function() { console.log('[QRScanPlay] Audio playing!'); });
            });
            
            // 1. Play all audio elements
            var audios = document.querySelectorAll('audio');
            audios.forEach(function(audio) {
                audio.muted = false;
                audio.volume = 1.0;
                audio.play().then(function() {
                    console.log('[QRScanPlay] Audio playing!');
                }).catch(function(e) {
                    console.log('[QRScanPlay] Audio play failed:', e.message);
                });
            });
            
            // 2. Play all video elements
            var videos = document.querySelectorAll('video');
            videos.forEach(function(video) {
                video.muted = false;
                video.volume = 1.0;
                video.play().catch(function(e) {});
            });
            
            // 3. Click all play buttons
            var playSelectors = [
                'button[class*="play"]',
                'button[id*="play"]',
                'button[aria-label*="play" i]',
                'button[aria-label*="Play" i]',
                '[role="button"][class*="play"]',
                '.play-button',
                '.play-btn',
                '.btn-play',
                '.audio-play',
                '.playButton',
                '.PlayButton',
                '[data-action="play"]',
                '[data-play]',
                '.audio-player__play',
                '.audio__play',
                '.track-play',
                '.playlist-play',
                '.audio-player button:first-child',
                '.audio-container button:first-child',
                // More generic - any button with play in its text
                'button'
            ];
            
            var clicked = false;
            playSelectors.forEach(function(selector) {
                try {
                    var elements = document.querySelectorAll(selector);
                    elements.forEach(function(el) {
                        var text = (el.innerText || el.textContent || '').toLowerCase();
                        var ariaLabel = (el.getAttribute('aria-label') || '').toLowerCase();
                        var className = (el.className || '').toLowerCase();
                        
                        if (text.includes('play') || ariaLabel.includes('play') || className.includes('play') || selector.includes('play')) {
                            console.log('[QRScanPlay] Clicking play button:', selector);
                            el.click();
                            clicked = true;
                        }
                    });
                } catch(e) {}
            });
            
            // 4. Also try clicking the first visible button if nothing else worked
            if (!clicked) {
                var firstButton = document.querySelector('.audio-player button, .player button, button[class*="control"]');
                if (firstButton) {
                    console.log('[QRScanPlay] Clicking first control button');
                    firstButton.click();
                }
            }
            
            return 'Play triggered by user tap';
        })();
        """
        
        webView.evaluateJavaScript(playScript) { result, error in
            if let error = error {
                NSLog("[AudioWebView] Play trigger error: \(error.localizedDescription)")
            } else {
                NSLog("[AudioWebView] Play triggered: \(String(describing: result))")
            }
        }
    }
}

struct AudioWebView: UIViewRepresentable {
    let url: URL
    var webViewRef: WebViewReference
    var onFinishedLoading: (() -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Allow autoplay
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.allowsBackForwardNavigationGestures = false
        
        // Enable JavaScript alert/confirm handling
        webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        // Store reference for external access
        webViewRef.webView = webView
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Update reference
        webViewRef.webView = webView
        
        // Only load if URL is different AND we're not already loading
        let currentURLString = webView.url?.absoluteString
        let newURLString = url.absoluteString
        
        if currentURLString != newURLString && !webView.isLoading {
            NSLog("[AudioWebView] Loading new URL: \(newURLString)")
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: AudioWebView
        
        init(_ parent: AudioWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.onFinishedLoading?()
            NSLog("[AudioWebView] Page loaded - waiting for user tap to play audio")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            NSLog("[AudioWebView] Navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            NSLog("[AudioWebView] Provisional navigation failed: \(error.localizedDescription)")
        }
        
        // Handle JavaScript alerts
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            NSLog("[AudioWebView] JS Alert: \(message)")
            completionHandler()
        }
        
        // Handle new window requests (some players open in new windows)
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Load the URL in the same webview instead of opening new window
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
    }
}
