# WatchPod — Agent Context

> DEVICE: Wear OS smartwatch (round, 360x360 ~ 466x466)
> PRIMARY TARGET: Huawei Watch 3 (466×466 px, 320 DPI, ~233 dp logical)
> SDK: Flutter 3.44 / Dart 3.12 / Android SDK 35+36
> PACKAGE: com.watchpod.watchpod
> TARGET: Release APK for ARMv7 (Huawei Watch 3), ARM64. Debug for x86_64 (emulator)
> WEARSCALE BASE: 280 dp (not standard 360 dp). See ARCHITECTURE.md for rationale.

## TRIGGER CONDITIONS

WHEN task involves:
- **UI / layout redesign / screen adapt** → load skill `watchpod-ui` FIRST, then UI_COMPONENTS.md
- **build / CI / APK** → load skill `prebuild-check`, read docs/BUILD.md
- **error / crash / network** → read docs/TROUBLESHOOTING.md
- **new feature / large refactor** → load skill `writing-plans`, read ARCHITECTURE.md + docs/ROADMAP.md
- **version tracking** → read CHANGELOG.md, update it after changes
- **environment config / install** → log to ~/.hermes/deployment-log/
- **screen adapt / layout fix** → see WearScale in lib/widgets/wear_scale.dart

## KEY CROSS-REFERENCES

- **watchpod-ui skill**: Contains the complete layout specification for all screens. Load this FIRST before any UI work. It encodes the top-bar + full-content pattern, WearScale usage rules, arc track spec, and all current constraints.
- **WearScale**: Adaptive sizing system. `WearScale.of(context).sp(12)` scales 12px to fit screens. **Base is 280 dp**. All hardcoded sizes must use this.
- **TagTrack** (`lib/widgets/home_tag_track.dart`): Frosted-glass arc track glued to the right circular screen edge. CustomPaint arc (10dp, alpha ~0.69), OverflowBox full-screen canvas, GestureDetector vertical drag for tag switching, 2s bottom hover to add subscription. Uses circle equation `(centerX + R*cos(θ), centerY + R*sin(θ))` from -45° to 45°. Replaces the old right-side panel and thin arc line.
- **HomeScreen**: `Stack(children: [Positioned.fill(WatchSafeArea(内容)), Positioned.fill(TagTrack)])`. Full-width centered content + right-side arc track overlay. No more Row split.
- **Web debug** (`main.dart` `_WebDebugShell`): Wraps screens in `ClipRRect(circular)` + `MediaQuery(size: Size(watchSize, watchSize))` override so child widgets read correct circular dimensions on Web. No bottom nav bar.
- **SettingsScreen**: AppBar centered — 3 glass icon buttons (←, 🔄, +) in AppBar.title. Below: full-height hot podcast list. No info bar.
- **TopPodcastService**: `lib/services/top_podcast_service.dart`. 24h memory+file cache. `getTopPodcasts()` → iTunes RSS. `resolveFeedUrls()` → iTunes lookup.
- **HotPodcastList**: `lib/widgets/hot_podcast_list.dart`. Cover(42dp) + title(15sp) + subscribe(44dp). Optional `showTitle` flag.
- **EpisodesScreen**: Uses direct Scaffold (NOT WatchLayout). Only a centered back arrow (←) in AppBar title slot. Multi-select mode switches to close button. Cache-first: shows cached episodes immediately, silently refreshes RSS. **CRITICAL: Do NOT wrap in WatchLayout** — the `showAppBar: false` + `extendBodyBehindAppBar: true` combo shifts content off-screen on round hardware.
- **StorageService**: Silently returns [] on parse failure. No migration support.

## KEY PITFALLS

1. **Always load watchpod-ui skill before UI changes** — the layout spec is canonical. Don't start editing screens without loading it.
2. **Architecture mismatch**: Wear OS emulator is x86_64. `flutter build apk --debug` defaults to ARM64 → dlopen fails. Must use `--target-platform android-x64` for emulator.
3. **OOM cascade**: On 4GB WSL, Gradle OOM kills systemd → kills Gateway → kills mihomo proxy → all network requests fail. Fix: `export GRADLE_OPTS="-Xmx512m"`, kill stale daemons.
4. **Gradle daemon lock**: `flutter build` may hang on daemon lock after OOM/interrupt. Fix: `flutter clean` + specific PID kill.
5. **mihomo proxy**: Proxy at `127.0.0.1:7890`. API at `127.0.0.1:9090`. Must be running before network ops.
6. **Build/Git approval required**: Do NOT build APK or push to GitHub without user confirmation. Ask before both.
7. **Git commit before every build**: Always update CHANGELOG.md first, then `git add <files> && git commit` before `flutter build`.
8. **All action buttons at top-center, NOT sides**: Round screens clip corners. Use `centerTitle: true` + `automaticallyImplyLeading: false` on every AppBar. Buttons in `leading` or `actions` are invisible on real hardware.
9. **Do NOT refactor working screens into WatchLayout**: `WatchLayout(showAppBar: false)` with `extendBodyBehindAppBar: true` shifts content off-screen. Keep EpisodesScreen as direct Scaffold.
10. **WatchSafeArea wraps center zone only**: Every scrollable/list content area should use WatchSafeArea. Top/bottom bars stay outside.
11. **WearScale base is 280 not 360**: Huawei Watch 3 has ~233 dp logical screen. With base=280, the ratio is 233/280 ≈ 0.83× (elements shrink to 83%). **NOT** 1.32× — the old "~370 dp usable" was a calculation error. Correct logical dp from ADB: 466px / 2.0 (320dpi → xhdpi) = 233 dp.
12. **Arc track invisible on Web (v1.8.0 bug fix)**: Root cause: `MediaQuery.of(context).size` returned full browser width, not the circular mask size. Fixed by (a) `MediaQuery` override in `_WebDebugShell` with `copyWith(size: Size(watchSize, watchSize))`, (b) `OverflowBox` in TagTrack to paint on full-screen canvas at global coordinates.
13. **Arc coordinate system**: TagTrack's `CustomPaint` uses `OverflowBox` to fill the entire screen. Canvas origin (0,0) = screen (0,0). Arc points computed directly as `(centerX + R*cos(θ), centerY + R*sin(θ))` — no offset translation needed. This ensures identical rendering on Web, emulator, and real device.
