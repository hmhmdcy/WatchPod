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

# 查看当前 x11 窗口列表
xwininfo -root -tree | grep watchpod

# 启动（466×466 无标题栏圆形窗口）
./build/linux/x64/debug/bundle/watchpod &

# 窗口 ID 查询（主窗口 10×10，子窗口 466×466）
xdotool search --name watchpod

# 截图（xwd 而非 scrot — WSLg 下 scrot 黑屏）
# 注意：用子窗口 ID（466×466 的，不是父窗口）
xwd -id <子窗口ID> -out /tmp/wp.xwd
convert /tmp/wp.xwd /tmp/wp.png

# 模拟交互
xdotool windowfocus <ID>
xdotool mousemove --window <ID> <X> <Y>
xdotool click 1

# 视觉评估
# vision_analyze(image_url='/tmp/wp.png')

# 流程化评估: SnapshotAction (kill + screenshot)
# 定义在 .hermes/skills/.../watchpod-ui/SKILL.md

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
