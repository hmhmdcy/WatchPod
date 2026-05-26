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
| **AGENTS.md** | **Always load first.** Trigger conditions + cross-refs + 27 pitfalls. |
| ARCHITECTURE.md | Architecture, call chains, storage constraints, TagTrack coordinate system. |
| UI_COMPONENTS.md | Design tokens, component API, glass button style. |
| CHANGELOG.md | Version history (v1.9.4+). Update after changes. |
| docs/BUILD.md | Build env, commands, constraints, hot reload workflow. |
| docs/TROUBLESHOOTING.md | Error pattern recognition (10 patterns). |
| docs/ROADMAP.md | Future plans. Read before starting new features. |
| docs/CHANGELOG_ARCHIVE.md | Historical changelog (v1.9.3 and older). |
