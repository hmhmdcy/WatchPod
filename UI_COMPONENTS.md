# WatchPod UI Components Reference

> For AI consumption. All sizes use WearScale for adaptive scaling.

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

### Typography

| Role | Base Size | Weight | Usage |
|------|-----------|--------|-------|
| tag-text | 11 | bold/normal | Tag filter bar (compact 30dp row) |
| card-title | 13 | bold | Episode titles, podcast names |
| body | 12 | normal | Episode titles |
| subtitle | 11 | normal | Author names |
| caption | 9-10 | normal | Timestamps, hints |

## Virtual Tokens

| Token | Behavior |
|-------|----------|
| `ws.sp(X)` | Font size, scales linearly from 360dp base |
| `ws.s(X)` | Spacing, padding, scales linearly |
| `ws.capped(X, maxScale: 1.2)` | Scales but caps at 1.2x (for covers) |
| `ws.fs(X)` | Font size with floor (prevent oversized) |

## Layout Architecture: Top-Bar + Full Content

Since v1.4.0, ALL screens use a single-row top bar + full-height content below.

### What this replaces

- v1.0-v1.2: Bottom action bar pattern
- v1.3: Three-zone balanced layout (top bar / center content / bottom action bar)
- v1.4+: Top-bar + full content (bottom info bars removed — they waste vertical space on round watches)

### Why

Round smartwatch screens (360-466dp diameter) have limited usable vertical space. Dedicated bottom action bars consume 44-60dp. The top-bar pattern reclaims that for content.

## HomeScreen Layout

```
┌──────────────────────┐
│                       │
│                       │ ╲ ← TagTrack arc track
│        ┌──────────┐  ╱   (3dp, alpha 0.45)
│        │  iPod 封面 │  ╲  紧贴圆形右边缘
│        └──────────┘  ╱
│        标题 / 作者   ╲
│      ●    ●    ●    ╱
│                       │
└──────────────────────┘
```

### HomeScreen Content (Expanded, full width)
- Empty state: center-aligned icon + "还没有订阅播客" + "添加一个订阅开始收听"
- Has subscriptions: `_buildPodcastSection(ws)` inside WatchSafeArea
  - 1 item: center-aligned PodcastTile, coverSize `ws.capped(96, maxScale: 1.2)`
  - Multiple: PageView.builder, each page = PodcastTile + page indicator dots
  - Tap cover → `_openEpisodes(sub)` → EpisodesScreen (push)

### TagTrack — Right Edge Arc Track
- Located in a 24dp-wide SizedBox on the right of the HomeScreen Row
- Visual: 3dp white arc (alpha 0.45), inset ~3dp from right edge, runs ~85% of height
- Touch zone: 40dp wide GestureDetector, activates when dx < 20dp from arc center
- On drag: white slider dot + purple label bubble (shows current tag name)
- Tags: ["全部"(null), ...widget.tags] — mapped from full vertical range
- Bottom 15% hover for 2s → purple "添加订阅" bubble → triggers `onAddSubscription`
- Uses `_TagTrackPainter` CustomPainter for the arc line + slider dot

## SettingsScreen Layout

```
┌──────────────────────────────────┐
│  [+ 添加订阅]  🔄               │  ← 紧凑操作栏: 40dp h, SizedBox wrap
├──────────────────────────────────┤
│ 🔥 苹果热门播客                   │
│ ┌────┬───────────┬──┐           │
│ │36dp│ title     │+ │           │  ← 列表占满剩余空间
│ │cvr │ author    │40│           │
│ └────┴───────────┴──┘           │
│ ...more items                   │
│                                  │
└──────────────────────────────────┘
```

### SettingsScreen TopBar (40dp)
- Uses `SettingsAddBar(compact: true)` — button height 30dp, icon 14sp, text 11sp
- Two buttons: "添加订阅" (left) + 🔄 refresh (right)
- No AppBar, no back arrow. PopScope swipe-back on Scaffold.body.

### SettingsScreen Content (Expanded)
- `HotPodcastList` with `showTitle: true`
- Each item row: cover(36dp) + name(14sp) + author(11sp) + subscribe button(40dp circle)

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

Compact mode (used in top-bars): height 30dp, icon 14sp, text 11sp, icon+text gap 4dp.
Default mode: height ~36dp, icon 16sp, text 12sp.

## Key Components

### PodcastTile
- Params: title, author, imageUrl, tags, onTap, coverSize
- Cover: `ws.capped(96, maxScale: 1.2)` on HomeScreen

### EpisodeTile
- Params: title, duration, imageUrl, isDownloaded, isPlaying, isSelected, onTap, onLongPress
- Cover 32dp (capped). Row layout.

### SettingsAddBar
- Two modes: compact (top-bar) and default
- Compact: height 30dp, small icons/text
- Default: height 46dp, larger icons/text

### HotPodcastList
- Props: items, loading, error, subscribeError, showTitle, onItemTap, onSubscribe
- Each item: cover(36dp, borderRadius 8dp), title(14sp), author(11sp), subscribe btn(40dp circle)

### WatchSafeArea
- Circular clip. Only wraps center content zone — top bar goes outside it.

### Cache Behavior
- TopPodcastService: 24h memory + file cache. `invalidateCache()` for manual refresh.
- EpisodesScreen: cache-first (show immediately) → silent background RSS refresh.
