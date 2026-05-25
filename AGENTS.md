# WatchPod — Agent Context

|> DEVICE: Wear OS smartwatch (round, 360x360 ~ 466x466) / Linux Desktop 466×466 circular debug shell
|> PRIMARY TARGET: Huawei Watch 3 (466×466 px, 320 DPI, ~233 dp logical)
|> SDK: Flutter 3.44 / Dart 3.12 / Android SDK 35+36
|> PACKAGE: com.watchpod.watchpod
|> TARGET: Release APK for ARMv7 (Huawei Watch 3), ARM64. Debug for x86_64 (emulator)
|> WEARSCALE BASE: 280 dp (not standard 360 dp). See ARCHITECTURE.md for rationale.
||> LINUX DEBUG: Use `flutter run -d linux --debug` NOT direct binary. Direct binary (`./build/linux/x64/debug/bundle/watchpod`) may start without creating a visible X11 window in WSLg. Build first, then kill old flutter run, launch via `flutter run -d linux --debug` (wait 10-12s for window). Load `wslg-x11-screenshot` skill for full debug workflow (截图 xwd/import, 录屏 ffmpeg, 模拟交互 xdotool, 清理). Cleanup: pkill -f 'watchpod.*linux'. After screenshot, ALWAYS send to user via Feishu: send_message(target:"feishu", message:"MEDIA:<path>\\n说明").

## TRIGGER CONDITIONS

WHEN task involves:
- **UI / layout redesign / screen adapt** → load skill `watchpod-ui` FIRST, then UI_COMPONENTS.md
- **build / CI / APK** → load skill `prebuild-check`, read docs/BUILD.md
- **error / crash / network** → read docs/TROUBLESHOOTING.md
- **new feature / large refactor** → load skill `writing-plans`, read ARCHITECTURE.md + docs/ROADMAP.md
- **version tracking** → read CHANGELOG.md, update it after changes
- **environment config / install** → log to ~/.hermes/deployment-log/
- **screen adapt / layout fix** → see WearScale in lib/widgets/wear_scale.dart
- **TagTrack arc slider touch issues** → read docs/KNOWN_BUGS.md (已归档，详见 CHANGELOG.md v1.8.2 Fixed)

## KEY CROSS-REFERENCES

- **watchpod-ui skill**: Contains the complete layout specification for all screens. Load this FIRST before any UI work. It encodes the top-bar + full-content pattern, WearScale usage rules, arc track spec, and all current constraints.
- **WearScale**: Adaptive sizing system. `WearScale.of(context).sp(12)` scales 12px to fit screens. **Base is 280 dp**. All hardcoded sizes must use this.
- **TagTrack** (`lib/widgets/home_tag_track.dart`): Frosted-glass arc track glued to the right circular screen edge. CustomPaint arc (10dp, alpha ~0.69), OverflowBox full-screen canvas, GestureDetector vertical drag for tag switching, 2s bottom hover to add subscription. Uses circle equation `(centerX + R*cos(θ), centerY + R*sin(θ))` from -45° to 45°. **v1.8.4: 标签气泡沿弧线运动** — `_dragArcX` 用圆方程同步计算，气泡右边缘紧贴弧线左侧 (24px 间隙)，轻量化样式 (10sp, alpha 0.5, w500)。Replaces the old right-side panel and thin arc line.
- **TopActionBar** (`lib/widgets/glass_components.dart`): v1.8.5 新增。统一顶部操作栏组件，Stack+Positioned 悬浮。40dp 圆形按钮、6dp 间距、18sp 图标。接受 `List<TopAction>`。所有二级页面（SettingsScreen/EpisodesScreen/PlayerScreen）均使用此组件。单按钮和多按钮都适用。
- **HomeScreen**: `GlassBackground → Stack [SafeArea → WatchSafeArea(内容), TagTrack(outside SafeArea)]`. Full-width centered content + right-side arc track overlay. TagTrack in outermost Stack to avoid SafeArea padding clipping touch zone. See pitfall #15.
- **Web debug** (`main.dart` `_WebDebugShell`): Wraps screens in `ClipRRect(circular)` + `MediaQuery(size: Size(watchSize, watchSize))` override so child widgets read correct circular dimensions on Web. No bottom nav bar.
- **SettingsScreen**: v1.8.5 重构为 **TopActionBar** + **SafeArea** 模式。无 AppBar。三按钮 (←, 🔄, ➕) 用 `TopActionBar` 组件 (Stack+Positioned 悬浮)。`HotPodcastList` 用 `SafeArea` 而非 `WatchSafeArea` (避免圆形裁剪列表两侧)。标题 left: ws.s(24) 防左上角遮挡。
- **PlayerScreen**: v1.8.5 重构为 **TopActionBar** + **SafeArea** 模式。单返回按钮。内容（封面+标题+进度条+控制按钮）在 SafeArea 内垂直居中，顶部 Spacer 留空。`ListenableBuilder` 响应 audioService 状态变化。
- **TopPodcastService**: `lib/services/top_podcast_service.dart`. 24h memory+file cache. `getTopPodcasts()` → iTunes RSS. `resolveFeedUrls()` → iTunes lookup.
- **HotPodcastList**: `lib/widgets/hot_podcast_list.dart`. Cover(42dp) + title(15sp) + subscribe(44dp). Optional `showTitle` flag.
- **EpisodesScreen**: v1.8.5 重构为 **TopActionBar** + **Stack** 模式。无 AppBar。单按钮（多选模式→close/正常→arrow_back）用 TopActionBar 组件。无 SafeArea，无 WatchSafeArea。多选底部操作栏在 Column 内位于列表下方。
- **StorageService**: Silently returns [] on parse failure. No migration support.

## KEY PITFALLS

1. **Always load watchpod-ui skill before UI changes** — the layout spec is canonical. Don't start editing screens without loading it.
2. **Architecture mismatch**: Wear OS emulator is x86_64. `flutter build apk --debug` defaults to ARM64 → dlopen fails. Must use `--target-platform android-x64` for emulator.
3. **OOM cascade**: On 4GB WSL, Gradle OOM kills systemd → kills Gateway → kills mihomo proxy → all network requests fail. Fix: `export GRADLE_OPTS="-Xmx512m"`, kill stale daemons.
4. **Gradle daemon lock**: `flutter build` may hang on daemon lock after OOM/interrupt. Fix: `flutter clean` + specific PID kill.
5. **mihomo proxy**: Proxy at `127.0.0.1:7890`. API at `127.0.0.1:9090`. Must be running before network ops.
6. **Build/Git approval required**: Do NOT build APK or push to GitHub without user confirmation. Ask before both.
7. **Git commit before every build**: Always update CHANGELOG.md first, then `git add <files> && git commit` before `flutter build`.
8. **All action buttons at top-center, NOT sides**: Round screens clip corners. Use TopActionBar (preferred) or `centerTitle: true` on AppBar. Buttons in `leading` or `actions` are invisible on real hardware.
9. **Do NOT refactor working screens into WatchLayout**: `WatchLayout(showAppBar: false)` with `extendBodyBehindAppBar: true` shifts content off-screen. Keep EpisodesScreen as direct Scaffold.
10. **WatchSafeArea wraps center zone only**: Every scrollable/list content area should use WatchSafeArea. Top/bottom bars stay outside.
11. **WearScale base is 280 not 360**: Huawei Watch 3 has ~233 dp logical screen. With base=280, the ratio is 233/280 ≈ 0.83× (elements shrink to 83%). **NOT** 1.32× — the old "~370 dp usable" was a calculation error. Correct logical dp from ADB: 466px / 2.0 (320dpi → xhdpi) = 233 dp.
12. **Arc track invisible on Web (v1.8.0 bug fix)**: Root cause: `MediaQuery.of(context).size` returned full browser width, not the circular mask size. Fixed by (a) `MediaQuery` override in `_WebDebugShell` with `copyWith(size: Size(watchSize, watchSize))`, (b) `OverflowBox` in TagTrack to paint on full-screen canvas at global coordinates.
13. **Arc coordinate system**: TagTrack's `CustomPaint` uses `OverflowBox` to fill the entire screen. Canvas origin (0,0) = screen (0,0). Arc points computed directly as `(centerX + R*cos(θ), centerY + R*sin(θ))` — no offset translation needed. This ensures identical rendering on Web, emulator, and real device.
14. **TagTrack must have GestureDetector (v1.8.2)**: The arc is purely visual without a gesture handler. `TagTrack.build()` must always include a `GestureDetector` with `onVerticalDragStart/Update/End` and `onTapUp`. Without it, drag/tap on the arc has zero effect.
15. **TagTrack must be outside SafeArea (v1.8.2)**: On round screens, `SafeArea` adds padding that shifts the 40dp touch zone away from the screen right edge. In `HomeScreen.build()`, TagTrack's `Positioned.fill` must be in the outer `Stack` (outside `SafeArea`), not nested inside it.
16. **Linux Desktop: xwd NOT scrot/ffmpeg (v1.8.3)**: In WSL2/WSLg, standard screenshot tools capture WSL-internal display (blank/black). Use `xwd` to read pixels from X11 shared memory directly. Workflow: `xdotool search --name watchpod` → `xwd -id <ID> -out /tmp/wp.xwd` → `convert /tmp/wp.xwd /tmp/wp.png` → `vision_analyze`.
17. **Linux Desktop: cleanup after use (v1.8.3)**: Always run `pkill -f 'watchpod.*linux'` after debugging. Leftover processes accumulate and consume GPU/CPU resources. The 466×466 undecorated window persists on the Windows desktop until killed. **v1.8.4:** `pkill -f` may miss processes under shell protection. Use `kill -9 <PID>` with explicit PID list when `pkill` leaves survivors.
18. **标签气泡弧线定位 (v1.8.4)**: 气泡 `Positioned(top: _dragY, right: screenSize.width - _dragArcX + 29)` 中 `_dragArcX` 在 `_updateFromY()` 中用圆方程 `cx + R*cos(θ)` 同步计算。**不要直接用 `left: _dragArcX - N`** —— 气泡有动态宽度，用 `left` 会让气泡内容与弧线重叠。必须用 `right` 从屏幕右边缘算，确保气泡右边缘紧贴弧线左侧。气泡样式已轻量化（10sp, alpha 0.5），不要改回 12sp/bold。
19. **TopActionBar 全屏统一 (v1.8.5)**: SettingsScreen、EpisodesScreen、PlayerScreen 均已从 AppBar 迁移到 TopActionBar + Stack 模式。只有 HomeScreen 保留 WatchSafeArea。不要在已迁移的页面上再加 AppBar。
20. **TopActionBar 单按钮用法**: EpisodesScreen 和 PlayerScreen 各只有一个按钮，也使用 TopActionBar。单按钮 TopActionBar 的 `actions` 列表长度 = 1，居中效果和 AppBar 一样好，还避免了 AppBar 的阴影/背景条问题。
