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

### Linux Desktop 调试（WSLg + 466×466 圆形窗口）

```bash
# 构建
flutter build linux --debug

# 启动（466×466 无标题栏圆形窗口）
./build/linux/x64/debug/bundle/watchpod &

# 截图（xwd 而非 scrot — WSLg 下 scrot 黑屏）
xdotool search --name watchpod        # 找窗口 ID
xwd -id <ID> -out /tmp/wp.xwd         # 抓窗口像素
convert /tmp/wp.xwd /tmp/wp.png        # 转 PNG

# 模拟交互
xdotool windowfocus <ID>
xdotool mousemove --window <ID> <X> <Y>
xdotool click 1

# 视觉评估
# vision_analyze(image_url='/tmp/wp.png')

# 清理
pkill -f 'watchpod.*linux'
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
