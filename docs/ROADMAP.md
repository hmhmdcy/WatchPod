# WatchPod Roadmap

> Read before starting new features. Update after completing milestones.
> Actual versioning: v1.3.1 → v1.6.0 → v1.8.0–1.8.6 → v1.9.0–1.9.7. No v1.4/v1.5 releases.

## ✅ v1.0 — MVP
- RSS CRUD / feed parsing / audio playback / offline download / JSON persistence / cache-first

## ✅ v1.1 — UI Polish
- Glassmorphism design system / tag classification / seekable slider / per-episode covers / modular docs

## ✅ v1.2 — Huawei Watch 3 Support
- WatchLayout dual-zone layout / 466x466 screen adaptation / batch episode ops

## ✅ v1.3 — Balanced Layout + WearScale (2026-05-24)
- WearScale adaptive sizing (base 360) / three-zone balanced layout / hot podcast preview / centered pill button
- iTunes top-10 fetching / dialog-based RSS input / subscription+storage info bar

## ✅ v1.3.1 — Navigation & Polish (2026-05-24)
- PopScope swipe-back on all sub-screens / empty state bottom button / frosted glass buttons
- Tag filter bar enlarged / HotPodcastList items enlarged / in-memory shuffle refresh

## ✅ v1.6.0 → v1.8.x — Arc Track + Linux Desktop (2026-05-24)
- Centered action bars across all screens / TagTrack arc track (right edge frosted glass)
- WearScale base 360 → 280 / TagTrack GestureDetector + SafeArea fix
- Linux Desktop 466×466 debug shell / circular screen adaptation
- Label bubbles along arc trajectory / TopActionBar unified component

## ✅ v1.9.x — Architecture Consolidation (2026-05-25~26)
- TagPickerPage: AppBar → TopActionBar / global MaterialApp.builder ClipRRect
- WatchScreen unified skeleton (5 pages → ~180 fewer lines)
- WatchSafeArea dedup (no more ClipRRect) / HotPodcastList title scrolls with list
- Cache-first fix: RSS failure no longer overwrites cached episodes
- docs consolidation: KNOWN_BUGS deleted, CHANGELOG archived, UI_COMPONENTS deduped

## 🔜 v1.10 — Media Controls
- Media notification + lock screen controls
- Bluetooth AVRCP button handling
- Rotating bezel navigation
- Ambient mode (low-power always-on)
- Touch target audit (min 44dp)

## 🔜 v1.11 — Reliability & Scale
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
