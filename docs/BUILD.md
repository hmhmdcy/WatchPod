# WatchPod Build Guide

> For AI consumption.

## Environment

| Variable | Value |
|----------|-------|
| Flutter | 3.44 (in ~/flutter) |
| Dart | 3.12 |
| Android SDK | ~/Android/Sdk (API 35 + 36) |
| Java | OpenJDK 17 (in PATH) |
| Proxy | mihomo @ 127.0.0.1:7890 (Clash API @ :9090) |
| WSL RAM | 4.8GB (AVD + Gradle need care) |

### PATH Setup
```bash
source /home/user/.bashrc_flutter
export GRADLE_OPTS="-Xmx512m"    # prevent OOM on 4GB WSL
```

## Build Commands

### Release APK (for Huawei Watch 3 / real devices)
```bash
source /home/user/.bashrc_flutter
flutter build apk --release --split-per-abi
# armeabi-v7a → build/.../app-armeabi-v7a-release.apk (16MB)
# arm64-v8a  → build/.../app-arm64-v8a-release.apk  (19MB)
```

### Debug APK (for x86_64 emulator)
```bash
flutter build apk --debug --target-platform android-x64
# → build/.../app-x86_64-debug.apk
```

### Clean build (after OOM / daemon lock)
```bash
flutter clean
kill $(ps aux | grep '[g]radle' | awk '{print $2}') 2>/dev/null
rm -rf ~/.gradle/daemon/
flutter pub get
```

## Key Constraints

- Always source `~/.bashrc_flutter` before any flutter command.
- GRADLE_OPTS must be -Xmx512m — default 2GB causes OOM + systemd cascade.
- mihomo proxy must be running before pub get or Gradle dependency resolution.
- After interrupting a build, kill stale Gradle daemons — they keep locks.
- **Do NOT build without user approval** — wait for explicit confirmation.
- Build approval is also required before pushing to GitHub.
