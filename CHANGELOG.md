# WatchPod Changelog

## v1.9.6 — 2026-05-26

### Changed
- **HotPodcastList 标题行为重构** (`lib/widgets/hot_podcast_list.dart`):
  - 标题从 Column 固定位置移入 ListView 作为首个列表元素 → **随列表一起滚动**
  - 标题居中：`SizedBox(width: double.infinity)` + `Text(textAlign: TextAlign.center)`
  - 订阅错误提示 (`subscribeError`) 保持在列表上方临时显示，不参与滚动
- **SettingsScreen** (`lib/screens/settings_screen.dart`):
  - 移除 `Stack` + `Positioned` 标题浮层 → 标题由 `HotPodcastList` 内部管理 (`showTitle: true`)
  - 订阅错误通过 `subscribeError` 参数传递给 `HotPodcastList`

## v1.9.5 — 2026-05-26

### Added
- **WatchScreen 统一页面骨架** (`lib/widgets/watch_screen.dart`):
  - 封装 `Scaffold(transparent) + GlassBackground + Stack + TopActionBar + SafeArea` 为复用组件
  - API：`WatchScreen(actions, safeArea, extendBody, child)` — 5 行替代原来 25+ 行样板代码

### Changed
- **SettingsScreen** — `WatchScreen` 替换 40 行重复骨架（`PopScope + GlassBackground + Stack + SafeArea + TopActionBar` → 2 行 `WatchScreen(safeArea: true, actions: [...])`)
- **EpisodesScreen** — `WatchScreen` 替换 40 行重复骨架，行为不变（无 SafeArea)
- **PlayerScreen** — `WatchScreen` 替换 45 行重复骨架，`safeArea: true` 自动包裹
- **TagPickerPage** — `WatchScreen` 替换 25 行重复骨架，✕ 按钮移入 `actions:` 参数

### Architecture
- 所有 5 个页面统一骨架：`WatchScreen → GlassBackground → SafeArea(可选) → Stack → [Content + TopActionBar]`
- 后续新增页面只需关注内容布局，骨架代码自动继承

## v1.9.4 — 2026-05-26

### Changed
- **全局圆形裁剪：MaterialApp.builder 统一所有路由** (`lib/main.dart`):
  - 将 `ClipRRect(圆形)` + `MediaQuery(466×466)` 从 `_WebDebugShell` 提升到 `MaterialApp.builder`
  - 所有页面（包括 Navigator.push 路由）自动获得圆形裁剪，不再依赖 IndexedStack
  - 合并 `_WebDebugShell` + `_LinuxDebugPages` → `_DebugPages`，去掉冗余嵌套
  - 重命名 `_HomePage` 为统一入口：调试模式用 IndexedStack，生产模式用 HomeScreen

## v1.9.3 — 2026-05-26

### Added
- **EpisodePreviewSheet 重构：BottomSheet → 居中圆形弹窗** (`lib/widgets/episode_preview_sheet.dart`):
  - 使用 `PageRouteBuilder(opaque: false)` + `CircularScreenClipper` 替代 `showModalBottomSheet`，弹窗边缘跟随圆形屏幕
  - 组件化重构：提取为 Widget 类结构，入口 `EpisodePreviewSheet.show()`
  - 新增 `CircularScreenClipper` 通用圆形裁剪组件 (`lib/widgets/circular_screen_clipper.dart`)
  - 内容精简：仅显示播客标题 + 半透明订阅按钮 + 最新节目列表（无缩略图）
  - 播客标题取自实际播客名称（如"科技早知道"）
  - 动态高度：内容少时自适应，内容多时限制高度并内部滚动，滑到底时底部完整可见

### Changed
- **SettingsScreen 添加 Linux Desktop 调试支持** (`lib/screens/settings_screen.dart`):
  - `_loadTopPodcasts` 增加 `Platform.isLinux` 模拟数据分支
  - `_previewPodcast` 增加 Linux 模拟 Episode 数据，无需真实 RSS 请求即可触发预览弹窗
  - 完善 mock 数据：20 期不同标题节目，覆盖滚动测试

## v1.9.2 — 2026-05-25

### Fixed
- **EpisodesScreen 列表项被圆形边缘裁剪** (`lib/widgets/episode_tile.dart`):
  - 根因：`EpisodeTile` 横向 margin 仅 ws.s(4)（≈7px），右侧播放按钮靠近圆形屏幕右边界时被裁剪
  - 修复：横向 margin ws.s(4)→ws.s(20)，播放按钮 padding ws.s(6)→ws.s(4)、icon ws.s(20)→ws.s(18)
  - 效果：第1项气泡四周留白 ~20-25px，完整可见无遮挡
- **EpisodesScreen 列表顶部/底部圆形裁剪** (`lib/screens/episodes_screen.dart`):
  - 顶部 spacer ws.s(48)→ws.s(60)，底部 padding ws.s(4)→ws.s(64)
  - 效果：列表顶部不下压，滑到底时最后一项在圆形安全区内

### Changed
- **EpisodesScreen 添加 Linux Desktop 模拟数据** — `_loadEpisodes` 增加 `Platform.isLinux` 分支，Linux 调试时直接注入 8 条模拟剧集（不用请求 RSS），方便 UI 调试

## v1.9.1 — 2026-05-25

### Changed
- **TagPickerPage 布局优化** (`lib/screens/tag_picker_page.dart`):
  - 结构改为 `SafeArea → Center → SizedBox(width:192) → Stack`，内容用 `Positioned.fill` 占满垂直空间
  - 标题 `ws.sp(14)` white w500，`Padding(top: ws.s(60))` 与 ✕ 按钮拉开距离，解决重叠问题
  - 标签气泡加大：宽度从 `(maxWidth - ws.s(12)*3)/2` 改为 `(maxWidth - ws.s(3)*3)/2`（≈92dp），更宽靠近但不贴边
  - 列间距 `spacing: ws.s(8)`、行间距 `runSpacing: ws.s(5)`、标签气泡 `vertical padding: ws.s(7)`
  - 确认按钮改为半透明毛玻璃：`BackdropFilter blur 6` + alpha 0.35 紫色/0.1 白色，透出下方标签暗示可滚动
  - `ScrollView padding bottom: ws.s(80)` 确保最后一行标签在按钮上方
- **TopActionBar compact 默认保持 true** — TagPickerPage final form 为纯图标 ✕（不是之前 compact:false 药丸），删除 compact:false 相关文档描述

### Documentation
- UI_COMPONENTS.md: 更新 TagPickerPage 节为 v1.9.x 布局描述，更新快速参考表
- CHANGELOG.md: 本次变更记录

## v1.9.0 — 2026-05-25

### Changed
- **TagPickerPage: AppBar → TopActionBar(compact: false) 迁移** (`lib/screens/tag_picker_page.dart`) — 去掉 AppBar（`backgroundColor: Colors.transparent, extendBodyBehindAppBar: true`），改用 Stack + TopActionBar(compact: false) 模式。顶部按钮改为自适应宽度药丸 `✕ 选择标签`（最小 40dp, padding 水平 12dp, borderRadius: ws.s(20)）。Content 通过 `Padding(top: ws.s(48))` 与按钮栏错开。与其他二级页面（SettingsScreen/EpisodesScreen/PlayerScreen）统一为 TopActionBar 方案。
- **TopActionBar 新增 compact 开关** (`lib/widgets/glass_components.dart`) — `TopActionBar(compact: true)`(默认) 维持 40×40 圆形按钮不变；`TopActionBar(compact: false)` 改为自适应宽度药丸（`minWidth: ws.s(40)`, padding: horizontal 12dp）。两个模式的样式统一（glass bg / border / borderRadius: ws.s(20)）。
- **_LinuxDebugPages 新增 initialPage 参数** (`lib/main.dart`) — 替代硬编码 `int _currentPage = N`。构造函数 `_LinuxDebugPages(initialPage: N)` 传索引切换调试页面，无需改源码值。页面索引: 0=Home, 1=Episodes, 2=Player, 3=Settings, 4=TagPicker。默认值 0（HomeScreen）。

### Documentation
- AGENTS.md: 更新 TagPickerPage 状态（已迁移），新增 pitfall #21 (compact:false) / #22 (initialPage)，更新 pitfall #19 (全屏统一)
- UI_COMPONENTS.md: 更新 TagPickerPage 节为 TopActionBar(compact: false) 模式，更新顶部快速参考表
- ARCHITECTURE.md: 更新 TagPickerPage 文件描述/导航图/Per-Screen Button Spec/布局代码示例
- CHANGELOG.md: 本次变更记录

## v1.8.6 — 2026-05-25

### Changed
- **TagPickerPage: 从 settings_screen.dart 提取为独立公开类** (`lib/screens/tag_picker_page.dart`) — 新增独立文件，公开 `TagPickerPage` 类 + `static show()` 便捷路由。`settings_screen.dart` 从 545 行降至 324 行。warning 从 6 降为 0。`main.dart` Linux Debug 可直接 `TagPickerPage(...)` 引用，不再需要 `debugTagPicker()` 桥接函数。其他页面(HomeScreen/TagTrack)不受影响。
- **settings_screen.dart 清理** — 删除未使用 import：`dart:io`、`Episode`、`settings_add_bar`、`settings_info_bar`；删除未使用 `_getStorageInfo()` 和 `borderRadius` 变量。

### Fixed
- **PlayerScreen 底部 -15/+15 按钮被圆形边界裁切** — 三个控制按钮在圆形屏幕底部靠两边的按钮总是被圆边界裁切。经过 4 次方案迭代：
  - ❌ LayoutBuilder + 圆方程：`LayoutBuilder` 在 `Column`/`Padding` 内获取的是 Column 可用宽度而非全屏宽度，圆方程计算出的按钮位置偏移到屏幕外
  - ❌ Stack + `Positioned(left:14 / right:14)`：233dp 逻辑屏幕太窄，14dp 偏移量仍然在圆形裁切区外
  - ❌ Row + 间距 + 底部 padding 不足：继续被裁切
  - ✅ **Row 紧凑居中 + 两侧按钮上移 8dp + 底部 16dp padding**：`-15` 和 `+15` 用 `Padding(bottom: ws.s(8))` 上移形成弧线感（"∩"形），play 按钮 52dp 居中偏大，间距 6dp，整体底部 `Padding(bottom: ws.s(16))` 提供安全距离。全部 100% 可见无裁切。
- **LayoutBuilder → Row 方案原则**：PlayerScreen 底部控制栏绝对不要在 `Column`/`Padding` 内的 `LayoutBuilder` 做全屏坐标计算——`constraints.maxWidth` = Column 可用宽度 ≠ 全屏宽度。优先用 `Row` + `mainAxisAlignment: MainAxisAlignment.center` + 相对 padding 偏移，简单可靠。

### Changed
- **-15/+15 按钮尺寸缩小**：36×36dp（原来是 `padding: all(10)` 无固定尺寸），文字 10sp（原来 13sp），borderRadius 18dp
- **play 按钮增大居中**：52×52dp（原来 padding: all(12)），图标 26sp（原来 24sp），紫色 #6C63FF alpha 0.6
- **按钮间距缩小**：从 12dp 减到 6dp，确保紧凑居中
- **底部 padding 增大**：从 8dp 增大到 16dp，提供安全距离

## v1.8.5 — 2026-05-25

### Added
- **`TopActionBar` 统一顶部操作栏组件** (`lib/widgets/glass_components.dart`) — Stack+Positioned 悬浮设计方案，消除 AppBar 底部半透明背景条和阴影。统一 40dp 圆形按钮、ws.s(6) 间距、18sp 图标。接受 `List<TopAction>` 支持任意数量按钮和三态高亮。
- **`TopAction` 按钮定义类** — `child`(图标/文字)、`onTap`(回调)、`brighter`(可选高亮)，配合 `TopActionBar` 使用。

### Changed
- **SettingsScreen: AppBar → TopActionBar + SafeArea** — 去掉 AppBar(←/🔄/➕ 三按钮) 改用 `TopActionBar`，前后按钮列表改用 Stack+Positioned 悬浮。同时 `WatchSafeArea` → `SafeArea` + `Padding(horizontal:8)`，消除圆形屏幕对列表两侧的裁剪，标题 left: ws.s(24) 避免圆形边界遮挡。
- **EpisodesScreen: WatchSafeArea → SafeArea** — 最小改动，仅替换 import 和包裹组件。保持直接 Scaffold 结构，AppBar 保留（只有一个按钮）。
- **hot_podcast_list.dart: 标题 left 间距增大** — `left: ws.s(4)` 确保圆形屏幕左上角不遮挡"🔥"和"苹"字。

### Documentation
- README.md: 更新调试流程，加入 SnapshotAction 和 xdotool 交互示例
- AGENTS.md: 添加 TopActionBar 跨引用、SafeArea 迁移说明
- CHANGELOG.md: 本次变更记录

## v1.8.4 — 2026-05-25

### Changed
- **TagTrack 标签气泡定位: 垂直跟随 → 弧线运动** — 气泡从 `Positioned(top: _dragY, right: 34)` 改为 `Positioned(top: _dragY, right: screenSize.width - _dragArcX + 29)`。`_dragArcX` 用圆方程 `cx + R*cos(θ)` 计算，气泡沿弧线滑条轨迹运动，不再是垂直上下移动。
- **TagTrack 标签气泡样式轻量化** — padding 缩小 (10→8, 6→4)、字号缩小 (12sp→10sp)、透明度降低 (0.7→0.5)、去粗体改为 w500，避免抢主内容焦点。
- **TagTrack 气泡间距优化** — 气泡右边缘与弧线左侧保持 24px 间隙（之前紧贴弧线导致拥挤感），视觉评估确认"更舒适"。

### Fixed
- **气泡与弧线重叠问题** — 之前用 `left: _dragArcX - 34` 导致气泡左边缘在弧线左侧但气泡宽度使内容重叠。改用 `right: screenSize.width - _dragArcX + 29`，气泡右边缘始终紧贴弧线左侧不重叠。
- **残留 watchpod 进程清理** — `pkill -f` 在 shell 保护下可能遗漏进程，需用 `kill -9 <PID>` 逐个清理。

### Added
- **`_dragArcX` 状态变量** — `_TagTrackState` 新增 `_dragArcX` 字段，在 `_updateFromY()` 中用圆方程同步计算弧线点的 X 坐标，供气泡弧线定位使用。

### Documentation
- UI_COMPONENTS.md: 更新 TagTrack 架构图，加入气泡弧线定位描述
- AGENTS.md: 更新 pitfall #18 加入气泡弧线定位和清理注意事项
- CHANGELOG.md: 本次变更记录

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
