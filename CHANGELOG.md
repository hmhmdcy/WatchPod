# WatchPod Changelog

## v1.8.3 — 2026-05-25

### Added
- **Linux Desktop 调试环境** — 窗口尺寸改为 466×466（`linux/runner/my_application.cc`），去掉标题栏（`gtk_window_set_decorated(FALSE)`）
- **Linux Desktop 圆形裁剪** — `_WebDebugShell` 改为 StatelessWidget，固定 `watchSize=466`，`ClipRRect` 圆形裁剪 + `MediaQuery` 覆盖
- **`_LinuxDebugPages`** — 新增 `_LinuxDebugPages` StatefulWidget，四页导航（Home/Episodes/Player/Settings）供 Linux Desktop 调试用

### Changed
- **TagTrack GestureDetector** — 加上 `behavior: HitTestBehavior.translucent`，扩大触摸区域命中范围
- **`_WebDebugShell`** — 从 `StatefulWidget` 重构为 `StatelessWidget`，由新 `_LinuxDebugPages` 管理状态

## v1.8.2 — 2026-05-25

### Fixed
- **TagTrack arc slider completely non-interactive** — Root cause: `TagTrack.build()` had no `GestureDetector` at all. The arc was drawn but no touch/gesture handlers were registered, so vertical drag, tap, and long-press all had zero effect. Fixed by adding a `GestureDetector` layer (`onVerticalDragStart`/`onVerticalDragUpdate`/`onVerticalDragEnd`/`onTapUp`) between the arc CustomPaint and the label overlay, using `SizedBox.expand()` as the gesture target.

- **HomeScreen: TagTrack touch area clipped by SafeArea on round screens** — Root cause: TagTrack was placed inside `SafeArea`, which on a round screen (Huawei Watch 3) adds padding to all four edges. This shifted the 40dp touch zone away from the screen right edge, making the arc unreachable. Fixed by restructuring `HomeScreen.build()` layout from `SafeArea → Stack [content, TagTrack]` to `Stack [SafeArea → content, TagTrack (outside SafeArea)]`, ensuring TagTrack's gesture region reaches the screen edge.

- **Cover tap unresponsive on round screens** — TagTrack's `Positioned.fill` was in the same `SafeArea`-wrapped `Stack` as the content, causing layout inconsistencies. The SafeArea separation fix also resolved this: content inside `WatchSafeArea` is no longer overlapped by SafeArea padding on the circular display.

### Changed
- **HomeScreen layout: SafeArea scope restricted** — `SafeArea` now only wraps the content area (`_buildPodcastSection`), not the TagTrack. The outer layer becomes `GlassBackground → Stack [SafeArea → content, TagTrack]`.

### Cleanup
- Removed unused `_ArcShape` clipper (legacy from right-panel era)
- Removed unused `_allTagItems` getter
- Removed unused `_openPlayer` method
- Removed unused `_selectTag` method (had logic bug, was never called)
- Removed unused `_screenSize` field from `_TagTrackState`

## v1.8.1 — 2026-05-25

### Added
- `ArcLinePainter` (`lib/widgets/arc_line_painter.dart`) — CustomPaint arc drawn with circle equation on full screen, hugging right circular edge exactly from top-right (-90°) to bottom-right (90°). Uses global screen coordinates via `Positioned.fill(left: -N)` extension.
- `OverflowBox` full-screen arc painting — `CustomPaint` now uses `OverflowBox` to paint outside TagTrack's 40dp container, ensuring canvas origin (0,0) = screen (0,0) for consistent rendering across Web, emulator, and real device.
- Frosted glass arc effect — `MaskFilter.blur` blur layer under the semi-transparent white stroke for a frosted glass appearance.
- Web debug: `MediaQuery` override in `_WebDebugShell` — wraps child screens with `MediaQuery(data: copyWith(size: Size(watchSize, watchSize)))` so child widgets read the correct circular mask size instead of full browser dimensions.

### Changed
- **HomeScreen layout: Row → Stack for centered content** — Content (WatchSafeArea) now uses `Positioned.fill` in a Stack instead of `Expanded` in a Row. This ensures the podcast cover is truly centered on round screens, unaffected by the 24dp right-side TagTrack zone.
- **TagTrack arc coordinates: global → OverflowBox** — Arc is drawn using the raw circle equation `(centerX + R*cos(θ), centerY + R*sin(θ))` on a full-screen Canvas. No more offset-based coordinate translation. This eliminates the earlier bug where `MediaQuery` returned browser size (1280px) on Web, causing arc to render at wrong coordinates.
- **Arc length: full right semicircle → half length (-45° to 45°)** — Reduced from -90°~90° (full right semicircle) to -45°~45° per user feedback.
- **Arc inset: 2dp → 0dp** — Arc now sits directly on the circular edge with no inset, matching user's "紧贴圆边" requirement.
- **Arc stroke: 10dp, semi-transparent white + blur** — Frosted glass look with `MaskFilter.blur(BlurStyle.normal, 10)`.

### Fixed
- **Arc invisible on Web** — Root cause: `MediaQuery.of(context).size` returned full browser width (1280px) when Flutter was rendered inside a 577px circular ClipRRect mask. The circle equation computed arc points far from the visible mask area. Fixed by overriding `MediaQuery` in `_WebDebugShell` and using `OverflowBox` for the CustomPaint canvas.
- **Cover off-center** — Root cause: `Row(children: [Expanded(...), SizedBox(width:24, TagTrack)])` offset the geometric center by 12dp. Fixed by using `Stack(children: [Positioned.fill(WatchSafeArea), Positioned(right:0, TagTrack)])`.

## v1.8.0 — 2026-05-24

### Changed
- **HomeScreen: right-side panel → arc track** — Replaced the entire right-side arched panel (`ClipPath` + button list) with `TagTrack`, a tight arc track (3dp) glued to the right circular screen edge. Finger touch reveals a slider dot + tag label bubble; drag vertically to switch tags; hover at bottom for 2s triggers "add subscription".
- **HomeScreen layout: row split → full width + arc track** — Content area now occupies full `Expanded` width, with only a 24dp touch zone on the right for the arc track. No more 1/4 right panel.
- **Web debug shell: removed bottom nav bar** — kIsWeb `_WebDebugShell` no longer shows the "首页/节目/播放/设置" bottom bar, making Web screenshots closer to actual watch display.

### Removed
- `_ArcShape` clipper (no longer needed after right panel removal)
- `_allTagItems` / `_selectTag` / `_openPlayer` methods (old button-based tag filter removed)
- Right panel container with ClipPath, GlassBackground, button list

### Added
- `TagTrack` widget (`lib/widgets/home_tag_track.dart`) — CustomPaint arc track, GestureDetector vertical drag, label bubble overlay, 2s bottom hover to add subscription.

### Documentation
- AGENTS.md: Added TagTrack cross-ref, updated HomeScreen description, added Web debug shell note
- ARCHITECTURE.md: Added `home_tag_track.dart` to file structure, updated home_screen description
- UI_COMPONENTS.md: Replaced HomeScreen layout diagram with arc track version, added TagTrack section
- .gitignore: Added screenshot_*.png pattern to prevent local test screenshots from being committed

### Changed
- **WearScale base: 360 → 280** — Huawei Watch 3 has ~370 dp usable (466×466 px @ 320 DPI). With base=280, ratio ≈ 1.32×, ensuring buttons (36→47dp), icons (18→24sp) and all elements are large enough for finger touch. This is a one-line change that globally scales all `ws.s()`, `ws.sp()`, `ws.fs()` calls. See ARCHITECTURE.md for device specs.
- All top bar buttons: 28dp → 36dp height, icons 14sp → 18sp, spacing increased
- Top bar container height: 40dp → 48dp
- Tag chips: 28dp → 36dp height, text 11sp → 13sp
- HotPodcastList: cover 36→42dp, title 14→15sp, subscribe btn 40→44dp, item padding increased
- EpisodeTile: cover 32→36dp, title 12→13sp, duration 10→11sp, play btn 18→20sp, padding increased
- PlayerScreen: back button padding 6→8, icon 16→18sp; -15/+15 buttons enlarged; slider track 3→4dp, thumb radius 7→8dp
- EpisodesScreen: back/close button padding 6→8, icon 16→18sp

### Removed
- Prebuilt RSS feed URLs from pre_build_check.sh — WatchPod gets podcast data solely from Apple iTunes API, no hardcoded RSS presets needed.

## v1.6.0 — 2026-05-24

### Added
- HomeScreen: "正在播放" button at the start of the tag bar — purple outlined pill with play icon, only shown when audio is active. Tap returns to PlayerScreen.
- EpisodesScreen: centered back arrow (←) replaces refresh/close buttons in single mode. Multi-select shows centered close (✕) button.
- SettingsScreen top bar: replaced text-based SettingsAddBar with three centered icon buttons → ← back / 🔄 refresh / ➕ add (icon only, no text)
- SettingsScreen: WatchSafeArea now wraps the hot podcast list for round screen protection
- All AppBars: `automaticallyImplyLeading: false` — prevents Flutter Material from auto-inserting back arrows at top-left
- PlayerScreen: back button changed from IconButton to GestureDetector+Container for proper centering

### Changed
- EpisodesScreen: restored from WatchLayout to direct Scaffold (fixes blank page on round screens)
- EpisodesScreen: AppBar title removed (only action buttons remain)

### Fixed
- **Leftover back arrows on round screens**: `AppBar.leading` was suppressed but Flutter's `automaticallyImplyLeading: true` still injected default back buttons. Fixed by adding explicit `automaticallyImplyLeading: false` on all AppBars.
- PlayerScreen back arrow position: IconButton as title didn't center properly; replaced with GestureDetector+Container matching EpisodesScreen pattern.

## v1.5.0 — 2026-05-24

### Added
- EpisodesScreen: restored original Scaffold layout (removed WatchLayout dependency that caused blank screen)
- RssService: set explicit Dio timeouts (connect 10s, receive 15s)
- Centered action bars across all screens (HomeScreen, PlayerScreen, TagPickerPage, EpisodesScreen)

### Fixed
- **Critical: EpisodesScreen blank on first open** — Two-layer issue:
  - Layer 1: Dio BaseOptions syntax was corrupted by cumulative patch() operations, causing RSS requests to hang indefinitely
  - Layer 2: Cache-empty state never exited `_loading=true`, making CircularProgressIndicator invisible on dark background
  - Why Apple Hot Podcast worked: subscribe flow calls `saveEpisodes()` immediately, so cache exists on subsequent opens
- HomeScreen: top-bar changed from left-aligned (tags) + right-aligned (add btn) to centered layout

### Moved
- AppBar buttons from `leading`/`actions` to `centerTitle: true` across all screens

## v1.4.0 — 2026-05-24

### Changed
- HomeScreen: three-zone layout → top-bar layout (tag row + add btn in one 44dp line, content fills rest)
- SettingsScreen: three-zone layout → top-bar layout (compact 40px action bar + full-height list)
- SettingsAddBar: added compact mode (30dp buttons for top-bar layout)
- HotPodcastList: added `showTitle` prop (optional title for SettingsScreen)
- All screens: bottom info/action bars removed to maximize content space

### Architecture
- SettingsScreen reduced from 449 to ~350 lines (removed SettingsInfoBar dependency, dedup)
- Added `compact` mode to SettingsAddBar for dual-use (standalone + top-bar)
- TopPodcastService: 24h memory + file cache (hot podcasts survive app restart)
- EpisodesScreen: cache-first load (no loading spinner on subsequent opens)

### Removed
- SettingsInfoBar widget (subscription count + storage info) — removed from SettingsScreen
- HomeScreen: bottom "添加订阅" pill button (moved to top-bar as mini button)
- SettingsScreen: bottom info bar (subscription count, storage size)

## v1.3.1 — 2026-05-24

### Added
- Empty state: bottom "添加订阅" button
- Tag filter bar: enlarged to 48dp h, 34dp tags, 13sp text, BouncingScrollPhysics
- SettingsScreen: PopScope swipe-back navigation
- EpisodesScreen: PopScope swipe-back via WatchLayout
- SettingsScreen: refresh button shuffles in-memory list
- Loading text in EpisodesScreen

### Changed
- All action buttons: solid purple → frosted glass (white @ 0.1 + white border)
- Hot podcast list: cover 28dp→36dp, title 11sp→14sp, subscribe btn 32dp→40dp
- SnackBar on subscribe: removed (replaced with pop-and-reload)

### Removed
- AppBar from SettingsScreen and EpisodesScreen
- HomeScreen empty state was missing bottom button (fixed)

## v1.3.0 — 2026-05-24

### Added
- WearScale adaptive sizing tool (base 360dp)
- Three-zone layout (tag bar / iPod card / pill button)
- Hot podcast preview (DraggableScrollableSheet)
- Dialog-based RSS input

### Fixed
- HomeScreen top/bottom bars clipped by WatchSafeArea

## v1.2.0 — 2026-05-24

### Added
- WatchLayout dual-zone layout
- Huawei Watch 3 screen adaptation
