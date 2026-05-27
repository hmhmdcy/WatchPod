# WatchPod Changelog

## v1.9.9 — 2026-05-27

### Changed
- **主页 UI 打磨** (`lib/screens/home_screen.dart`):
  - 顶部"正在播放"按钮上边距从 `ws.s(6)` 改为 `ws.s(10)`，与底部按钮对称（~17px）
  - 统一上下按钮样式：高度 `ws.s(28)`、水平内边距 `ws.s(12)`、字号 `ws.sp(10)`、圆角 14
  - 添加订阅按钮改用 `_tagDecoration`，支持自定义颜色参数（白色半透明调）
  - 右侧标签列触摸区域从 `double.infinity`（全屏高）改为 `ws.s(200)`（滑动条区域，垂直居中）
  - 拖拽位置映射从 `_screenHeight` 改为滑块高度 `200`，灵敏度提升
  - `_updateTagDragFromY()` 接收 `sliderHeight` 参数替代硬编码全屏高
- **Linux Desktop 调试修复** (`lib/services/audio_service.dart`):
  - `try-catch` 包裹 `AudioPlayer()` 初始化，避免 Linux Desktop 因 `MissingPluginException`(just_audio) 崩溃
  - Linux Desktop 自动注入 mock Episode，使"正在播放"按钮可渲染
- **PodcastTile 去除重复标签** (`lib/widgets/podcast_tile.dart`):
  - 移除卡片内的 `Chip` 标签组件——标签仅保留在右侧标签列显示

## v1.9.8 — 2026-05-26

### Changed
- **重构主页布局** (`lib/screens/home_screen.dart`):
  - 移除 `TagTrack` 弧线滑条（`home_tag_track.dart` 依赖全部删除）
  - 新增左侧垂直分页指示点列（替代底部水平圆点）
  - 新增右侧标签列（双模式：常显当前播客标签 / 拖拽切换筛选）
  - 顶部条件显示「正在播放」紫色药丸按钮（`_openPlayer()` 从历史版本恢复）
  - 底部常驻「添加订阅」按钮（有/无订阅均显示）
  - 左右 padding 对称化，封面居中
  - 左右侧元素定位在屏幕边缘到中心线距离中点附近，保持视觉对称

## v1.9.7 — 2026-05-26

### Fixed
- **EpisodesScreen 在真机上不显示节目**：缓存节目数据存在时，RSS 网络刷新失败会覆盖缓存并显示错误页。修复：分离缓存加载和 RSS 刷新，RSS 失败不再覆盖已有缓存数据。真机网络不稳定时仍能正常查看已缓存的节目列表。
- **首页点击播客卡片无法进入节目播放列表**：TagTrack 的全屏 OverflowBox（用于全屏坐标绘制弧线）吸收了所有命中测试，且内部 GestureDetector 覆盖全屏，导致中央 PodcastTile 无法收到点击事件。修复：① OverflowBox 包裹 `IgnorePointer`（只画不挡事件）；② GestureDetector 改为 `Positioned(right:0) + SizedBox(width:40)` 限定触摸区为右侧 40dp；③ 恢复 `Positioned.fill()` 保证弧线在正确屏幕坐标绘制。（`home_tag_track.dart` / `home_screen.dart`）

## v1.9.6 — 2026-05-26

### Changed
- **HotPodcastList 标题行为重构** (`lib/widgets/hot_podcast_list.dart`):
  - 标题从 Column 固定位置移入 ListView 作为首个列表元素 → **随列表一起滚动**
  - 标题居中：`SizedBox(width: double.infinity)` + `Text(textAlign: TextAlign.center)`
  - 订阅错误提示 (`subscribeError`) 保持在列表上方临时显示，不参与滚动
- **SettingsScreen** (`lib/screens/settings_screen.dart`):
  - 移除 `Stack` + `Positioned` 标题浮层 → 标题由 `HotPodcastList` 内部管理 (`showTitle: true`)
  - 订阅错误通过 `subscribeError` 参数传递给 `HotPodcastList`
- **WatchSafeArea 去除冗余裁剪** (`lib/widgets/watch_safe_area.dart`):
  - 移除 `ClipRRect(borderRadius: circular)` — 全局 `MaterialApp.builder` 已对所有路由提供圆形裁剪
  - 保留自适应 `Padding`（内容距圆形边缘间距）— 独立有用
  - 文档注释更新：说明此组件不再负责裁剪

### Removed
- **CircularScreenClipper** (`lib/widgets/circular_screen_clipper.dart`): 删除独立圆形裁剪组件
  - 原为 `EpisodePreviewSheet` 的圆形裁剪而设计，现由 `MaterialApp.builder` 全局 `ClipRRect` 统一覆盖
  - `EpisodePreviewSheet` 中的 `ClipPath(clipper: CircularScreenClipper())` 已移除

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

