# WatchPod UI Components Reference

> For AI consumption. All sizes use WearScale for adaptive scaling (base=280).

## Design Tokens

### Colors

| Token | Hex | Usage |
|-------|-----|-------|
| Primary | `#6C63FF` | Accent, selected state, active tags, subscribe btn |
| Glass bg | `Colors.white @ 0.1` | Frosted glass buttons |
| Glass border | `Colors.white @ 0.12` | Button borders |
| Background start | `#1A1A2E` | Gradient top-left |
| Background mid | `#16213E` | Gradient middle |
| Background end | `#0F3460` | Gradient bottom-right |
| Text primary | `Colors.white` | Titles, labels |
| Text secondary | `Colors.grey[400..600]` | Subtitles, authors |
| Arc track | `Color(0xB0FFFFFF)` | Semi-transparent white arc on right edge |

### Typography

| Role | Base Size | Weight | Usage |
|------|-----------|--------|-------|
| card-title | 13 | bold | Episode titles, podcast names |
| body | 12 | normal | Episode titles |
| subtitle | 11 | normal | Author names |
| caption | 9-10 | normal | Timestamps, hints |
|| arc-label | 10 | w500 | TagTrack floating label bubble (v1.8.4: 轻量化) |

### Virtual Tokens

| Token | Behavior |
|-------|----------|
| `ws.sp(X)` | Font size, scales from 280dp base |
| `ws.s(X)` | Spacing, padding, scales linearly |
| `ws.capped(X, maxScale: 1.2)` | Scales but caps at 1.2x (for covers) |
| `ws.fs(X)` | Font size with floor (prevent oversized) |

## Layout Architecture Overview

Since v1.8.1, TWO layout patterns are used depending on screen:

| Screen | Pattern | Content |
|--------|---------|---------|
| **HomeScreen** | Stack + right arc track overlay | Full-width content (centered) + TagTrack overlay |
| **SettingsScreen** | Stack + TopActionBar overlay + SafeArea | No AppBar. Buttons float in TopActionBar. `SafeArea` instead of `WatchSafeArea`. |
| **EpisodesScreen** | Stack + TopActionBar overlay | Single centered button in TopActionBar (arrow_back / close). |
| **PlayerScreen** | Stack + TopActionBar overlay + SafeArea | Single centered back button in TopActionBar. Center content in SafeArea. |
| **TagPickerPage** | Stack + TopActionBar(compact: true) overlay | Pure icon ✕ circle button (default compact). Tag grid 2-col layout. Mid-bottom floating confirm btn, translucent frosted glass (BackdropFilter blur 6). ScrollView with bottom padding for last-row clearance. |

## HomeScreen Layout (v1.8.2+)

**IMPORTANT (v1.8.2 fix):** TagTrack must be **outside** `SafeArea`. See ARCHITECTURE.md for rationale.

```
  ┌──────────────────────┐
  │                        │
  │         ┌────┐        │ ╲ ← TagTrack arc (10dp frosted glass)
  │         │封面│        │ ╱   -45° to 45°, circle equation
  │         └────┘        ╲  紧贴圆形右边缘
  │       标题 / 作者      ╱
  │       ●    ●    ●     ╲
  │                        │
  └──────────────────────┘
```

### Architecture Detail (v1.8.2+)

```dart
// HomeScreen.build() — v1.8.2
return Scaffold(
  extendBodyBehindAppBar: true,
  body: GlassBackground(
    child: Stack(
      children: [
        // Content inside SafeArea
        SafeArea(
          child: _subscriptions.isEmpty
              ? _emptyState(ws)
              : Positioned.fill(
                  child: WatchSafeArea(
                    child: _buildPodcastSection(ws),
                  ),
                ),
        ),
        // TagTrack OUTSIDE SafeArea — gesture region reaches screen edge
        if (_subscriptions.isNotEmpty)
          Positioned.fill(
            child: _buildTopBar(ws),  // → TagTrack
          ),
      ],
    ),
  ),
);
```

**Why SafeArea separation:** On round screens (Huawei Watch 3), `SafeArea` adds padding on all four edges. If TagTrack is inside SafeArea, its 40dp touch zone shifts inward and becomes unreachable on the right edge.

### Architecture Detail (v1.8.1, superseded)

```dart
Stack(
  children: [
    Positioned.fill(
      child: WatchSafeArea(
        child: _buildPodcastSection(ws),
      ),
    ),
    Positioned.fill(
      child: _buildTopBar(ws),
    ),
  ],
)
```

**Why Stack instead of Row:** Previous `Row(children: [Expanded(...), SizedBox(width:24, TagTrack)])` offset the geometric center by 12dp, making the podcast cover appear off-center. Stack with `Positioned.fill` keeps WatchSafeArea truly centered.

### HomeScreen Content

- **Empty state:** `_buildEmptyState(ws)` — centered icon + "还没有订阅播客" + "添加一个订阅开始收听" + bottom-center "添加" button
- **Has subscriptions:** `_buildPodcastSection(ws)` inside WatchSafeArea
  - 1 item: center-aligned `PodcastTile`, coverSize `ws.capped(96, maxScale: 1.2)`
  - Multiple: `PageView.builder(scrollDirection: Axis.vertical)`, each page = PodcastTile + dot indicator
  - Tap cover → `_openEpisodes(sub)`

## TagTrack — Right Edge Frosted-Glass Arc Track

### Architecture (v1.8.4+)

```
SizedBox(width:40, height:screenHeight)    ← touch zone (40dp wide)
  └─ Stack
       ├─ Positioned.fill
       │   └─ OverflowBox(minWidth:screenWidth)
       │       └─ CustomPaint(size: screenSize)
       │           └─ _TagTrackArcPainter   ← arc at screen-global coordinates
       │              - canvas origin (0,0) = screen (0,0)
       │              - arc: x=CX+R*cos(θ), y=CY+R*sin(θ)  (-45° to 45°)
       │              - 10dp semi-transparent white + MaskFilter blur
       ├─ Positioned.fill
       │   └─ GestureDetector              ← v1.8.2 fix
       │       └─ SizedBox.expand()
       │          onVerticalDragStart → _isDragging = true
       │          onVerticalDragUpdate → _updateFromY(→ hover label)
       │          onVerticalDragEnd → _commitLabel()
       │          onTapUp → _commitLabel()
       └─ Positioned.fill (v1.8.4: OverflowBox + Stack for label overlays)
           └─ OverflowBox(minWidth:screenWidth)  ← 全屏坐标系
               └─ Stack
                   └─ Positioned(
                        top: _dragY - 12,
                        right: screenWidth - _dragArcX + 29,
                      )
                      └─ _buildLabelBubble(label)
                         - 气泡沿弧线运动: _dragArcX = cx + R*cos(θ)
                         - 气泡右边缘紧贴弧线左侧, 24px 间隙
                         - 轻量化样式: 字号 10sp, alpha 0.5, w500
```

### Key Design Decisions

| Decision | Why |
|----------|-----|
| `OverflowBox` instead of `Positioned.fill(left:-N)` | `OverflowBox` gives true full-screen canvas at correct world-space coordinates. `Positioned.fill(left:-N)` introduced coordinate translation bugs because the offset depends on parent container width, which differs between Web and real device. |
| `arcRadius = r` (no inset) | User explicitly wanted arc "紧贴圆边" (tight against the circular bezel) |
| -45° to 45° | Arc covers ~1/4 circle (right side, about half screen height). User said previous full right semicircle was "太长了" |
| `MaskFilter.blur(BlurStyle.normal, 10)` | Creates frosted glass glow under the semi-transparent white stroke. First layer: 14dp blur + 0.15 opacity. Top layer: 10dp + 0.69 opacity. |
| `GestureDetector` in SizedBox(40dp) | Touch zone restricted to right edge so swiping left side won't trigger tag changes. **v1.8.2 fix:** Previously missing entirely (arc was drawn but no gesture handler). Added as a full `SizedBox.expand()` layer between arc painting and label overlay. |

### Interaction Model

- **Idle state:** Arc visible on right edge (frosted glass, 10dp)
- **Touch near arc** (within 30dp of nearest point): Activates drag — white slider dot (6dp radius) + purple floating label bubble (v1.8.4: 气泡沿弧线运动，右边缘紧贴弧线左侧，轻量化样式不再抢主内容焦点)
- **Drag:** Labels change as slider passes through each tag zone: "全部" → [tag1] → [tag2] → ... (v1.8.4: 气泡跟随弧线轨迹，X 和 Y 同步变化)
- **Bottom 85%+:** 2s hold → purple glow + "添加订阅" bubble → auto-navigate to SettingsScreen
- **Lift:** Commits selected tag as active filter

## SettingsScreen Layout (v1.8.5+)

**TopActionBar pattern:** No AppBar. Buttons are `TopActionBar` (Stack+Positioned overlay) floating on content.

```dart
Scaffold(
  body: GlassBackground(
    child: Stack(
      children: [
        // Content — SafeArea(horizontal:8) instead of WatchSafeArea
        SafeArea(
          child: Padding(
            padding: EdgeInsets.only(top: ws.s(48)), // room for TopActionBar
            child: Column(
              children: [
                Expanded(
                  child: HotPodcastList(
                    showTitle: true,  // 标题在 ListView 内部，居中，随列表滚动
                    onItemTap: ...,
                    onSubscribe: ...,
                  ),
                ),
              ],
            ),
          ),
        ),
        // TopActionBar — float above content, outside SafeArea
        TopActionBar(
          actions: [
            TopAction(child: Icon(Icons.arrow_back, size: ws.s(18)), onTap: pop),
            TopAction(child: Icon(Icons.refresh, size: ws.s(18)), onTap: refresh),
            TopAction(child: Icon(Icons.add, size: ws.s(18)), onTap: add),
          ],
        ),
      ],
    ),
  ),
);
```

**Why:** AppBar leaves a semi-transparent background bar + shadow line even with transparent bg. TopActionBar + Stack eliminates all traces of AppBar UI artifacts.

**Why SafeArea instead of WatchSafeArea:** WatchSafeArea clips content edges to the circular mask radius, cutting off list card edges on round screens. `SafeArea` only adds system-inset padding (status bar, chin) without circular clipping, letting list cards render fully visible on both square and round screens.

## EpisodesScreen Layout (v1.8.5+)

**TopActionBar pattern (single button):** No AppBar. Stack + TopActionBar overlay.

```dart
Scaffold(
  body: GlassBackground(
    child: Stack(
      children: [
        Column(
          children: [
            SizedBox(height: ws.s(60)), // room for TopActionBar (v1.9.2: 60 for round-screen safety)
            Expanded(child: episodeList),
            if (_selectionMode) _bottomActionBar, // batch download/delete
          ],
        ),
        TopActionBar(
          actions: [
            TopAction(
              child: Icon(_selectionMode ? Icons.close : Icons.arrow_back, ...),
              onTap: _selectionMode ? _exitSelectionMode : () => Navigator.pop(context),
            ),
          ],
        ),
      ],
    ),
  ),
);
```

**IMPORTANT (v1.8.5):** No SafeArea, no WatchSafeArea. Content is now inside Column directly. The multi-select bottom bar stays inside the Column, below the Expanded list. The TopActionBar icon and callback switch based on `_selectionMode`.

## PlayerScreen Layout (v1.8.6+)

**TopActionBar pattern (single button):** Same Stack structure as EpisodesScreen.

```dart
Scaffold(
  body: GlassBackground(
    child: Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: EdgeInsets.only(top: ws.s(48)),
            child: Center(
              child: ListenableBuilder(...),
            ),
          ),
        ),
        TopActionBar(
          actions: [
            TopAction(child: Icon(Icons.arrow_back, ...),
                onTap: () => Navigator.pop(context)),
          ],
        ),
      ],
    ),
  ),
);
```

### 底部控制按钮 — 弧形排列方案 (v1.8.6)

三个控制按钮（-15 / play / +15）沿底部弧形排列，避免圆形屏幕左右两侧裁切：

```dart
// ─── 播放控制按钮（弧形排列） ───
// -15 · play · +15 紧凑居中，两侧按钮上移呈弧线感
// 整体底部留足安全距离，避免被圆形边界裁切
Padding(
  padding: EdgeInsets.only(bottom: ws.s(16)),   // ← 整体安全距离
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // -15 — 上移 8dp 形成弧线上方
      Padding(
        padding: EdgeInsets.only(bottom: ws.s(8)),
        child: Container(
          width: ws.s(36), height: ws.s(36),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(ws.s(18)),
          ),
          child: Center(
            child: Text('-15', style: TextStyle(
              fontSize: ws.sp(10), color: Colors.white,
              fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      SizedBox(width: ws.s(6)),
      // 播放/暂停（紫色，居中偏大，弧线最底部）
      GestureDetector(
        onTap: () => audioService.togglePlayPause(),
        child: Container(
          width: ws.s(52), height: ws.s(52),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(ws.s(26)),
          ),
          child: Center(
            child: Icon(
              audioService.isPlaying || audioService.isBuffering
                  ? Icons.pause : Icons.play_arrow,
              color: Colors.white, size: ws.s(26),
            ),
          ),
        ),
      ),
      SizedBox(width: ws.s(6)),
      // +15 — 上移 8dp 形成弧线上方
      Padding(
        padding: EdgeInsets.only(bottom: ws.s(8)),
        child: Container(
          width: ws.s(36), height: ws.s(36),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(ws.s(18)),
          ),
          child: Center(
            child: Text('+15', style: TextStyle(
              fontSize: ws.sp(10), color: Colors.white,
              fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    ],
  ),
)
```

### 方案演进（避免重复踩坑）

| # | 方案 | 结果 | 根因 |
|---|------|------|------|
| 1 | `LayoutBuilder` + 圆方程 | ❌ 按钮渲染到屏幕外 | `LayoutBuilder` 在 `Column`/`Padding` 内获取的 `constraints.maxWidth` = Column 可用宽度 ≠ 全屏宽度 |
| 2 | `Stack` + `Positioned(left:14 / right:14)` | ❌ 仍然被圆边界裁切 | 233dp 屏幕太窄，>14dp 的偏移量就在圆形裁切区外 |
| 3 | `Row` + 间距调整, 底部 padding=8 | ❌ 继续被裁切 | 底部安全距离不足 |
| 4 | **`Row` 紧凑居中 + 两侧上移 8dp + 底部 16dp** | ✅ **100% 可见** | 6dp 间距让三个按钮紧贴底部的中线区域，偏移仅 8dp 避免超出圆形范围 |

**核心原则：** PlayerScreen 底部控制栏绝对不要在 `Column`/`Padding` 内的 `LayoutBuilder` 做全屏坐标计算。优先用 `Row(mainAxisAlignment: MainAxisAlignment.center)` + 相对 `Padding` 偏移，简单可靠。

| Button | Size | Style | Position |
|--------|------|-------|----------|
| -15/+15 | 36×36dp, 10sp text, radius 18dp | Glass (white 0.08) | 上移 8dp (弧线两侧) |
| Play/Pause | 52×52dp, 26sp icon, radius 26dp | Primary #6C63FF alpha 0.6 | 居中 (弧线底部) |
| Button gap | 6dp | — | 紧凑居中 |
| Bottom safe | 16dp padding | — | 整体安全距离 |

Content: cover (68dp) + title + progress slider + -15/play/+15 controls. All centered vertically with Spacer at top.

## Glass Button Style

```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(ws.s(14)),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.15),
      width: 0.5,
    ),
  ),
)
```

**AppBar glass pill:** height 36dp, padding horizontal ws.s(12), icon 16-18sp, text 12-13sp.

## Web Debug Shell

```dart
class _WebDebugShell extends StatefulWidget {
  // Wraps all 4 screens (Home, Episodes, Player, Settings) in:
  // Center > ClipRRect(circular) > MediaQuery(size override) > SizedBox
  // No bottom nav bar. Switch pages by editing _currentPage in source code.
}
```

For accurate round-screen simulation, the `MediaQuery` override is **critical** — without it, `MediaQuery.of(context).size` returns the full browser window size (e.g. 1280×720) instead of the circular mask size (e.g. 577×577), causing arc equation coordinates to be wrong.

## Key Components

### PodcastTile
- Params: title, author, imageUrl, tags, onTap, coverSize
- Cover: `ws.capped(96, maxScale: 1.2)` on HomeScreen (single podcast)
- Tags: purple glass pills, max 3 shown

### EpisodeTile (v1.9.2)
- Params: title, duration, imageUrl, isDownloaded, isPlaying, isSelected, onTap, onLongPress
- Cover `ws.capped(36, maxScale: 1.1)`. Row layout with 3 zones.
- **Round-screen safety margins:**
  - Horizontal margin: `ws.s(20)` ≈ 33px (prevents right-side clipping on circular bezel)
  - Play button: icon `ws.s(18)` + padding `ws.s(4)` — compact to fit near right edge
  - Title font: `ws.sp(13)`, duration: `ws.sp(11)`
- **Bottom padding:** `ws.s(64)` for EpisodesScreen ListView — last item stays in circular safe zone when scrolled to bottom

### HotPodcastList
- Props: items, loading, error, subscribeError, showTitle, onItemTap, onSubscribe
- `showTitle: true` → 标题作为 ListView 首个元素，居中显示（`SizedBox(width: double.infinity)` + `textAlign: TextAlign.center`），**随列表滚动**
- `subscribeError` → 红色渐变提示条，显示在列表上方（不参与滚动，瞬态提示）
- Each item: cover(42dp, borderRadius 8dp), title(15sp), author(11sp), subscribe btn(44dp circle)

### EpisodePreviewSheet
**File:** `lib/widgets/episode_preview_sheet.dart`
- 居中弹窗，预览播客节目列表，代替 `showModalBottomSheet` 以适配圆形屏幕
- **入口:** `EpisodePreviewSheet.show(context, item, episodes, onSubscribe)`
- **Props:**
  - `item` — `TopPodcastItem`（播客名称作为弹窗标题）
  - `episodes` — `List<Episode>`（节目列表，缩略图格式 ▸）
  - `onSubscribe` — 订阅回调 `(String feedUrl) => void`
- **实现细节:**
  - 使用 `PageRouteBuilder(opaque: false)` 保持底层页面可见
  - 圆形裁剪由全局 `MaterialApp.builder` 的 `ClipRRect` 统一提供，无需额外 clipper
  - 动画：`FadeTransition` + `ScaleTransition(easeOutBack)` — 弹性缩放弹入
  - 标题栏+订阅按钮固定在顶部，节目列表内部可滚动
  - 收起订阅按钮：半透明毛玻璃样式 (`alpha: 0.18` + 描边)
  - 动态高度计算：基于圆形方程 `y = centerY + sqrt(r² - (w/2)²)` 确保底部不被截断
  - 点击背景遮罩或订阅后自动关闭弹窗

### WatchSafeArea
- Circular clip using `ClipPath` with circle equation.
- Only wraps center content zone — top bar goes outside it.

### TagPickerPage
**File:** `lib/screens/tag_picker_page.dart`
- 全屏标签选择页面，在添加订阅流程中使用 (`TagPickerPage.show()`)
- **v1.9.0 迁移: AppBar → TopActionBar(compact: true)** — 去掉 AppBar，改用 Stack + `TopActionBar(compact: true)`（纯图标 ✕），final form 经迭代确认
- **v1.9.x 布局优化 (2026-05-25):**
  - 结构: `GlassBackground → SafeArea → Center → SizedBox(width:192) → Stack`
  - 内容层: `Positioned.fill → Padding(top:60) → SingleChildScrollView(padding bottom:80)`，确保最后一行标签在悬浮按钮上方
  - 标题: `ws.sp(14)` white w500，通过 `Padding(top:60)` 与 ✕ 按钮拉开距离
  - 标签网格: 2列，`tagWidth = (maxWidth - ws.s(3)*3) / 2` ≈ 92dp（靠近但不贴边），`spacing: ws.s(8)` 列间距，`runSpacing: ws.s(5)` 行间距，`vertical padding: ws.s(7)` 气泡高度
  - 确认按钮: `Positioned(bottom:8)` 固定悬浮，`BackdropFilter blur 6` + alpha 0.35 紫色（有选择）/ alpha 0.1 白色（无选择），半透明毛玻璃可透出下方标签暗示可滚动
- 数据源：`PodcastSubscription.presetTags` (10 tags: 科技/商业/文化/社会/故事/新闻/教育/生活/音乐/搞笑)
- 推荐标签行：`Wrap` + 小胶囊(9sp) + 紫色提示

### Cache Behavior
- TopPodcastService: 24h memory + file cache. `invalidateCache()` for manual refresh.
- EpisodesScreen: cache-first (show immediately) → silent background RSS refresh.
