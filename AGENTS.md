# WatchPod — Agent Context

> DEVICE: Wear OS smartwatch (round, 360x360 ~ 466x466)
> PRIMARY TARGET: Huawei Watch 3 (466×466 px, 320 DPI, ~370 dp usable)
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

- **watchpod-ui skill**: Contains the complete layout specification for all screens. Load this FIRST before any UI work. It encodes the top-bar + full-content pattern, WearScale usage rules, three-zone history (don't revert), and all current constraints.
- **WearScale**: Adaptive sizing system. `WearScale.of(context).sp(12)` scales 12px to fit screens. **Base is 280 dp** (set for Huawei Watch 3, which has ~370 dp usable). All hardcoded sizes must use this.
- **HomeScreen**: Top-bar layout: tag scroll row + "add" button in one line (48dp). Below: full-height podcast cover / empty state.
- **SettingsScreen**: Top-bar layout: compact "add subscription" button + refresh button (48dp). Below: full-height hot podcast list. No info bar.
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
6. **Layout clipping on round screens**: WatchSafeArea clips content to a circle. Top action bars must be OUTSIDE WatchSafeArea.
7. **EpisodesScreen first load**: No cache on first open → must wait for RSS network fetch. Subsequent opens show cached data instantly.
8. **Build approval required**: Do NOT build APK without user confirmation. Also required before pushing to GitHub.
9. **Git commit before every build**: Before running `flutter build apk --release`, always `git add -A && git commit -m "..."` with a descriptive English commit message summarizing all changes since last commit. Update CHANGELOG.md first if there are significant features or breaking changes. This ensures every APK is traceable to a specific commit for version rollback.
10. **All action buttons at top-center, NOT sides**: Round screens clip corners. Use `centerTitle: true` + `automaticallyImplyLeading: false` on every AppBar. Buttons in `leading` or `actions` are invisible on real hardware.
11. **Do NOT refactor working screens into WatchLayout**: `WatchLayout(showAppBar: false)` with `extendBodyBehindAppBar: true` shifts content off-screen. Keep EpisodesScreen as direct Scaffold.
12. **WatchSafeArea wraps center zone only**: Every scrollable/list content area should use WatchSafeArea (HomeScreen cover, EpisodesScreen list, PlayerScreen controls, SettingsScreen hot list). Top/bottom bars stay outside.
13. **WearScale base is 280 not 360**: Huawei Watch 3 has ~370 dp usable. With base=280, the ratio is 370/280 ≈ 1.32×. This ensures buttons (36dp → 47dp), icons (18sp → 24sp), and text are large enough for finger touch. When adapting for other devices, re-check actual dp and adjust if needed.
