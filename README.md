# WatchPod

Wear OS podcast aggregator · RSS-based · Flutter 3.44

## Quick Start

```bash
source ~/.bashrc_flutter
export GRADLE_OPTS="-Xmx512m"
flutter pub get
flutter build apk --release --split-per-abi
# APK: build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
```

## Docs

| File | When to read |
|------|-------------|
| **AGENTS.md** | **Always load first.** Trigger conditions + cross-refs + pitfalls. |
| ARCHITECTURE.md | Architecture, call chains, storage constraints. |
| UI_COMPONENTS.md | Design tokens, component API, screen templates. |
| CHANGELOG.md | Version history. Update after changes. |
| docs/BUILD.md | Build env, commands, constraints. |
| docs/TROUBLESHOOTING.md | Error pattern recognition. |
| docs/ROADMAP.md | Future plans. Read before starting new features. |
