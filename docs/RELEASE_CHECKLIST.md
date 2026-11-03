# Release checklist (TestFlight / App Store)

| Item | Status | Notes |
|---|---|---|
| Xcode build (simulator) | Done | Xcode 16.4, GitHub Actions `macos-15` |
| Unit + UI tests | Done | 95 SkydayKit + 8 UI tests pass in CI |
| Physical device run | **Blocked** | Needs a Mac and the owner's Apple ID |
| Bundle IDs | Placeholder | `com.skyday.app`, `com.skyday.app.widget`; regenerate with `Tools/generate_xcodeproj.py --bundle-prefix` |
| Team / signing | **Blocked** | `DEVELOPMENT_TEAM` empty; needs the owner's team |
| App Group | Placeholder | `group.com.skyday.app`; must match your prefix and be registered |
| App icon 1024 | Done | `Assets.xcassets/AppIcon` (original pixel art) |
| Launch screen | Done | `UILaunchScreen` with `LaunchBackground` colour |
| Version / build | 1.0 (1) | bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in the generator |
| Privacy manifest | Done | `Skyday/PrivacyInfo.xcprivacy` |
| App Privacy label | Ready | "Data Not Collected" |
| Export compliance | Ready | No encryption beyond iOS system APIs → answer "No" to non-exempt encryption (`ITSAppUsesNonExemptEncryption = NO` can be added to Info.plist) |
| Notification permission copy | Done | asked in context when a reminder is set |
| Accessibility pass (VoiceOver, AX5 text, Reduce Motion) | Not run | manual, on simulator or device |
| Screenshots for store | Partial | CI screenshots at iPhone SE / 16 size in `docs/screenshots/ios-simulator/`; App Store needs 6.9" set |
| Metadata (name, subtitle, description, keywords, support URL, privacy policy URL) | Not started | privacy policy can state: no data collected, all data on device |
| TestFlight upload | **Blocked** | needs paid Apple Developer account |
| App Store submission | Not started | |
