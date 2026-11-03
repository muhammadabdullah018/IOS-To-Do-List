# Run Skyday on an iPhone

> **No Mac?** Use `docs/INSTALL_WITHOUT_MAC.md`: GitHub builds an unsigned `.ipa` and Sideloadly on Windows signs it with a free Apple ID.

Skyday is a native SwiftUI app. Installing it on an iPhone needs a Mac with Xcode; Apple does not allow a normal iPhone to install an unsigned app, and Windows cannot sign iOS apps.

## What exists today
| Artifact | Where | Installable on a normal iPhone? |
|---|---|---|
| Xcode project + sources | this repo (`Skyday.xcodeproj`) | Yes, after you sign it in Xcode (steps below) |
| Unsigned simulator build `Skyday.app` (arm64/x86_64 simulator) | GitHub Actions run artifact `ios-results` → `Skyday-simulator.app.zip` | **No.** Simulator only |
| Signed `.ipa` / TestFlight | not produced | Needs your Apple account (see below) |

## Prerequisites
- A Mac with macOS 14.5+ and **Xcode 16 or newer** (CI uses Xcode 16.4).
- An Apple ID. A free Apple ID works for your own phone (app expires after 7 days, then re-run). A paid Apple Developer Program account ($99/yr) is needed for TestFlight, App Groups on device with long-lived signing, and the App Store.
- iPhone on iOS 17 or later and a USB cable (or same Wi-Fi after first pairing).

## Steps (exact)
1. Clone the delivery branch:
   ```bash
   git clone -b skyday-delivery https://github.com/SpideyAB/IOS-To-Do-List.git
   cd IOS-To-Do-List
   ```
2. Regenerate the project with your own bundle prefix so IDs are unique (pick any reverse-DNS you own, for example `com.yourname`). Find your Team ID in Xcode → Settings → Accounts, or leave `--team` off and pick it in step 4:
   ```bash
   python3 Tools/generate_xcodeproj.py --bundle-prefix com.yourname --team YOURTEAMID
   ```
3. `open Skyday.xcodeproj`
4. For both targets **Skyday** and **SkydayWidgetExtension**: *Signing & Capabilities* → tick *Automatically manage signing* → choose your Team. Keep the *App Groups* capability (`group.com.yourname.app`). With a free account, if App Groups fails, remove it from both targets: the app still works, only the widget shows an empty state.
5. Plug in the iPhone, unlock it, tap *Trust*. On iOS 16+ enable *Settings → Privacy & Security → Developer Mode* and restart when asked.
6. In Xcode pick your iPhone as the run destination, press **Run** (⌘R).
7. First launch on a free account: *Settings → General → VPN & Device Management* → trust your developer certificate.

## Simulator (no device)
```bash
xcodebuild -project Skyday.xcodeproj -scheme Skyday \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
```
Or download `Skyday-simulator.app.zip` from a CI run, unzip, boot a simulator and run `xcrun simctl install booted Skyday.app && xcrun simctl launch booted com.skyday.app`.

## TestFlight (paid account)
1. Steps 1–4 with your paid team.
2. Create the app record in App Store Connect with the same bundle ID.
3. Xcode → *Product → Archive* → *Distribute App* → *App Store Connect* → *Upload*.
4. In App Store Connect → TestFlight, add yourself as an internal tester and install via the TestFlight app.
Never commit certificates, `.p12`, provisioning profiles or App Store Connect keys; `.gitignore` blocks the common file types.

## Known limits on device
- Reminders are local notifications. iOS may delay them under Focus or Low Power; the app cannot run continuous background checks.
- Data lives only on the phone (no iCloud sync). Deleting the app deletes the data unless you exported a backup (Settings → Data).
