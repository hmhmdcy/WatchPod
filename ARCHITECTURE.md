# WatchPod Architecture Reference

> For AI consumption.

## Device Specs

### Huawei Watch 3 (primary target)

| Parameter | Value |
|-----------|-------|
| Screen | 1.43" AMOLED round |
| Resolution | 466 × 466 px |
| DPI | 320 |
| Usable dp | ~370 dp (466 / (320/160) ≈ 233pt × 2 = 370dp) |
| Architecture | ARMv7 (32-bit) |

### WearScale Design Baseline

- **Design base:** 280 dp (not the standard 360 dp)
- **Rationale:** Huawei Watch 3's actual usable dp is ~370 dp. With base=280, ratio = 370/280 ≈ 1.32×, ensuring all UI elements (buttons 36dp → 47dp, icons 18sp → 24sp) are large enough for finger touch on a round screen.
- **This is Option 2 (lower base value)** from the Hermes skill: change one constant, all `ws.s()`, `ws.sp()`, `ws.fs()` scale proportionally.

### Scaling Reference (at 370 dp / 320 DPI)

| Design value | Actual size | Use case |
|-------------|-------------|----------|
| 36 dp | ~47 dp | Top bar buttons (height) |
| 18 sp | ~24 sp | Button icons |
| 13 sp | ~17 sp | Tag chip / body text |
| 15 sp | ~20 sp | List item title |
| 11 sp | ~14.5 sp | Caption / meta text |

## File Structure (18 files, ~3600 LOC)

```
lib/
├── main.dart                  # Entry: init 3 services, run WatchPodApp
├── models/
│   ├── episode.dart
│   └── podcast_subscription.dart
├── screens/
|   ├── home_screen.dart       # Full-width content + right TagTrack arc track (~230 lines)
|   ├── episodes_screen.dart   # Episode list: cache-first + silent RSS refresh
|   ├── player_screen.dart     # Seekable Slider + play/pause + skip15
|   └── settings_screen.dart   # Top-bar layout: compact add+refresh / full-height hot list (~350 lines)
├── services/
│   ├── audio_service.dart
│   ├── rss_service.dart
│   ├── storage_service.dart
│   └── top_podcast_service.dart # iTunes API + 24h cache + TopPodcastItem model
└── widgets/
    ├── episode_preview_sheet.dart
    ├── episode_tile.dart
    ├── glass_components.dart
    ├── hot_podcast_list.dart  # List with showTitle prop
    ├── podcast_tile.dart
    ├── settings_add_bar.dart  # compact + default modes
    ├── settings_info_bar.dart # Unused since v1.4.0 (kept for reference)
    ├── home_tag_track.dart    # CustomPaint arc track + GestureDetector tag selection
    ├── watch_safe_area.dart
    ├── watch_layout.dart
    └── wear_scale.dart
```

## Navigation Graph

```
/ → HomeScreen
  → SettingsScreen (add + browse hot podcasts)  [PopScope swipe-back]
    → _TagPickerPage (fullscreen tag selection)
    → showEpisodePreview (bottom sheet)
  → EpisodesScreen (tap podcast card)  [PopScope via WatchLayout]
    → PlayerScreen (play episode)
```

No deep linking, no named routes. Manual DI.

## State Management

| Screen | Mechanism | Notes |
|--------|-----------|-------|
| HomeScreen | setState | Sub list, tag filter, page index |
| EpisodesScreen | setState | Cache-first on init, silent RSS background refresh |
| PlayerScreen | ListenableBuilder | AudioService (ChangeNotifier) |
| SettingsScreen | setState | TopPodcastService auto-caches, no loading on cache hit |

## Top-Bar Layout Architecture (v1.4.0+)

All screens use the same pattern: **top action bar (48dp) + full-height content (Expanded)**.

```
┌───────────────────────┐
│  [tags/add/refresh]   │  ← Row / SizedBox(48dp). Outside WatchSafeArea.
├───────────────────────┤
│                       │
│  Content (Expanded)   │  ← HomeScreen: WatchSafeArea wrap. Settings: plain.
│                       │
└───────────────────────┘
```

No bottom bars. No info footers.

## Refresh Button Flow

```
Tap refresh → TopPodcastService.invalidateCache() → _loadTopPodcasts()
  → getTopPodcasts(forceRefresh: true) → http to iTunes API
  → cache updated → UI updates with setState
```

## Storage Constraints

| File | Format | Notes |
|------|--------|-------|
| subscriptions.json | JSON | <50KB |
| episodes/*.json | JSON | Full read/write per op. Migrate at >5000. |
| top_podcasts_cache.json | JSON | 24h TTL. Survives app restart. |
