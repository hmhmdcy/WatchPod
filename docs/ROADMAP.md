# WatchPod Roadmap

> Read before starting new features. Update after completing milestones.

## ✅ v1.0 MVP
- RSS CRUD · Feed parsing · Audio playback · Offline download · JSON persistence · Cache-first

## ✅ v1.1 — UI Polish
- Glassmorphism design system · Tag classification · Seekable slider · Per-episode covers · Modular docs

## 🔜 v1.2 — Wear OS Polish
- Media notification + lock screen controls
- Bluetooth AVRCP button handling
- Rotating bezel navigation
- Ambient mode (low-power always-on)
- Touch target audit (min 44dp)
- i18n (zh + en)

## 🔜 v1.3 — Reliability & Scale
- Storage migration: JSON → Hive/Isar (trigger: >5000 episodes or >10MB)
- Download queue with progress
- Periodic playback position save (15s interval)
- Atomic file writes (write temp → rename)
- Background RSS refresh (WorkManager)
- Unit tests (models + services)
- App-level error boundary

## 🔜 v2.0 — Features
- Podcast search (iTunes API / Podindex)
- Playback speed (0.5x–3x)
- Sleep timer
- Watch face complication
- Deep linking (podcast://)
- Riverpod state management
- go_router navigation
- Post-hoc tag editing
