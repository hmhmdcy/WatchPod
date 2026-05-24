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
| arc-label | 12 | bold | TagTrack floating label bubble |

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
| **All others** | AppBar centered buttons + full content | Scaffold(extendBodyBehindAppBar) + WatchSafeArea(body) |

## HomeScreen Layout (v1.8.1+)

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

### Architecture Detail

```dart
Stack(
  children: [
    Positioned.fill(
      child: WatchSafeArea(
        child: _buildPodcastSection(ws),  // centered content
      ),
    ),
    Positioned.fill(
      child: _buildTopBar(ws),  // → TagTrack overlay
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

### Architecture

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
       └─ Positioned.fill (label overlays when dragging)
```

### Key Design Decisions

| Decision | Why |
|----------|-----|
| `OverflowBox` instead of `Positioned.fill(left:-N)` | `OverflowBox` gives true full-screen canvas at correct world-space coordinates. `Positioned.fill(left:-N)` introduced coordinate translation bugs because the offset depends on parent container width, which differs between Web and real device. |
| `arcRadius = r` (no inset) | User explicitly wanted arc "紧贴圆边" (tight against the circular bezel) |
| -45° to 45° | Arc covers ~1/4 circle (right side, about half screen height). User said previous full right semicircle was "太长了" |
| `MaskFilter.blur(BlurStyle.normal, 10)` | Creates frosted glass glow under the semi-transparent white stroke. First layer: 14dp blur + 0.15 opacity. Top layer: 10dp + 0.69 opacity. |
| `GestureDetector` in SizedBox(40dp) | Touch zone restricted to right edge so swiping left side won't trigger tag changes |

### Interaction Model

- **Idle state:** Arc visible on right edge (frosted glass, 10dp)
- **Touch near arc** (within 30dp of nearest point): Activates drag — white slider dot (6dp radius) + purple floating label bubble
- **Drag:** Labels change as slider passes through each tag zone: "全部" → [tag1] → [tag2] → ...
- **Bottom 85%+:** 2s hold → purple glow + "添加订阅" bubble → auto-navigate to SettingsScreen
- **Lift:** Commits selected tag as active filter

## SettingsScreen Layout (v1.8.1+)

```dart
Scaffold(
  extendBodyBehindAppBar: true,
  appBar: AppBar(
    backgroundColor: const Color(0xFF0F0F23).withValues(alpha: 0.85),
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    centerTitle: true,
    automaticallyImplyLeading: false,
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _backButton(),    // ← glass pill 36dp
        SizedBox(width: ws.s(6)),
        _refreshButton(), // 🔄 glass pill 36dp
        SizedBox(width: ws.s(6)),
        _addButton(),     // + glass pill 36dp
      ],
    ),
  ),
  body: GlassBackground(
    child: Column(
      children: [
        Expanded(child: WatchSafeArea(child: HotPodcastList(...))),
      ],
    ),
  ),
);
```

## EpisodesScreen Layout (v1.8.1+)

```
Scaffold(
  extendBodyBehindAppBar: true,
  appBar: AppBar(
    backgroundColor: const Color(0xFF0F0F23).withValues(alpha: 0.85),
    scrolledUnderElevation: 0,
    centerTitle: true,
    automaticallyImplyLeading: false,
    title: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        height: ws.s(36),
        padding: EdgeInsets.symmetric(horizontal: ws.s(12)),
        decoration: BoxDecoration(...),  // glass pill
        child: Row(
          children: [
            Icon(Icons.arrow_back, size: ws.s(16)),
            SizedBox(width: ws.s(6)),
            Text('返回'),
          ],
        ),
      ),
    ),
  ),
  body: GlassBackground(
    child: Column(
      children: [
        Expanded(child: WatchSafeArea(child: episodeList)),
        if (multiSelect) _bottomActionBar,
      ],
    ),
  ),
);
```

## PlayerScreen Layout (v1.8.1+)

Same AppBar pattern as EpisodesScreen. Content column with `mainAxisAlignment: MainAxisAlignment.center`:

- Cover: `ws.capped(68, maxScale: 1.2)` with glass rounded corners
- Title: 2-line max, `ws.fs(12)` font
- Progress: `SliderTheme` with track height 3dp, width constrained to `min(ws.s(160), screenWidth*0.70)`
- Time row: `ws.sp(10)` font, 8dp gap
- Control row: -15s | play/pause | +15s — each button 10dp padded

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

### EpisodeTile
- Params: title, duration, imageUrl, isDownloaded, isPlaying, isSelected, onTap, onLongPress
- Cover 32dp (capped). Row layout.

### HotPodcastList
- Props: items, loading, error, subscribeError, showTitle, onItemTap, onSubscribe
- Each item: cover(42dp, borderRadius 8dp), title(15sp), author(11sp), subscribe btn(44dp circle)

### WatchSafeArea
- Circular clip using `ClipPath` with circle equation.
- Only wraps center content zone — top bar goes outside it.

### Cache Behavior
- TopPodcastService: 24h memory + file cache. `invalidateCache()` for manual refresh.
- EpisodesScreen: cache-first (show immediately) → silent background RSS refresh.
