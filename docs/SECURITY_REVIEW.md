# Skyday security and privacy review

Date: 2026-11-03. Scope: iOS app (`Skyday/`, `SkydayWidget/`, `Packages/SkydayKit`), web demo (`web-demo/`), repository and CI. Skyday is offline-only: no accounts, no backend, no network calls, no third-party SDKs.

## Threats, controls, status
| # | Threat | Severity | Control implemented | Status | Evidence |
|---|---|---|---|---|---|
| 1 | Task text read from a lost/stolen phone's disk | Medium | iOS sandbox + App Group container; store written with `.completeFileProtectionUntilFirstUserAuthentication` (encrypted until first unlock after boot). Not `.complete`, on purpose: reminders, widget refresh and notification actions must read data while locked | Done (code), not device-verified | `JSONFileStore.save` |
| 2 | Exported backup left readable | Low | Export written to the temp dir with `.completeFileProtection`; user chooses where to share it | Done | `SettingsView.makeExportFile` |
| 3 | Task details on the lock screen | Medium | Notification title = task title, body = list name; **notes are never included**. Category sets `hiddenPreviewsBodyPlaceholder` so iOS "Show Previews: When Unlocked/Never" shows "Skyday reminder" | Done | `ReminderPlanner`, `NotificationService` |
| 4 | Malformed or hostile import file | Medium | iOS: versioned decoding, unreadable files quarantined, newer schema opens read-only (unit tests). Web: `parseData` validates shape, clamps lengths, dates (2000–2100), times, enums; 5 MB cap | Done | `StoreTests`, `web-demo/src/domain.test.ts` |
| 5 | Accidental destructive actions | Medium | Delete task: confirm + undo. Delete list: confirm (iOS moves tasks to Inbox). Erase all: confirm (+ undo on iOS) | Done | UI code; UI tests cover undo |
| 6 | Secrets in source, history or CI | High | No secrets exist. `.gitignore` blocks `.env`, `.p12`, `.p8`, `.cer`, provisioning profiles, `.ipa`, `.xcarchive`, `ExportOptions.plist`, backup JSON. gitleaks runs on every push across full history. CI builds with `CODE_SIGNING_ALLOWED=NO`, no credentials stored | Done | CI job "Secret scan" passed |
| 7 | Vulnerable dependencies | Medium | iOS: zero third-party packages. Web: React 18.3.1 + Vite toolchain, pinned exact versions, `npm audit` = 0 vulnerabilities after upgrading vite 6.4.5 / vitest 5.0.5; audit runs in CI | Done | `npm audit` output in TEST_RESULTS |
| 8 | Tracking / data collection | — | No analytics, ads, IDFA or network. `PrivacyInfo.xcprivacy`: tracking false, no collected data, no required-reason APIs (grep found no UserDefaults, file-timestamp, boot-time or disk-space APIs) | Done | `Skyday/PrivacyInfo.xcprivacy` |
| 9 | Public web demo leaks data | Low | Static HTTPS GitHub Pages site; data only in the visitor's own `localStorage`; CSP `default-src 'self'`, no external scripts, no `connect-src` beyond self; labelled DEMO | Done | live URL, `web-demo/index.html` |
| 10 | Data loss (app deletion, corruption) | Medium | Atomic writes, corrupt-file quarantine, export/import. No sync: deleting the app deletes the data (documented in Settings and RUN_ON_IPHONE) | Done, documented | `StoreTests` |
| 11 | AI attribution / authorship metadata | Info | `.claude/settings.json` disables commit/PR attribution; new commits authored by the owner's configured identity. Older commits keep their original metadata (history not rewritten) | Done | `git log` |

## Remaining risks
- `localStorage` in the web demo is plain text for anyone using that browser profile (by design for a demo).
- File protection, notification privacy and App Group access are implemented but **not verified on a physical device**.
- The prompt `.md` files were removed from the branch tip, but remain readable in older commits of history (no history rewrite by owner's choice). They contain no secrets.
- `PrivacyInfo.xcprivacy` must be re-checked if any SDK or required-reason API is added.
- No Keychain use: there are no credentials to store. If login or sync is ever added, tokens must go in Keychain and the backend needs TLS, auth, authorization and a retention policy.

## Not applicable
Authentication, server-side validation, TLS to an API, payments: the app has no backend or accounts.
