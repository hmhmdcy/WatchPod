# Known Bugs — WatchPod

> This file tracks unresolved bugs that need investigation in the next session.
> Updated: 2026-05-25

---

## #1: 弧线滑条（TagTrack）触摸无响应

**严重度：** 高 — 影响核心交互
**发现时间：** v1.8.3 调试（2026-05-25）
**涉及文件：** `lib/widgets/home_tag_track.dart`

### 症状

- 用户真机反馈：右侧弧线滑条滑动/点击无反应
- Linux Desktop 测试（xdotool 模拟点击）：顶部弧线区（y=68 附近）点击有像素变化（-124 bytes），中部/底部无变化
- 拖拽测试（y=150→315）：有像素变化（-924 bytes），说明 GestureDetector 部分触发了
- 但视觉分析显示：点击后界面没有任何可见变化——标签浮层、滑块圆点均未出现

### 已做的修复尝试

1. **v1.8.2：添加 GestureDetector 手势层** — `onVerticalDragStart/Update/End` + `onTapUp`
2. **v1.8.3：加 `behavior: HitTestBehavior.translucent`** — 让 40dp 触摸区也能接收事件

### 根因假设（待验证）

1. **坐标计算问题** — `GestureDetector` 使用 `details.localPosition.dy`，但 `_calcArcParameters` 依赖 `screenSize = MediaQuery.of(context).size`。在 Linux Desktop 圆形调试壳中，`MediaQuery` 被覆盖为 `Size(466, 466)`。如果 `GestureDetector` 在 `OverflowBox` 内获取到的坐标是屏幕全局坐标（1280×720）而不是裁剪后的 466×466，`_updateFromY` 计算出的标签索引就会错位。

2. **OverflowBox 与 GestureDetector 的坐标关系** — `GestureDetector` 放在 `OverflowBox` 外的 `Positioned.fill` 中，但 `OverflowBox` 是 `minWidth/maxWidth: screenSize.width`。`GestureDetector` 的 `child: SizedBox.expand()` 受限于其父级 `Positioned.fill`（即 SizedBox(width:40)）的范围。所以 **GestureDetector 的触摸区只有 40dp 宽**，`localPosition.dy` 也是相对于这个 40dp 条，而不是全屏坐标。

3. **`_updateFromY` 的 rawY 偏移** — 当 `GestureDetector` 在 40dp 宽的条内时，`y` 坐标范围为 0→720（相对 SizedBox）。但 `_calcArcParameters` 用的是屏幕坐标（centerY = screenHeight/2 = 360），而 GestureDetector 接收的 y 可能是 0→720（整个 Stack 高度），两者不一致。

### 验证方法

在 `_updateFromY` 开头加 `print('rawY=$rawY, arcTop=$_arcTop, arcBottom=$_arcBottom')`，查看实际坐标值。

### 修复方向（候选）

- **方案 A：** 给 `GestureDetector` 包一层 `LayoutBuilder`，输出实际尺寸，修正 `_updateFromY` 中的坐标偏移
- **方案 B：** 将 `GestureDetector` 从 `SizedBox(width:40)` 内移除，放到 `OverflowBox` 内部，在全屏坐标下检测手势
- **方案 C：** 扩大 TagTrack 的 `SizedBox(width: 40)` 为 `width: screenSize.width`，用 `HitTestBehavior.translucent` 让手势区覆盖整个屏幕，只处理右侧弧线区域的触摸

### 测试环境

- Linux Desktop 466×466 圆形窗口（已建好）
- 启动：`./build/linux/x64/debug/bundle/watchpod`
- 截图：`xwd -id $(xdotool search --name watchpod | tail -1) -out /tmp/wp.xwd && convert /tmp/wp.xwd /tmp/wp.png`
- 模拟点击：`xdotool mousemove --window <ID> 397 233 && xdotool click 1`
- 模拟拖拽：`xdotool mousedown 1 && ... mousemove ... && xdotool mouseup 1`
- 视觉评估：`vision_analyze(image_url='/tmp/wp.png')`
