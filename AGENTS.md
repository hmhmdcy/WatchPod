# WatchPod — Agent Context

|> DEVICE: Wear OS smartwatch (round, 360x360 ~ 466x466) / Linux Desktop 466×466 circular debug shell
|> PRIMARY TARGET: Huawei Watch 3 (466×466 px, 320 DPI, ~233 dp logical)
|> SDK: Flutter 3.44 / Dart 3.12 / Android SDK 35+36
|> PACKAGE: com.watchpod.watchpod
|> TARGET: Release APK for ARMv7 (Huawei Watch 3), ARM64. Debug for x86_64 (emulator)
|> WEARSCALE BASE: 280 dp (not standard 360 dp). See ARCHITECTURE.md for rationale.
||| LINUX DEBUG: Use `DISPLAY=:0 GDK_BACKEND=x11 NO_PROXY="*" HTTP_PROXY="" HTTPS_PROXY="" flutter run -d linux --debug` with background=true + pty=true. Launch ONCE per session (wait 10-12s for window). After that, use **hot reload** (`process(action='write', session_id='<id>', data='r')`) for all code changes — ~0.6s per iteration, NOT ~30s restart. Do NOT kill/re-launch flutter run between iterations. **Use `write` (raw 'r') NOT `submit` ('r'+Enter).** Only clean up at session end. Load `wslg-x11-screenshot` skill for full debug workflow (screenshots, xdotool limitations: clicks intercepted by translucent overlays in Stack, not reliably testable on Linux).

## TRIGGER CONDITIONS

WHEN task involves:
- **UI / layout redesign / screen adapt** → load skill `watchpod-ui` FIRST, then UI_COMPONENTS.md
- **build / CI / APK** → load skill `prebuild-check`, read docs/BUILD.md
- **error / crash / network** → read docs/TROUBLESHOOTING.md
- **new feature / large refactor** → load skill `writing-plans`, read ARCHITECTURE.md + docs/ROADMAP.md
- **version tracking** → read CHANGELOG.md, update it after changes
- **environment config / install** → log to ~/.hermes/deployment-log/
- **screen adapt / layout fix** → see WearScale in lib/widgets/wear_scale.dart
- **TagTrack arc slider touch issues** → 已归档在 docs/CHANGELOG_ARCHIVE.md (v1.8.2 Fixed)
- **TagPickerPage / 标签选择** → read `lib/screens/tag_picker_page.dart` + UI_COMPONENTS.md TagPickerPage section

## KEY CROSS-REFERENCES

- **watchpod-ui skill**: Contains the complete layout specification for all screens. Load this FIRST before any UI work. It encodes the top-bar + full-content pattern, WearScale usage rules, arc track spec, and all current constraints.
- **WearScale**: Adaptive sizing system. `WearScale.of(context).sp(12)` scales 12px to fit screens. **Base is 280 dp**. All hardcoded sizes must use this.
- **TagTrack** — **已移除 (v1.9.8)**。原弧线滑条 `lib/widgets/home_tag_track.dart` 已删除。替代为右侧标签列（双模式：常显当前播客标签 / 拖拽切换筛选）。
- **TopActionBar** (`lib/widgets/glass_components.dart`): v1.8.5 新增。统一顶部操作栏组件，Stack+Positioned 悬浮。40dp 圆形按钮、6dp 间距、18sp 图标。接受 `List<TopAction>`。所有二级页面（SettingsScreen/EpisodesScreen/PlayerScreen）均使用此组件。单按钮和多按钮都适用。
- **HomeScreen**: `GlassBackground → Stack [SafeArea → WatchSafeArea(内容, padding left:42 right:42), 左侧指示点列(Positioned left:70), 右侧标签列(Positioned right:52 → Center → SizedBox(40×200) → GestureDetector), 顶部"正在播放"(Positioned top:10), 底部"添加订阅"(Positioned bottom:10)]`. 封面 PageView 垂直滑动。右侧标签列双模式：常显当前播客标签(竖向气泡) / 拖拽切换筛选(横向 Wrap，200dp 滑块垂直居中)。标签拖拽映射仅用滑块高度，非全屏。TagTrack 已移除 (v1.9.8)。
- **Web debug** (`main.dart` `_DebugPages`): `_DebugPages` provides Linux Desktop / Web multi-page debugging via `IndexedStack`. Circular clip + `MediaQuery` size override handled globally by `MaterialApp.builder` (`_circularScreenBuilder`). Pages: 0=Home, 1=Episodes, 2=Player, 3=Settings, 4=TagPicker.
- **SettingsScreen**: v1.8.5 重构为 **TopActionBar** + **SafeArea** 模式。无 AppBar。三按钮 (←, 🔄, ➕) 用 `TopActionBar` 组件 (Stack+Positioned 悬浮)。`HotPodcastList` 用 `SafeArea` 而非 `WatchSafeArea` (WatchSafeArea 的 padding 对列表太紧)。标题由 `HotPodcastList` 管理 (`showTitle: true`)，作为 ListView 头部随列表滚动。点击播客条目触发 `EpisodePreviewSheet.show()`。
- **PlayerScreen**: v1.8.5 重构为 **TopActionBar** + **SafeArea** 模式。单返回按钮。内容（封面+标题+进度条+控制按钮）在 SafeArea 内垂直居中，顶部 Spacer 留空。`ListenableBuilder` 响应 audioService 状态变化。
- **TopPodcastService**: `lib/services/top_podcast_service.dart`. 24h memory+file cache. `getTopPodcasts()` → iTunes RSS. `resolveFeedUrls()` → iTunes lookup.
- **HotPodcastList**: `lib/widgets/hot_podcast_list.dart`. Cover(42dp) + title(15sp) + subscribe(44dp). `showTitle: true` → 标题作为居中 ListView 头部随列表滚动。订阅错误通过 `subscribeError` 显示在列表上方。
- **EpisodePreviewSheet**: `lib/widgets/episode_preview_sheet.dart`. 居中弹窗预览节目列表。`PageRouteBuilder(opaque: false)` + 全局 `MaterialApp.builder` 圆形裁剪。`EpisodePreviewSheet.show(context, item, episodes, onSubscribe)`。
- **EpisodesScreen**: v1.8.5 重构为 **TopActionBar** + **Stack** 模式。无 AppBar。单按钮（多选模式→close/正常→arrow_back）用 TopActionBar 组件。无 SafeArea，无 WatchSafeArea。多选底部操作栏在 Column 内位于列表下方。
- **StorageService**: Silently returns [] on parse failure. No migration support.
- **TagPickerPage** (`lib/screens/tag_picker_page.dart`): v1.8.6 从 settings_screen.dart 提取为独立公开页面。全屏标签选择。**v1.9.0 迁移: AppBar → TopActionBar(compact: true)** 纯图标 ✕。**v1.9.1 布局优化**: `SafeArea → Center → SizedBox(192) → Stack` 结构，标签气泡加大到 ≈92dp（`(maxWidth - ws.s(3)*3)/2`），列间距 `spacing:8` 行间距 `runSpacing:5`，确认按钮半透明毛玻璃 `BackdropFilter blur 6` + alpha 0.35。`ScrollView padding bottom: 80` 确保最后一行在按钮上方。标签数据源：`PodcastSubscription.presetTags`（10个预设标签）。

## KEY PITFALLS

1. **Always load watchpod-ui skill before UI changes** — the layout spec is canonical. Don't start editing screens without loading it.
2. **Architecture mismatch**: Wear OS emulator is x86_64. `flutter build apk --debug` defaults to ARM64 → dlopen fails. Must use `--target-platform android-x64` for emulator.
3. **OOM cascade**: On 4GB WSL, Gradle OOM kills systemd → kills Gateway → kills mihomo proxy → all network requests fail. Fix: `export GRADLE_OPTS="-Xmx512m"`, kill stale daemons.
4. **Gradle daemon lock**: `flutter build` may hang on daemon lock after OOM/interrupt. Fix: `flutter clean` + specific PID kill.
5. **mihomo proxy**: Proxy at `127.0.0.1:7890`. API at `127.0.0.1:9090`. Must be running before network ops.
6. **Build/Git approval required**: Do NOT build APK or push to GitHub without user confirmation. Ask before both.
7. **Git commit before every build**: Always update CHANGELOG.md first, then `git add <files> && git commit` before `flutter build`.
8. **All action buttons at top-center, NOT sides**: Round screens clip corners. Use TopActionBar (preferred) or `centerTitle: true` on AppBar. Buttons in `leading` or `actions` are invisible on real hardware. **`WatchLayout` has been deleted (dead code since v1.8.5).**
9. **WatchSafeArea only provides adaptive padding, no clip**: Every scrollable/list content area should use WatchSafeArea for adaptive circular-safe padding. The circular clip is handled globally by MaterialApp.builder — WatchSafeArea no longer clips. Top/bottom bars stay outside.
10. **WearScale base is 280 not 360**: Huawei Watch 3 has ~233 dp logical screen. With base=280, the ratio is 233/280 ≈ 0.83× (elements shrink to 83%). **NOT** 1.32× — the old "~370 dp usable" was a calculation error. Correct logical dp from ADB: 466px / 2.0 (320dpi → xhdpi) = 233 dp.
11. **Arc track invisible on Web — 已归档 (v1.9.8, TagTrack 已移除)**: Root cause: `MediaQuery.of(context).size` returned full browser width, not the circular mask size. Fixed by (a) `MediaQuery` override in `_DebugPages` via `MaterialApp.builder` with `copyWith(size: Size(watchSize, watchSize))`, (b) `OverflowBox` in TagTrack to paint on full-screen canvas at global coordinates.
12. **Arc coordinate system — 已归档 (v1.9.8, TagTrack 已移除)**
13. **TagTrack must have GestureDetector — 已归档 (v1.9.8, TagTrack 已移除)**
14. **TagTrack must be outside SafeArea — 已归档 (v1.9.8, TagTrack 已移除)
15. **Linux Desktop: xwd NOT scrot/ffmpeg (v1.8.3)**: In WSL2/WSLg, standard screenshot tools capture WSL-internal display (blank/black). Use `xwd` to read pixels from X11 shared memory directly. Workflow: `xdotool search --name watchpod` → `xwd -id <ID> -out /tmp/wp.xwd` → `convert /tmp/wp.xwd /tmp/wp.png` → `vision_analyze`.
16. **Linux Desktop: cleanup after use (v1.8.3)**: Always run `pkill -f 'watchpod.*linux'` after debugging. Leftover processes accumulate and consume GPU/CPU resources. The 466×466 undecorated window persists on the Windows desktop until killed. **v1.8.4:** `pkill -f` may miss processes under shell protection. Use `kill -9 <PID>` with explicit PID list when `pkill` leaves survivors.
17. **标签气泡弧线定位 — 已归档 (v1.9.8, TagTrack 已移除)
18. **TopActionBar 全屏统一 (v1.8.5+)**: SettingsScreen、EpisodesScreen、PlayerScreen 均已从 AppBar 迁移到 TopActionBar + Stack 模式。**v1.9.1: TagPickerPage 也完成迁移**（使用 `TopActionBar(compact: true)` 纯图标 ✕ 按钮）。所有二级页面均已统一。只有 HomeScreen 保留 WatchSafeArea。不要在已迁移的页面上再加 AppBar。
19. **TopActionBar 单按钮用法**: EpisodesScreen 和 PlayerScreen 各只有一个按钮，也使用 TopActionBar。单按钮 TopActionBar 的 `actions` 列表长度 = 1，居中效果和 AppBar 一样好，还避免了 AppBar 的阴影/背景条问题。
20. **TopActionBar compact 模式**: `TopActionBar(compact: true)`(默认)强制 40×40 圆形按钮。`TopActionBar(compact: false)` 改为自适应宽度药丸(最小宽度 40dp, padding 水平 12dp)，适合 icon+text 双元素按钮（当前项目所有页面使用 `compact: true` 纯图标按钮）。两种模式的样式统一（glass bg / border / borderRadius: ws.s(20)）。
21. **_DebugPages initialPage 参数 (v1.9.0)**: 调试页面构造函数新增 `initialPage` 参数（默认 0 = HomeScreen），替代硬编码 `_currentPage = N`。切换调试页面只需在 `_DebugPages(initialPage: N)` 传索引，无需改源码值再改回来。索引: 0=Home, 1=Episodes, 2=Player, 3=Settings, 4=TagPicker。
22. **EpisodeTile 横向 margin (v1.9.2)**: 圆形屏幕下 `EpisodeTile` 的横向 margin 至少 `ws.s(16)`，推荐 `ws.s(20)`（≈33px）。ws.s(4) 会导致右侧播放按钮在圆形下半部分被裁切。播放按钮图标用 `ws.s(18)` 而非 `ws.s(20)` 以节省边缘空间。
23. **EpisodesScreen 顶部/底部安全距 (v1.9.2)**: `SizedBox(height: ws.s(60))` 给 TopActionBar 留空间 + 列表顶部不进圆形收窄区；`ListView padding bottom: ws.s(64)` 确保滑到底时最后一项不被裁。底部 padding < ws.s(48) 时最后一项进入圆形下缘裁切区。
24. **热重载替代重建 (v1.9.7)**: Linux Desktop 调试时，`flutter run` 保持运行，用 `process(action='write', session_id='<id>', data='r')` 发送 'r' 键触发热重载（无需回车），耗时 ~0.6s 而非重启的 ~30s。启动命令：`DISPLAY=:0 GDK_BACKEND=x11 NO_PROXY="*" HTTP_PROXY="" HTTPS_PROXY="" flutter run -d linux --debug`。使用 background=true + pty=true 模式。注意：使用 `write`（纯 'r'）而非 `submit`（'r\n'），flutter run 的 hot reload 只需按键不需回车。
25. **RSS 刷新失败不再覆盖缓存 (v1.9.7)**: EpisodesScreen 在缓存有节目数据时，后台 RSS 网络刷新失败不会覆盖已有缓存。实现：分离 `_loadCachedEpisodes()` 和 `_refreshEpisodes()` 两个阶段，RSS 失败时保持 `_isLoading=false` 且 `_episodes` 保留缓存值。真机网络不稳定时用户仍可正常浏览已缓存节目——不会突然跳到错误页。
26. **docs 已归档的文件**: `docs/KNOWN_BUGS.md` 已删除（全部内容过时）。`docs/CHANGELOG_ARCHIVE.md` 包含 v1.9.3 及更早的 changelog。Changelog 只保留最近 4 个版本（v1.9.4+）。UI_COMPONENTS.md 已剔重（架构代码移至 ARCHITECTURE.md）。ARCHITECTURE.md 中 TagPickerPage 引用已修正为 `compact: true`。`watch_layout.dart` 已删除（v1.8.5 后的死代码）。TagTrack 相关 pitfalls 从 11-14,17 标记为已归档（v1.9.8）。
27. **右侧标签列拖拽映射用滑块高度 (v1.9.9)**: `_updateTagDragFromY(y, sliderHeight)` 中 `ratio = y / sliderHeight`，滑块高度固定为 `200.0`（WearScale 缩放）。`GestureDetector` 的 `Container(height: ws.s(200))` 垂直居中在右侧 40dp 栏内。不要再用 `_screenHeight` 做映射——全屏映射拖拽距离太大，手感差。
