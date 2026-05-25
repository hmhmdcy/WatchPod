# Known Bugs — WatchPod

> ~~这个文件之前记录了需要调查的 bug。所有已知 bug 已修复，归档于 CHANGELOG.md。~~
> 新的 bug 可在 CHANGELOG.md 的 `### Fixed` 章节中查看。

---

## 历史记录

### #1: 弧线滑条（TagTrack）触摸无响应 [已修复 — v1.8.2]

**严重度：** 高
**发现时间：** v1.8.3 调试（2026-05-25）
**修复版本：** v1.8.2（加 `GestureDetector` + `HitTestBehavior.translucent`）

**根因：** `TagTrack.build()` 完全没有 `GestureDetector`——弧线绘制了但没有任何手势处理器注册，垂直拖拽、点击、长按全部无响应。

**修复方案：**
1. 在弧线 `CustomPaint` 和标签浮层之间添加 `GestureDetector` 层（`onVerticalDragStart/Update/End` + `onTapUp`）
2. 使用 `SizedBox.expand()` 作为触摸目标
3. 添加 `behavior: HitTestBehavior.translucent` 确保 40dp 窄条也能响应触摸
4. `TagTrack` 移出 `SafeArea`，让触摸区域到达屏幕右边缘

**验证情况：**
- Linux Desktop 拖拽测试：有像素变化（AE > 0），拖拽渲染正常
- 视觉模型确认：滑块圆点、标签气泡均可正常拖拽渲染

### #2: TagPickerPage AppBar → TopActionBar 迁移 [待办]

**严重度：** 低
**发现时间：** v1.8.6 提取为独立页面时发现
**目标版本：** 下一轮

**现状：**
- TagPickerPage (`lib/screens/tag_picker_page.dart`) 是唯一仍使用旧 AppBar 方案的二级页面
- 其他二级页面（SettingsScreen/EpisodesScreen/PlayerScreen）均已迁移到 TopActionBar + Stack
- 当前截图验证 AppBar 无可见背景条/阴影，视觉上干净，但为了一致性建议迁移

**待完成任务：**
1. 把 AppBar 替换为 TopActionBar + Stack 模式
2. `✕ close` + "选择标签" 改为 `TopActionBar(actions: [TopAction(child: ...)])`
3. 删除 `extendBodyBehindAppBar: true`
4. 标签列表和底部确认按钮布局保持不变
