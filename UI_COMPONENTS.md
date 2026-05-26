# WatchPod UI Components Reference

> For AI consumption. All sizes use WearScale for adaptive scaling (base=280).
> Architecture/code layout details are in ARCHITECTURE.md. Cross-refs in AGENTS.md.
> This file: design tokens + component API only.

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
| arc-label | 10 | w500 | TagTrack floating label bubble (v1.8.4: 轻量化) |

### Virtual Tokens

| Token | Behavior |
|-------|----------|
| `ws.sp(X)` | Font size, scales from 280dp base |
| `ws.s(X)` | Spacing, padding, scales linearly |
| `ws.capped(X, maxScale: 1.2)` | Scales but caps at 1.2x (for covers) |
| `ws.fs(X)` | Font size with floor (prevent oversized) |

## Layout Architecture Overview

| Screen | Pattern | Content |
|--------|---------|---------|
| **HomeScreen** | Stack + right arc track overlay | Full-width content (centered) + TagTrack overlay |
| **SettingsScreen** | Stack + TopActionBar overlay + SafeArea | No AppBar. Buttons float in TopActionBar. |
| **EpisodesScreen** | Stack + TopActionBar overlay | Single centered button (arrow_back / close). |
| **PlayerScreen** | Stack + TopActionBar overlay + SafeArea | Single centered back button. Center content in SafeArea. |
| **TagPickerPage** | Stack + TopActionBar(compact: true) overlay | Pure icon ✕ circle button. 2-col tag grid. Frosted glass confirm btn. |

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

## Component APIs

### PodcastTile
- Params: title, author, imageUrl, tags, onTap, coverSize
- Cover: `ws.capped(96, maxScale: 1.2)` on HomeScreen (single podcast)
- Tags: purple glass pills, max 3 shown

### EpisodeTile (v1.9.2+)
- Params: title, duration, imageUrl, isDownloaded, isPlaying, isSelected, onTap, onLongPress
- Cover `ws.capped(36, maxScale: 1.1)`. Row layout with 3 zones.
- **Round-screen safety margins:**
  - Horizontal margin: `ws.s(20)` ≈ 33px (prevents right-side clipping on circular bezel)
  - Play button: icon `ws.s(18)` + padding `ws.s(4)` — compact to fit near right edge
  - Title font: `ws.sp(13)`, duration: `ws.sp(11)`
- **Bottom padding:** `ws.s(64)` for EpisodesScreen ListView — last item stays in circular safe zone

### HotPodcastList
- Props: items, loading, error, subscribeError, showTitle, onItemTap, onSubscribe
- `showTitle: true` → 标题作为 ListView 首个元素，居中显示，**随列表滚动**
- `subscribeError` → 红色渐变提示条，显示在列表上方（瞬态，不参与滚动）
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
  - `PageRouteBuilder(opaque: false)` 保持底层页面可见
  - 圆形裁剪由全局 `MaterialApp.builder` 的 `ClipRRect` 统一提供
  - 动画：`FadeTransition` + `ScaleTransition(easeOutBack)` — 弹性缩放弹入
  - 收起订阅按钮：半透明毛玻璃 (`alpha: 0.18` + 描边)
  - 动态高度：基于圆方程 `y = centerY + sqrt(r² - (w/2)²)` 确保底部不被截断

### WatchSafeArea
- Adaptive `Padding` based on circular geometry: `safePadding + radius * 0.06`
- **Does NOT clip** — circular screen clip handled globally by `MaterialApp.builder`.
- Used in: HomeScreen (central podcast section) — wraps scrollable content inside WatchSafeArea for circular-safe padding
- Only wraps center content zone — top bar goes outside it.

### TagPickerPage
**File:** `lib/screens/tag_picker_page.dart`
- 全屏标签选择页面 (`TagPickerPage.show()`)
- **布局结构:** `GlassBackground → SafeArea → Center → SizedBox(width:192) → Stack`
- **标题:** `ws.sp(14)` white w500, `Padding(top:60)` 与 ✕ 按钮错开
- **标签网格:** 2列, `tagWidth = (maxWidth - ws.s(3)*3) / 2` ≈ 92dp, `spacing: ws.s(8)`, `runSpacing: ws.s(5)`
- **确认按钮:** `Positioned(bottom:8)` 固定悬浮, `BackdropFilter blur 6` + alpha 0.35/0.1 (purple/white)
- **ScrollView padding bottom:** `ws.s(80)` — 确保最后一行标签在按钮上方
- **数据源:** `PodcastSubscription.presetTags` (10 preset tags)

### PlayerScreen — 底部控制按钮弧形排列

三个控制按钮（-15 / play / +15）沿底部弧形排列，适应圆形屏幕：

| Button | Size | Style | Position |
|--------|------|-------|----------|
| -15/+15 | 36×36dp, 10sp text, radius 18dp | Glass (white 0.08) | 上移 8dp (弧线两侧) |
| Play/Pause | 52×52dp, 26sp icon, radius 26dp | Primary #6C63FF alpha 0.6 | 居中 (弧线底部) |
| Button gap | 6dp | — | 紧凑居中 |
| Bottom safe | 16dp padding | — | 整体安全距离 |

**方案演进（避免重复踩坑）:**

| # | 方案 | 结果 | 根因 |
|---|------|------|------|
| 1 | `LayoutBuilder` + 圆方程 | ❌ 按钮渲染到屏幕外 | `constraints.maxWidth` = Column 可用宽度 ≠ 全屏宽度 |
| 2 | `Stack` + `Positioned(left:14 / right:14)` | ❌ 被圆边界裁切 | 233dp 屏幕太窄，偏移量超出圆形范围 |
| 3 | `Row` + 间距调整, bottom padding=8 | ❌ 继续被裁切 | 底部安全距离不足 |
| 4 | **`Row` 紧凑居中 + 两侧上移 8dp + bottom 16dp** | ✅ **100% 可见** | 6dp 间距紧贴中线区域，偏移 8dp 不超出圆形 |

**核心原则:** 底部控制栏绝对不要在 `Column`/`Padding` 内的 `LayoutBuilder` 做全屏坐标计算。优先 `Row(mainAxisAlignment: MainAxisAlignment.center)` + 相对 `Padding` 偏移。

## Cache Behavior
- TopPodcastService: 24h memory + file cache. `invalidateCache()` for manual refresh.
- EpisodesScreen: cache-first (show immediately) → silent background RSS refresh.
