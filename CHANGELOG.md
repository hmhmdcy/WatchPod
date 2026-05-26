# WatchPod Changelog

## v1.9.7 — 2026-05-26

### Fixed
- **EpisodesScreen 在真机上不显示节目**：缓存节目数据存在时，RSS 网络刷新失败会覆盖缓存并显示错误页。修复：分离缓存加载和 RSS 刷新，RSS 失败不再覆盖已有缓存数据。真机网络不稳定时仍能正常查看已缓存的节目列表。
- **首页点击播客卡片无法进入节目播放列表**：`HomeScreen` 中 `Positioned.fill()` 强制约束 TagTrack 全屏，覆盖内部的 `SizedBox(width: 40)`，导致 TagTrack 的 `GestureDetector`（全屏透明区域）吞掉所有点击事件。修复：改用 `Positioned(right: 0, top: 0, bottom: 0)` 让 TagTrack 仅占据右边缘 40dp，中央 PodcastTile 的 `onTap` 恢复正常。（`home_screen.dart` / `podcast_tile.dart`）

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

