# Install Skyday on your iPhone from Windows (no Mac, free Apple ID)

GitHub's macOS runners build the app. Sideloadly on your Windows PC signs it with your own Apple ID and installs it over USB.

## What you get, and the limits
- The real native Skyday app on your iPhone: tasks, lists, streaks, calendar, reminders, offline storage.
- **It expires after 7 days.** Re-install with Sideloadly before then (step 7); your tasks stay if the bundle ID is unchanged.
- Free Apple IDs: max 3 sideloaded apps at once, 10 new app IDs per 7 days.
- **The widget probably won't work.** Free accounts cannot use App Groups, so remove the extension when signing (step 5). The app falls back to its own storage automatically.
- Reminders work: they are local notifications and need no paid account.

## ⚠️ Security first
- Download Sideloadly **only** from `https://sideloadly.io`, and iTunes **only** from `https://www.apple.com/itunes/` (the Apple website installer, not the Microsoft Store version; Sideloadly needs the website version).
- Sideloadly asks for your Apple ID and password to create a free signing certificate. Turn on two-factor authentication first. The safest option is a **separate Apple ID made just for sideloading**.
- Never put your Apple ID, password or certificates into this repository, GitHub Secrets or a chat.

## Step 1: Get the `.ipa` file
1. Open https://github.com/SpideyAB/IOS-To-Do-List/actions/workflows/ios-device-ipa.yml (signed in as SpideyAB).
2. Open the newest run with a green check. If none exists, click **Run workflow**, choose branch `skyday-delivery`, click **Run workflow** again and wait about 10–20 minutes.
3. At the bottom of the run, under **Artifacts**, download **Skyday-unsigned-ipa**.
4. GitHub gives you a `.zip`. Extract it; inside is `Skyday-unsigned.ipa`.

## Step 2: Install the Windows tools
1. Install **iTunes** from https://www.apple.com/itunes/ (Windows 64-bit). If the Microsoft Store version is installed, uninstall it first.
2. Install **Sideloadly** from https://sideloadly.io (Windows, 64-bit).
3. Restart the PC.

## Step 3: Connect the iPhone
1. Plug the iPhone into the PC with a USB cable and unlock it.
2. Tap **Trust** on the phone and enter your passcode.
3. Open iTunes once and check that it shows the phone. Then you can close iTunes.

## Step 4: Open Sideloadly
1. Open Sideloadly. Your iPhone should appear in the **iDevice** field.
2. Drag `Skyday-unsigned.ipa` onto the large IPA icon.
3. Type your Apple ID email in the **Apple account** field.

## Step 5: Advanced options (recommended)
Click **Advanced options**:
- **Remove app extensions**: ON. This removes the widget, which needs a paid account.
- Leave the bundle ID as Sideloadly suggests. Sideloadly may change it to keep it unique to your account; keep the same one for future re-installs so your data survives.

## Step 6: Install
1. Click **Start** and enter your Apple ID password when asked, plus the 2FA code sent to your devices.
2. Wait for **Done** in the log at the bottom.
3. On the iPhone: **Settings → General → VPN & Device Management**, tap your Apple ID under *Developer App*, then **Trust**.
4. On iOS 16 or later: **Settings → Privacy & Security → Developer Mode** → ON, restart, then confirm **Turn On**. (The switch appears after the first sideload attempt.)
5. Open **Skyday** from the Home Screen. Allow notifications when you first set a reminder.

## Step 7: Every 7 days
Before day 7, connect the phone and repeat steps 4 and 6 with the same `.ipa` (or a newer one from step 1) and the same Apple ID. Sideloadly can also refresh automatically over Wi-Fi if you enable its auto-refresh option and leave the PC on.

**Export a backup first** (Skyday → Progress → gear → Your data → Export backup) in case the app expires or a re-install changes the bundle ID.

## Troubleshooting
| Problem | Fix |
|---|---|
| Sideloadly doesn't see the iPhone | Use the apple.com iTunes, a data-capable cable, unlock the phone, tap Trust again |
| "Unable to verify app" / app won't open | Step 6.3 (trust the developer profile) and check you have an internet connection |
| "Maximum number of apps" | Free IDs allow 3 sideloaded apps; delete one |
| Error about App Groups or entitlements | Turn on **Remove app extensions** (step 5) |
| Login fails | Make sure 2FA is on and use the code sent to your devices; try a separate Apple ID |
| App vanished or crashes on launch after a week | Certificate expired: re-install (step 7) |

## Paid alternative
With an Apple Developer account ($99/year) the build can be signed in GitHub Actions and delivered through TestFlight: no 7-day expiry, widget works, no USB. See `docs/RUN_ON_IPHONE.md` (TestFlight section).
