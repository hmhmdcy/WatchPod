# WatchPod Build Guide

> For AI consumption. Run from `~/watchpod/`. Environment: `source ~/.bashrc_flutter` first.

## Build Environment

| Tool | Version |
|------|---------|
| Flutter | 3.44.0 stable |
| Dart | 3.12.0 |
| JDK | OpenJDK 17.0.18 |
| Android SDK | API 35 + 36 |
| Gradle | 9.1.0 |
| NDK | 28.2.13676358 |

## Commands

```bash
# Build all arch (52MB)
flutter build apk --release

# Split by arch (16-20MB each — RECOMMENDED)
flutter build apk --release --split-per-abi
# → build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# Pre-build check (RSS URLs + flutter analyze + tests)
bash tools/pre_build_check.sh
```

## Constraints

- **RAM: 4GB total** → Gradle Xmx=2G (set in android/gradle.properties). Xmx > 2G causes OOM.
- **Proxy: Clash (mihomo) @ :7890** — systemd user service, auto-restart on crash (~3s). Required for Flutter/Gradle downloads behind GFW.
- **NO_PROXY**: `storage.googleapis.com,download.flutter.io` → direct, never through proxy (causes SSL errors).

## Proxy Failure Diagnosis

**Symptom**: `SSLHandshakeException: Remote host terminated the handshake` during build
**Root cause 90%**: Clash died (OOM killed Gateway → kills Clash → all network fails)
**Check**: `systemctl --user is-active mihomo`
**Don't**: Tweak Gradle TLS config. **Do**: Restart proxy, retry.

## Build Flow (Complete)

```bash
source ~/.bashrc_flutter
systemctl --user is-active mihomo || systemctl --user start mihomo
cd ~/watchpod && bash tools/pre_build_check.sh
flutter pub get
flutter build apk --release --split-per-abi
ls -lh build/app/outputs/flutter-apk/
```

## Config Files

| File | Purpose |
|------|---------|
| `~/.bashrc_flutter` | Flutter PATH + Android SDK + proxy env vars |
| `android/gradle.properties` | JVM args: Xmx2G, TLS protocols |
| `~/.config/clash/config.yaml` | Proxy rules (DIRECT for googleapis.com) |
