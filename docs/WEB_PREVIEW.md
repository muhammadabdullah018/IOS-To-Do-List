# Skyday web preview (DEMO)

**Live:** https://spideyab.github.io/IOS-To-Do-List/ (GitHub Pages, HTTPS, deployed by `.github/workflows/web-demo-pages.yml` from branch `skyday-delivery`).

A separate React + Vite port under `web-demo/` so you can try Skyday on any device. It shares no code with the iOS app; the rules in `web-demo/src/domain.ts` are a small TypeScript port of `Packages/SkydayKit`.

## Run locally
```bash
cd web-demo
npm install
npm run dev        # http://localhost:5173
npm test           # 11 domain tests (recurrence, streaks, undo, import validation)
npm run typecheck
npm run build      # static output in web-demo/dist
```

## What works
Three tabs (Today, Lists, Progress); Calendar from Today; Streak & Achievements and Settings from Progress. Create, edit, complete, reopen, undo, delete (with confirmation) tasks; subtasks; due date and time; priority; daily/weekly/monthly repeats (one record per series, month-end safe); custom lists (create, rename, recolour, delete with confirmation); daily goal; streak and weekly chart; export, validated import and erase-all. Data persists in this browser's `localStorage`.

## Differences from the iOS app
| Area | iOS app | Web demo |
|---|---|---|
| Storage | JSON file in the app sandbox (App Group), iOS file protection | browser `localStorage`, readable by anyone using this browser profile |
| Reminders | local notifications with Complete/Snooze | shown on the task, **never delivered** |
| Widgets, haptics, Keychain | WidgetKit widget, haptics | not available |
| Repeat rules | daily, weekdays, weekly, every N, monthly, yearly, custom | daily, weekly, monthly |
| Streak rest day | one forgiven day per week | not implemented (stricter) |
| Backup files | not interchangeable with the iOS backup format | — |

## Privacy
No server, no analytics, no cookies. A Content-Security-Policy blocks external scripts and network calls. Do not enter sensitive personal data into the public demo.
