# Buddy

Photo-first calorie companion for iPhone — a **marshmallow ghost** who helps you **watch what you eat**.

**What’s up, bud?** · Made by Night Folio.

## Stack

- SwiftUI + SwiftData (local-only, no account)
- Photos / Camera → plate watch
- Foundation Models (iOS 26+) specialized for calorie & fitness estimates + Buddy voice
- Offline heuristic fallback when Apple Intelligence is unavailable
- Native (XcodeGen), not Expo

## Brand

See [`brand.md`](./brand.md) · board [`design/buddy-brandkit-board.png`](./design/buddy-brandkit-board.png)

## Generate & run

```bash
cd /Users/markraphaelsto.domingo/Projects/buddy
xcodegen generate
open Buddy.xcodeproj
```

Use an Apple Intelligence–capable device (or Simulator on iOS 26+) to exercise meal analysis.

## MVP

1. **Today** — daily energy ring, plate feed, Buddy mood + XP / streak
2. **Watch a plate** — camera or library → FM meal estimate → confirm → XP
3. **Buddy** — short character reactions (never guilt-coach)
4. **Settings** — daily calorie target, AI readiness

## Privacy

Photos and estimates stay on-device. No account. No cloud model calls.
