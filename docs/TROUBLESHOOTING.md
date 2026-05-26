# WatchPod Troubleshooting Guide

> For AI consumption. Organized by symptom pattern.

## PATTERN: Gradle build fails — "Gradle build daemon disappeared unexpectedly"

```
Symptom: Build fails after 30-60s. Log shows daemon killed.
Root cause: OOM. Default Gradle daemon uses 2GB heap. WSL has 4GB total.
Check: free -h (during build, used >3.5GB)
Fix:
  export GRADLE_OPTS="-Xmx512m"
  flutter clean
  kill $(ps aux | grep '[g]radle' | awk '{print $2}')
  rm -rf ~/.gradle/daemon/
  flutter pub get
  flutter build apk --release --split-per-abi
```

## PATTERN: Debug APK crashes — "EM_AARCH64 instead of EM_X86_64"

```
Symptom: APK installs, app immediately exits.
  logcat: dlopen failed: "libflutter.so" is for EM_AARCH64 instead of EM_X86_64
Root cause: Built for ARM64, emulator is x86_64.
Fix: flutter build apk --debug --target-platform android-x64
```

## PATTERN: Network fails — "Connection refused" or "SocketException"

```
Symptom: DioException when accessing iTunes/RSS feeds during build or runtime.
Root cause: mihomo proxy not running (OOM killed or not started).
Check:
  ps aux | grep mihomo | grep -v grep
  curl -x http://127.0.0.1:7890 https://www.google.com -s -o /dev/null -w "%{http_code}"
Fix:
  cd ~/.config/clash && /usr/local/bin/mihomo -d .
```

## PATTERN: Flutter pub get / resolve hangs

```
Symptom: "flutter pub get" or Gradle dependency resolution hangs indefinitely.
Root cause: Proxy down OR stale Gradle daemon lock.
Check:
  ps aux | grep 'gradle'
  curl --proxy http://127.0.0.1:7890 https://pub.dev
Fix:
  kill $(ps aux | grep '[g]radle' | awk '{print $2}')
  rm -rf ~/.gradle/daemon/
  flutter pub get
```

## PATTERN: `pkill -9 -f GradleDaemon` kills mihomo too

```
Symptom: After killing Gradle, proxy also stops.
Root cause: pkill -f pattern match — mihomo in same process tree matches.
Fix: Never use pkill -f. Instead:
  ps aux | grep GradleDaemon | awk '{print $2}'
  kill -9 <pid>
```

## PATTERN: Layout clipped on round screen — top/bottom buttons missing

```
Symptom: Tags at top or action bar at bottom are partially or fully invisible.
Root cause: WatchSafeArea wraps the entire Column, clipping top/bottom edges.
Fix: Only wrap center content zone with WatchSafeArea. Top/bottom bars in outer Column.
```

## PATTERN: SettingsScreen iTunes API call fails

```
Symptom: "加载热门失败" or empty hot podcast list.
Root cause: Proxy down, or Apple ITMS RSS API changed.
Check:
  curl https://itunes.apple.com/cn/rss/toppodcasts/limit=10/json | head -5
Fix: Ensure mihomo is running. If API endpoint changed, update _loadTopPodcasts() URL.
```

## PATTERN: Dart analyze reports mismatched brackets after file patches

```
Symptom: "Expected to find ')'" or "Expected to find ']'" after multiple patch() calls.
Root cause: Cumulative parenthesis mismatches from sequential file edits.
Check:
  python3 -c "c=open('file.dart').read(); print('():',c.count('(')-c.count(')'), '{}:',c.count('{')-c.count('}'), '[]:',c.count('[')-c.count(']'))"
Fix: Re-read the affected method and count brackets, or use dart format to auto-detect.
```

## PATTERN: EpisodesScreen shows blank/empty — nothing visible

```
Symptom: Tapping a podcast card from HomeScreen opens EpisodesScreen but nothing is visible — no loading indicator, no error, no list. Just the gradient background.
Scenario A: Apple Hot Podcast list → tap → shows episodes (cache exists from subscription step)
Scenario B: HomeScreen → tap → shows blank (no cache, RSS request pending)

Root cause: Two-layer issue.
  Layer 1 — Loading invisible: When cache is empty, _loading stays `true` (never set to false). CircularProgressIndicator on dark background is nearly invisible.
  Layer 2 (critical) — Dio options syntax corrupted: Patch operations on RssService's constructor left dangling `connectTimeout`/`receiveTimeout` arguments, breaking the Dio BaseOptions. The `Dio` silently fails to apply options, so default timeout is OS-default (~2 minutes). Combined with proxy issues, RSS requests hang far longer than the user waits.

Why "Apple Hot Podcast" works but HomeScreen doesn't:
  Subscribing from SettingsScreen calls `saveEpisodes()` immediately after RSS parse. So tapping that podcast later reads the cache directly (no network wait). HomeScreen subscriptions were added in an earlier session where `saveEpisodes` wasn't called, so cache is empty on first EpisodesScreen open.

Fix:
  1. Regenerate RssService constructor — ensure BaseOptions has clean, non-duplicate args:
     RssService() : _dio = Dio(BaseOptions(
       connectTimeout: const Duration(seconds: 10),
       receiveTimeout: const Duration(seconds: 15),
     ));
  2. In _loadEpisodes, consider adding a timeout guard: if cache is empty and RSS hasn't returned in 10s, show a "loading" text explicitly (instead of bare CircularProgressIndicator).
  3. Ensure `saveEpisodes` is always called after subscription, so subsequent opens have cache.

Check:
  cat lib/services/rss_service.dart | head -20   # verify BaseOptions is clean
  flutter analyze lib/services/rss_service.dart  # 0 errors
Prevention: After any patch() to constructor or Dio code, always run `flutter analyze` on that file.
```

## PATTERN: AppBar auto-inserts back arrow at top-left [HISTORICAL]

```
Status: This was an issue in v1.6.0–v1.8.5 when screens used AppBar with `centerTitle: true`.
As of v1.9.1, all active screens use TopActionBar instead of AppBar — the issue no longer applies.

Historical reference:
Symptom: Even after setting `leading: null` and `centerTitle: true`, a back arrow appeared at the top-left.
Root cause: Flutter's AppBar defaults to `automaticallyImplyLeading: true`.
Fix (archived): `automaticallyImplyLeading: false` on each AppBar.
```

## PATTERN: WatchSafeArea causes rounded corners on rectangular phone screens

```
Symptom: When installing the watch APK on a phone for testing, content areas have rounded-corner borders (ClipRRect effect). Looks intentional but unexpected.
Root cause: WatchSafeArea uses `ClipRRect(borderRadius: BorderRadius.circular(constraints.maxWidth / 2))` — on rectangular screens the radius clips off the four corners.
Status: NOT a bug — this is expected behavior. On round watch screens the circular clip matches the bezel. On rectangular phone screens it becomes rounded corners, which the user accepted as a positive visual effect.
Fix: Do NOT attempt to detect screen shape. The rounded corners are harmless and actually improve the phone test experience. The clip is correct on target hardware (round watch).
```

## PATTERN: EpisodesScreen show "加载失败" even though cached episodes exist

```
Symptom: User opens episodes from HomeScreen → sees error/empty state. But cache file exists on disk.
  On next app restart, cache loads fine. Problem only occurs mid-session after RSS refresh fails.

Root cause: Old code path: `_loadEpisodes()` → try RSS → on error → `setState(() { _error = true })`
  → UI enters error state, discarding cached episodes.
  Since `_loadEpisodes` was called both for cache-load AND RSS-refresh in one function,
  any RSS failure would overwrite even successfully-loaded cache.

Fix (v1.9.7): Separate cache loading from RSS refresh:
  1. `_loadCachedEpisodes()` — load from file, return episodes or null
  2. If cache has data → `_episodes = cached` → `setState` → show immediately
  3. Then call `_refreshEpisodes()` in background:
     - Success → update `_episodes` + save to cache
     - Failure → keep current `_episodes` (cache value), DO NOT show error
  4. Only show error if RSS fails AND cache was empty

Check:
  cat lib/screens/episodes_screen.dart | grep -E "_loadCached|_refreshEpisodes|_loadEpisodes"
  # Should see separation of concerns between cache and refresh

Prevention: Never combine "load cache" and "refresh network" in the same function chain.
  Cache-first means: load from cache → show UI immediately → then attempt network refresh
  → network failure should NEVER affect the already-shown cache data.
```
