# WatchPod Roadmap

> Read before starting new features. Update after completing milestones.

## ✅ v1.0 MVP
- RSS CRUD / feed parsing / audio playback / offline download / JSON persistence / cache-first

## ✅ v1.1 — UI Polish
- Glassmorphism design system / tag classification / seekable slider / per-episode covers / modular docs

## ✅ v1.2 — Huawei Watch 3 Support
- WatchLayout dual-zone layout / 466x466 screen adaptation / batch episode ops

## ✅ v1.3 — Balanced Layout + WearScale (2026-05-24)
- WearScale adaptive sizing / three-zone balanced layout / hot podcast preview / centered pill button
- iTunes top-10 fetching / dialog-based RSS input / subscription+storage info bar

## ✅ v1.3.1 — Navigation & Polish (2026-05-24)
- PopScope swipe-back on all sub-screens (SettingsScreen, EpisodesScreen, via WatchLayout)
- Empty state bottom button — no longer text-only
- Frosted glass buttons (white tint + border) on both HomeScreen and SettingsScreen
- Tag filter bar enlarged (48dp h, 34dp tags, 13sp, BouncingScrollPhysics)
- Hot podcast list items enlarged (cover 36dp, title 14sp, subscribe btn 40dp)
- Refresh button: in-memory shuffle (no API re-fetch)

## 🔜 v1.4 — Media Controls
- Media notification + lock screen controls
- Bluetooth AVRCP button handling
- Rotating bezel navigation
- Ambient mode (low-power always-on)
- Touch target audit (min 44dp)

## 🔜 v1.5 — Reliability & Scale
- Storage migration: JSON → Hive/Isar (trigger: >5000 episodes or >10MB)
- Download queue with progress
- Periodic playback position save (15s interval)
- Atomic file writes (write temp → rename)
- Background RSS refresh (WorkManager)
- Unit tests (models + services)

## 🔜 v2.0 — Features
- Podcast search (iTunes API / Podindex)
- Playback speed (0.5x–3x)
- Sleep timer
- Watch face complication
- Deep linking (podcast://)
- Riverpod state management
- go_router navigation
- Post-hoc tag editing
