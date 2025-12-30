# QRScanPlay - Museum Tour Guide

A hands-free iOS app for museum audio tours using Meta AI glasses. Scan QR codes with your glasses camera and listen to audio guides through the glasses speakers.

## Prerequisites

- **Xcode 15.0+** (iOS 17.0 SDK)
- **iOS 17.0+** device (simulator won't work for glasses features)
- **Meta AI Glasses** (Ray-Ban Meta or compatible)
- **Meta AI App** installed on your iPhone with Developer Mode enabled
- **Apple Developer Account** (for device deployment)

## Project Setup

### 1. Open in Xcode

```bash
# From terminal
cd /Users/shanchu/Documents/Develop/QRScanPlay
open QRScanPlay.xcodeproj
```

Or from VS Code:
- Press `Cmd + Shift + P`
- Type "Tasks: Run Task"
- Select or create a task to open Xcode

### 2. Configure Signing

1. In Xcode, select the **QRScanPlay** project in the navigator
2. Select the **QRScanPlay** target
3. Go to **Signing & Capabilities** tab
4. Select your **Team** from the dropdown
5. Xcode will automatically create a provisioning profile

### 3. Verify Swift Package Dependencies

The Meta DAT SDK should already be configured. To verify:

1. In Xcode, go to **File → Packages → Resolve Package Versions**
2. Check that `meta-wearables-dat-ios-private` appears in the package list
3. If missing, add it via **File → Add Package Dependencies...**
   - URL: `https://github.com/facebookincubator/meta-wearables-dat-ios-private`
   - Version: `0.2.0`

## Running the App

### Option A: With Physical Meta AI Glasses (Recommended)

1. **Prepare your glasses:**
   - Ensure glasses are paired with your iPhone via Meta AI app
   - Enable Developer Mode in Meta AI app settings
   - Glasses should be charged and connected

2. **Build and run:**
   - Connect your iPhone to your Mac
   - Select your iPhone as the run destination in Xcode
   - Press `Cmd + R` or click the ▶️ Run button

3. **First launch:**
   - Tap "Connect my glasses" on the home screen
   - You'll be redirected to Meta AI app for authorization
   - Return to QRScanPlay after granting permissions

4. **Start a tour:**
   - Tap "Start Tour" to begin
   - Tap "Scan QR" and look at a QR code with your glasses
   - Audio will play through glasses speakers

### Option B: With Mock Device (Development/Testing)

The app includes mock device support for testing without physical glasses:

1. **Build in Debug mode:**
   ```bash
   # Xcode builds in Debug by default
   # Or from command line:
   xcodebuild -scheme QRScanPlay -configuration Debug -destination 'platform=iOS,name=Your iPhone'
   ```

2. **Access Mock Device:**
   - Look for the 🐞 (ladybug) button on the right edge of the screen
   - Tap it to open the Mock Device panel
   - Add a mock device to simulate glasses connection

3. **Test the flow:**
   - With mock device active, the app will show the Tour view
   - Camera frames will be simulated for testing

## Testing QR Codes

### Create Test QR Codes

Generate QR codes pointing to audio content:

1. **Online generator:** https://www.qr-code-generator.com/
2. **Content examples:**
   ```
   https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3
   https://example.com/audio-guide.html
   ```

3. **Expected webpage structure:**
   ```html
   <audio id="exhibit-audio" controls autoplay>
     <source src="your-audio.mp3" type="audio/mpeg">
   </audio>
   ```

### Test Scenarios

| Scenario | Expected Behavior |
|----------|-------------------|
| Valid URL QR code | Loads in WebView, audio auto-plays |
| Invalid QR code | Shows error, returns to listening |
| No QR detected | Continues scanning animation |
| Stop during scan | Returns to idle state |

## VS Code Development

### Editing Code

1. Open the workspace in VS Code
2. Edit Swift files directly
3. Save changes (`Cmd + S`)

### Building from VS Code

Create a task in `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build QRScanPlay",
      "type": "shell",
      "command": "xcodebuild",
      "args": [
        "-project", "QRScanPlay.xcodeproj",
        "-scheme", "QRScanPlay",
        "-configuration", "Debug",
        "-destination", "generic/platform=iOS",
        "build"
      ],
      "group": "build",
      "problemMatcher": []
    },
    {
      "label": "Open in Xcode",
      "type": "shell",
      "command": "open",
      "args": ["QRScanPlay.xcodeproj"]
    }
  ]
}
```

Run tasks with `Cmd + Shift + P` → "Tasks: Run Task"

### Running Tests

```bash
# Run unit tests
xcodebuild test \
  -project QRScanPlay.xcodeproj \
  -scheme QRScanPlay \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Project Structure

```
QRScanPlay/
├── QRScanPlayApp.swift              # App entry point, SDK init
├── ViewModels/
│   ├── WearablesViewModel.swift     # Glasses connection
│   ├── TourSessionManager.swift     # Tour state & QR scanning
│   └── DebugMenuViewModel.swift     # Mock device (DEBUG)
├── Views/
│   ├── MainAppView.swift            # Navigation hub
│   ├── HomeScreenView.swift         # Onboarding UI
│   ├── TourView.swift               # Main tour interface
│   ├── AudioWebView.swift           # WebView + auto-play
│   ├── RegistrationView.swift       # OAuth callbacks
│   └── DebugMenuView.swift          # Debug overlay
└── Assets.xcassets/                 # App icons & colors
```

## Troubleshooting

### "Glasses not found"
- Ensure glasses are connected in Meta AI app
- Check Bluetooth is enabled
- Try re-pairing in Meta AI app

### "Camera permission denied"
- Go to Settings → QRScanPlay → Camera → Allow
- Or re-authorize via Meta AI app

### Audio not playing through glasses
- Check glasses are connected via Bluetooth
- Verify audio is not muted on glasses (tap temple)
- Check iPhone is not connected to other audio devices

### Build errors
```bash
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/QRScanPlay-*

# Reset package cache
cd /Users/shanchu/Documents/Develop/QRScanPlay
rm -rf .build
rm -rf QRScanPlay.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

# Re-open and resolve packages
open QRScanPlay.xcodeproj
```

## Debug Logging

View logs in Xcode console or via Console.app:

```bash
# Filter for app logs
log stream --predicate 'subsystem == "com.yourteam.QRScanPlay"' --level debug
```

Key log prefixes:
- `[TourSession]` - Tour state changes
- `[AudioWebView]` - WebView loading and JS injection
- `[QRScanPlay]` - General app events

## Next Steps

- [ ] Add voice command support ("Scan this QR code")
- [ ] Implement tour history
- [ ] Add offline audio caching
- [ ] Support multiple languages
