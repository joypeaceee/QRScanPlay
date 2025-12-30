# Product Requirements Document: Museum Tour with AI Glasses

## Overview

A simple iOS app that enables hands-free museum audio tours using Meta AI glasses. Users can voice-command the glasses to scan QR codes on museum exhibits, and the app automatically opens and plays the audio guide from the linked webpage through the glasses' speakers.

---

## Problem Statement

**User Problem:** "I want to listen to a museum audio guide from a QR code with voice only, without needing to take out my phone."

**Current Pain Points:**
- Museum visitors must constantly pull out their phone to scan QR codes
- Scanning disrupts the viewing experience and creates friction
- Handling phones while looking at exhibits is awkward
- Existing solutions require manual interaction with the phone screen

---

## User Journey

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  1. Open App    │────▶│  2. Press Start │────▶│  3. Session     │
│  on iPhone      │     │  to begin tour  │     │  Active         │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                         │
                                                         ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  6. Audio plays │◀────│  5. App opens   │◀────│  4. User says   │
│  on glasses     │     │  link in WebView│     │  "Scan this     │
│  speakers       │     │  & auto-plays   │     │  QR code"       │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                         │
                                                         ▼
                                               ┌─────────────────┐
                                               │  7. Repeat 4-6  │
                                               │  for each       │
                                               │  exhibit        │
                                               └────────┬────────┘
                                                         │
                                                         ▼
                                               ┌─────────────────┐
                                               │  8. Press Stop  │
                                               │  to end tour    │
                                               └─────────────────┘
```

---

## Functional Requirements

### Core Features

| ID | Feature | Description | Priority |
|----|---------|-------------|----------|
| F1 | Start Tour | User taps "Start" button to begin museum tour session | Must Have |
| F2 | Stop Tour | User taps "Stop" button to end museum tour session | Must Have |
| F3 | Voice Command Recognition | Glasses listen for "Scan this QR code" command during active session | Must Have |
| F4 | QR Code Scanning | Glasses camera captures and decodes QR code when commanded | Must Have |
| F5 | WebView Display | Open QR code URL in embedded WebView within the app | Must Have |
| F6 | Auto-Play Audio | Automatically trigger audio playback on loaded webpage | Must Have |
| F7 | Glasses Speaker Output | Route audio playback through AI glasses speakers | Must Have |

### Out of Scope (Explicitly Excluded)

- ❌ User authentication / login
- ❌ Backend server
- ❌ User accounts
- ❌ History / saved tours
- ❌ Custom audio player UI
- ❌ Offline mode
- ❌ Multiple language support
- ❌ Accessibility features (beyond basic iOS defaults)
- ❌ Analytics / tracking

---

## Technical Architecture

### Dependencies

| Component | Technology | Purpose |
|-----------|------------|---------|
| Meta DAT SDK | `MWDATCore`, `MWDATCamera` | Glasses connection, camera access, audio routing |
| iOS WebKit | `WKWebView` | Display webpage from QR code |
| iOS AVFoundation | Audio routing | Ensure audio goes to glasses |
| iOS Vision | QR code detection | Decode QR codes from camera frames |

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    iOS App (SwiftUI)                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────┐     ┌─────────────────────────┐   │
│  │   UI Layer      │     │   WebView Container     │   │
│  │  - Start Button │     │   - Displays URL        │   │
│  │  - Stop Button  │     │   - Auto-plays audio    │   │
│  │  - Status       │     │                         │   │
│  └────────┬────────┘     └────────────▲────────────┘   │
│           │                           │                 │
│           ▼                           │                 │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Session Manager                     │   │
│  │  - Manages tour state (active/inactive)         │   │
│  │  - Coordinates voice → scan → play flow         │   │
│  └────────┬─────────────────────────────▲──────────┘   │
│           │                             │               │
│           ▼                             │               │
│  ┌───────────────────┐    ┌─────────────────────────┐  │
│  │  Voice Handler    │    │   QR Scanner            │  │
│  │  - Listen for     │    │   - Process frames      │  │
│  │    "scan this     │───▶│   - Detect QR codes     │  │
│  │    QR code"       │    │   - Extract URL         │  │
│  └───────────────────┘    └─────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│              Meta Wearables DAT SDK                     │
├─────────────────────────────────────────────────────────┤
│  - Device connection (WearablesInterface)               │
│  - Camera streaming (StreamSession)                     │
│  - Audio output routing                                 │
│  - Voice command (if available via Meta AI)             │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│              Meta AI Glasses (Hardware)                 │
├─────────────────────────────────────────────────────────┤
│  - Camera                                               │
│  - Microphone (voice input)                             │
│  - Speakers (audio output)                              │
└─────────────────────────────────────────────────────────┘
```

---

## User Interface Design

### Screen Layout

```
┌─────────────────────────────────────────┐
│            Museum Tour Guide            │  ← Title Bar
├─────────────────────────────────────────┤
│                                         │
│                                         │
│                                         │
│         ┌─────────────────────┐         │
│         │                     │         │
│         │     WebView         │         │
│         │  (Audio content     │         │
│         │   from QR code)     │         │  ← WebView Container
│         │                     │         │      (80% of screen)
│         │                     │         │
│         │                     │         │
│         └─────────────────────┘         │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  Status: [Ready / Listening / Playing]  │  ← Status Text
│                                         │
│         ┌───────────────────┐           │
│         │                   │           │
│         │   START / STOP    │           │  ← Primary Action Button
│         │                   │           │
│         └───────────────────┘           │
│                                         │
└─────────────────────────────────────────┘
```

### UI States

| State | Button Text | Status Text | WebView |
|-------|-------------|-------------|---------|
| Idle | "Start Tour" | "Ready" | Empty/placeholder |
| Connecting | "Start Tour" (disabled) | "Connecting to glasses..." | Empty |
| Listening | "Stop Tour" | "Say 'Scan this QR code'" | Previous content or empty |
| Scanning | "Stop Tour" | "Scanning..." | Previous content |
| Loading | "Stop Tour" | "Loading audio..." | Loading URL |
| Playing | "Stop Tour" | "Playing audio" | Loaded webpage |
| Error | "Start Tour" | Error message | Empty |

---

## Technical Assumptions & Constraints

### Assumptions

1. **Voice Command:** Meta AI glasses have a built-in voice assistant that can recognize "Scan this QR code" and trigger an action in the app
   - *Fallback:* If voice isn't available via SDK, we may need to use continuous camera scanning or a physical button tap trigger
   
2. **Audio Routing:** Audio from WKWebView can be routed to Bluetooth audio device (glasses)
   - iOS typically routes audio to connected Bluetooth devices automatically
   
3. **Auto-Play Audio:** The museum webpages have a standard HTML5 audio player that can be triggered via JavaScript injection

4. **QR Code Format:** QR codes contain direct HTTPS URLs (not custom schemes)

### Constraints

1. **iOS 17.0+** required (per DAT SDK requirements)
2. **Meta AI Glasses** required (Ray-Ban Meta, etc.)
3. **Developer Mode** must be enabled in Meta AI app
4. **Camera Permission** must be granted for QR scanning
5. **Bluetooth** must be connected to glasses for audio output

---

## Open Questions / Risks

| # | Question/Risk | Impact | Mitigation |
|---|---------------|--------|------------|
| 1 | How is voice command "scan this QR code" detected? Is it via Meta AI platform or in-app speech recognition? | High - Core feature | Research Meta AI voice SDK; fallback to iOS Speech framework |
| 2 | Can we auto-play audio in WKWebView without user interaction? Safari has autoplay restrictions. | High - Core feature | JavaScript injection to simulate click; ensure audio is muted initially then unmuted |
| 3 | Will audio automatically route to glasses speakers? | Medium | Test with actual hardware; may need AVAudioSession configuration |
| 4 | QR scan latency - how quickly can we process frames and detect QR? | Medium - UX | Optimize Vision framework usage; use appropriate resolution |

---

## Success Criteria

1. ✅ User can start/stop a tour session with one tap
2. ✅ Voice command "scan this QR code" triggers camera capture
3. ✅ QR code is decoded and URL is extracted within 2 seconds
4. ✅ Webpage loads in embedded WebView
5. ✅ Audio plays automatically without additional user interaction
6. ✅ Audio is heard through glasses speakers (not phone speaker)

---

## Implementation Phases

### Phase 1: Basic App Shell (MVP)
- [ ] Create new iOS project with SwiftUI
- [ ] Integrate Meta DAT SDK
- [ ] Implement glasses connection (reuse CameraAccess patterns)
- [ ] Basic UI with Start/Stop button
- [ ] WebView container

### Phase 2: QR Scanning
- [ ] Start camera stream when session active
- [ ] Process video frames with Vision framework
- [ ] Detect and decode QR codes
- [ ] Extract URL from QR code

### Phase 3: Voice Command
- [ ] Research/implement voice trigger mechanism
- [ ] Integrate with QR scanning flow
- [ ] Handle voice command → scan → result flow

### Phase 4: Audio Playback
- [ ] Load URL in WebView
- [ ] Implement JavaScript injection for auto-play
- [ ] Configure audio session for Bluetooth output
- [ ] Test end-to-end with real museum content

---

## Appendix

### Reference: CameraAccess Sample App Patterns

The Meta DAT SDK CameraAccess sample app demonstrates:

- **Device Connection:** `WearablesViewModel` handles `WearablesInterface` for glasses pairing
- **Streaming:** `StreamSessionViewModel` manages `StreamSession` for camera frames
- **Frame Processing:** `videoFramePublisher` provides `VideoFrame` objects that can be converted to `UIImage`
- **Permissions:** `wearables.checkPermissionStatus()` and `requestPermission()` for camera access
- **State Management:** Published properties with SwiftUI `@Published` for reactive UI updates

### Target Webpage Audio Element (Expected)

```html
<!-- Typical museum audio page structure -->
<audio id="exhibit-audio" controls>
  <source src="audio-guide.mp3" type="audio/mpeg">
</audio>
<button onclick="document.getElementById('exhibit-audio').play()">
  Play Audio
</button>
```

JavaScript injection to auto-play:
```javascript
document.querySelector('audio')?.play();
// or click the play button
document.querySelector('button[onclick*="play"]')?.click();
```
