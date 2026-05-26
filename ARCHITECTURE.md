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

## File Structure (22 files, ~4300 LOC)

```
lib/
├── main.dart                  # Entry: init 3 services, run WatchPodApp
│                              # Debug: _DebugPages with IndexedStack (Home/Episodes/Player/Settings/TagPicker)
├── models/
│   ├── episode.dart
│   └── podcast_subscription.dart
├── screens/
│   ├── home_screen.dart       # Stack layout: Positioned.fill content + right arc (~360 lines)
│   ├── episodes_screen.dart   # Episode list: cache-first + silent RSS refresh
│   ├── player_screen.dart     # Seekable Slider + play/pause + skip15 arc controls
│   ├── settings_screen.dart   # TopActionBar (← 🔄 +) + SafeArea + hot list (~324 lines)
│   └── tag_picker_page.dart   # Fullscreen tag selection. TopActionBar(compact: true) pure icon ✕. 2-col tag grid, frosted glass confirm btn (~265 lines)
├── services/
│   ├── audio_service.dart
│   ├── rss_service.dart
│   ├── storage_service.dart
│   └── top_podcast_service.dart # iTunes API + 24h cache + TopPodcastItem model
└── widgets/
    ├── episode_preview_sheet.dart
    ├── episode_tile.dart      # Row layout: cover + text + play btn. ws.s(20) margin for round-screen safety (v1.9.2)
    ├── glass_components.dart
    ├── hot_podcast_list.dart  # List with showTitle prop
    ├── podcast_tile.dart
    ├── home_tag_track.dart    # CustomPaint arc + OverflowBox full-screen + GestureDetector
    ├── watch_safe_area.dart
    └── wear_scale.dart        # Base=280. ws.s/sp/fs/capped methods.
```

## Navigation Graph

```
/ → HomeScreen
  → SettingsScreen (add + browse hot podcasts)  [TopActionBar ← 🔄 +]
    → TagPickerPage (fullscreen tag selection)  [TopActionBar(compact: true) ✕ close]
    → showEpisodePreview (bottom sheet)
  → EpisodesScreen (tap podcast card)  [TopActionBar ← / ✕]
    → PlayerScreen (play episode)  [TopActionBar ←]
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

### TagTrack — Frosted-Glass Arc Track (v1.8.4+)

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
- **标签气泡 (v1.8.4):** 浮层也放在 `OverflowBox` + `Stack` 中使用全屏坐标系。气泡用 `Positioned(top: _dragY - 12, right: screenSize.width - _dragArcX + 29)` 定位，其中 `_dragArcX = cx + R*cos(θ)` 在 `_updateFromY()` 中同步计算。气泡右边缘距弧线左侧 24px 间隙，沿弧线运动（X 和 Y 同步变化）。轻量化样式：字号 10sp, alpha 0.5, w500。

### Global Circular Clip — MaterialApp.builder (v1.9.4+)

The circular screen clipping is handled globally by `_circularScreenBuilder` in `MaterialApp.builder`:

```dart
// In WatchPodApp.build:
// Comment: "全局 builder：统一所有路由的圆形裁剪 + 固定尺寸"
builder: _circularScreenBuilder,
// ...
Widget _circularScreenBuilder(BuildContext context, Widget? child) {
  if (kIsWeb || Platform.isLinux) {
    const watchSize = 466.0;
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(watchSize / 2),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: const Size(watchSize, watchSize),  // ← override!
          ),
          child: SizedBox(
            width: watchSize, height: watchSize,
            child: child,
          ),
        ),
      ),
    );
  }
  return child!;
}
```

This applies to **all routes** (including Navigator.push pages), not just the debug shell. On Android production builds, `kIsWeb || Platform.isLinux` is false, so no clip is applied (watch bezel handles it). On Web/Linux debug, 466×466 circular mask + MediaQuery override ensures TagTrack arc coordinates are correct.

### All Other Screens — TopActionBar (v1.8.5+)

EpisodesScreen, PlayerScreen, SettingsScreen all use TopActionBar instead of AppBar.

```dart
// Pattern:
Scaffold(
  body: GlassBackground(
    child: Stack(
      children: [
        // Content (SafeArea for some screens)
        Column/SafeArea(children: [...]),
        // TopActionBar — float above content
        TopActionBar(actions: [TopAction(child: ...), ...]),
      ],
    ),
  ),
);
```

### TagPickerPage — TopActionBar(compact: true) ✕ (v1.9.0 → v1.9.1)

**File:** `lib/screens/tag_picker_page.dart`
**v1.9.0 从 AppBar 迁移到 TopActionBar。最终形态为 compact: true（纯图标 ✕）。**

```dart
// Pattern: Stack + TopActionBar(compact: true) — 纯图标圆形按钮
Scaffold(
  backgroundColor: const Color(0xFF0F0F23),
  body: GlassBackground(
    child: Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: EdgeInsets.only(top: ws.s(48)),
            child: Column(children: [...]),
          ),
        ),
        TopActionBar(  // compact: true (default) = 40×40 circle
          actions: [
            TopAction(
              child: Icon(Icons.close, size: ws.s(18), color: Colors.white),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ],
    ),
  ),
);
```

布局详见 UI_COMPONENTS.md TagPickerPage 节。

### Per-Screen Button Spec

| Screen | Layout | Normal mode buttons | Multi-select |
|--------|--------|-------------------|-------------|
| HomeScreen | Stack + arc track | Arc track (-45°~45°, 10dp glass) + floating label bubbles | N/A |
| SettingsScreen | Stack + TopActionBar | [←] [🔄] [+] — 3 glass circle buttons via TopActionBar | N/A |
| EpisodesScreen | Stack + TopActionBar | [←] — single back button via TopActionBar | [✕ close] |
| PlayerScreen | Stack + TopActionBar | [←] — single back button via TopActionBar | N/A |
| TagPickerPage | Stack + TopActionBar(compact: true) | ✕ — pure icon circle button | N/A |

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
