# WatchPod Architecture Reference

> For AI consumption.

## Device Specs

### Huawei Watch 3 (primary target)

| Parameter | Value |
|-----------|-------|
| Screen | 1.43" AMOLED round |
| Resolution | 466 × 466 px |
| DPI (ADB) | 320 → density bucket xhdpi (2.0×) |
| Logical dp (Flutter) | 466 / 2.0 = **233 dp** |
| Architecture | ARMv7 (32-bit) — use armeabi-v7a APK |

> ⚠️ **CORRECTION**: The old claim "~370 dp usable" was based on a flawed calculation.
> Correct value from ADB: logical screen = 233×233 dp.

### WearScale Design Baseline

- **Design base:** 280 dp (not the standard 360 dp)
- **Rationale:** Huawei Watch 3 logical dp = 233 dp. ratio = 233/280 ≈ 0.83. All elements render at 83% of design spec. This was chosen over base=180 (which made buttons too large) after user testing.
- **One-line change:** `WearScale.base = 280` in `lib/widgets/wear_scale.dart` — all `ws.s()`, `ws.sp()`, `ws.fs()` scale proportionally.

### Scaling Reference (at 233 dp / 320 DPI)

| Design value | Actual size ratio | Use case |
|-------------|------------------|----------|
| 36 dp | ~30 dp (83%) | Top bar buttons (height) |
| 18 sp | ~15 sp (83%) | Button icons |
| 13 sp | ~10.8 sp | Tag chip / body text |
| 15 sp | ~12.5 sp | List item title |
| 11 sp | ~9.1 sp | Caption / meta text |
| 96 dp (cover) | ~80 dp (capped+clamped) | HomeScreen podcast cover |

## File Structure (19 files, ~3600 LOC)

```
lib/
├── main.dart                  # Entry: init 3 services, run WatchPodApp
│                              # Web: _WebDebugShell with ClipRRect + MediaQuery override
├── models/
│   ├── episode.dart
│   └── podcast_subscription.dart
├── screens/
│   ├── home_screen.dart       # Stack layout: Positioned.fill content + right arc (~360 lines)
│   ├── episodes_screen.dart   # Episode list: cache-first + silent RSS refresh
│   ├── player_screen.dart     # Seekable Slider + play/pause + skip15
│   └── settings_screen.dart   # AppBar centered (← 🔄 +) + full-height hot list (~350 lines)
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
    ├── home_tag_track.dart    # CustomPaint arc + OverflowBox full-screen + GestureDetector
    ├── watch_safe_area.dart
    ├── watch_layout.dart
    └── wear_scale.dart        # Base=280. ws.s/sp/fs/capped methods.
```

## Navigation Graph

```
/ → HomeScreen
  → SettingsScreen (add + browse hot podcasts)  [AppBar centered back]
    → TagPickerPage (fullscreen tag selection)
    → showEpisodePreview (bottom sheet)
  → EpisodesScreen (tap podcast card)  [AppBar centered ← back]
    → PlayerScreen (play episode)  [AppBar centered ← back]
```

No deep linking, no named routes. Manual DI.

## State Management

| Screen | Mechanism | Notes |
|--------|-----------|-------|
| HomeScreen | setState | Sub list, tag filter, page index |
| EpisodesScreen | setState | Cache-first on init, silent RSS background refresh |
| PlayerScreen | ListenableBuilder | AudioService (ChangeNotifier) |
| SettingsScreen | setState | TopPodcastService auto-caches, no loading on cache hit |

## Layout Architecture

### HomeScreen — Stack + Right Arc Track (v1.8.2+)

**IMPORTANT (v1.8.2 fix):** TagTrack must be **outside** `SafeArea` on round screens. `SafeArea` on Huawei Watch 3 adds padding that clips the 40dp touch zone away from the screen edge, making the arc unreachable.

```dart
// HomeScreen.build() — v1.8.2 layout
return Scaffold(
  extendBodyBehindAppBar: true,
  body: GlassBackground(
    child: Stack(
      children: [
        // Content: SafeArea protects from bezel clipping
        SafeArea(
          child: _subscriptions.isEmpty
              ? _emptyState(ws)
              : Positioned.fill(
                  child: WatchSafeArea(
                    child: _buildPodcastSection(ws),
                  ),
                ),
        ),
        // TagTrack OUTSIDE SafeArea — gesture region reaches screen edge
        if (_subscriptions.isNotEmpty)
          Positioned.fill(
            child: _buildTopBar(ws),  // → TagTrack
          ),
      ],
    ),
  ),
);
```

### TagTrack — Frosted-Glass Arc Track (v1.8.2+)

- **Container:** `SizedBox(width:40, height:screenHeight)` — limits touch zone to right edge
- **Arc painting:** `OverflowBox(minWidth:screenWidth)` extends `CustomPaint` to full screen
- **Canvas coordinate origin:** (0,0) = screen (0,0) — **no offset translation**
- **Arc formula:** `x = centerX + R*cos(θ)`, `y = centerY + R*sin(θ)`
- **Angle range:** -45° to 45° (upper-right to lower-right, ~1/4 circle)
- **Style:** 10dp stroke, `Color(0xB0FFFFFF)` (semi-transparent white), `StrokeCap.round`
- **Frosted glass:** `MaskFilter.blur(BlurStyle.normal, 10)` on a wider (14dp) low-opacity (0.15) blur layer
- **Tags:** ["全部"(null), ...widget.tags] — drag Y maps to tag via `asin((Y-centerY)/R)`
- **Bottom zone:** 85%+ of arc → 2s hold triggers "添加订阅"
- **Architecture (CRITICAL):** TagTrack's CustomPaint uses `OverflowBox` so the arc is drawn at true screen-global coordinates. This ensures **identical rendering on Web, emulator, and real hardware** — no coordinate translation bugs.
- **Gesture layer (v1.8.2 fix):** A `GestureDetector` with `SizedBox.expand()` is placed between the arc CustomPaint and the label overlay. Handlers: `onVerticalDragStart` → enables drag mode, `onVerticalDragUpdate` → maps Y to tag label, `onVerticalDragEnd` → commits selection, `onTapUp` → single-tap commit. The GestureDetector is at the third child position in the inner Stack (after arc OverFlowBox and before label overlay), ensuring it catches all gestures before they reach the label layer.

### Web Debug — MediaQuery Override

In `_WebDebugShell.build`:
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(watchSize/2),
  child: MediaQuery(
    data: MediaQuery.of(context).copyWith(
      size: Size(watchSize, watchSize),  // ← override!
    ),
    child: SizedBox(
      width: watchSize,
      height: watchSize,
      child: IndexedStack(...),  // HomeScreen + other pages
    ),
  ),
)
```
This ensures `MediaQuery.of(context).size` in TagTrack returns the circular mask size (e.g. 577×577), NOT the full browser window (1280×720).

### All Other Screens — AppBar Centered

```dart
Scaffold(
  extendBodyBehindAppBar: true,
  appBar: AppBar(
    backgroundColor: const Color(0xFF0F0F23).withValues(alpha: 0.85),
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    centerTitle: true,
    automaticallyImplyLeading: false,
    title: buttonsRow,  // ← centered, NOT in leading/actions
  ),
  body: GlassBackground(
    child: Column(
      children: [
        Expanded(child: WatchSafeArea(child: content)),
      ],
    ),
  ),
);
```

### Per-Screen Button Spec

| Screen | Layout | Normal mode buttons | Multi-select |
|--------|--------|-------------------|-------------|
| HomeScreen | Stack + arc track | Arc track (-45°~45°, 10dp glass) + floating label bubbles | N/A |
| SettingsScreen | AppBar centered | [←] [🔄] [+] — 3 glass pill buttons | N/A |
| EpisodesScreen | AppBar centered | [← 返回] — pill-style button | [✕ 退出选择] |
| PlayerScreen | AppBar centered | [← 返回] — pill-style button | N/A |

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
