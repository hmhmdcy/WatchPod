# WatchPod UI Components

> For AI consumption. v1.1 design system. Components in `lib/widgets/`.

## Design Tokens

| Token | Value |
|-------|-------|
| Primary | `#6C63FF` |
| Secondary | `#7C4DFF` |
| Background gradient | `topLeft→bottomRight: #1A1A2E → #16213E → #0F3460` |
| Glass tint | White @ 4-12% opacity |
| Glass blur | sigmaX=sigmaY=12 |
| Text primary | `#FFFFFF` |
| Text secondary | `#FFFFFFB3` |
| Slider track (active) | `#6C63FF` |
| Slider track (inactive) | `white 24%` |
| Slider thumb | `#6C63FF`, radius 7 |
| Touch target min | 36dp (play/pause = 60dp encouraged) |

## Component API — Quick Reference

### GlassContainer
```dart
GlassContainer({
  blur: 12, tintColor: 0x1AFFFFFF, borderRadius: 16,
  borderOpacity: 0.08, padding: 12, // null → no border
  width, height, margin, onTap,
  child,
})
// On-screen usage: GestureDetector wrapping, or use onTap param.
```

### GlassBackground
```dart
Scaffold(extendBodyBehindAppBar: true, body: GlassBackground(child: ...))
// Always wraps content + WatchSafeArea.
```

### GlassImage
```dart
GlassImage({imageUrl, size: 56, borderRadius: 16})
// Default icon Icons.podcasts if imageUrl null.
```

### PodcastTile
```dart
PodcastTile({
  title, author?, imageUrl?, tags: const [],
  required onTap,
})
// Layout: GlassImage(72×72) → GlassContainer(title) → author → tag chips (max 3)
```

### EpisodeTile
```dart
EpisodeTile({
  title, duration?, imageUrl?, // 🆕 v1.1 per-episode cover
  isDownloaded: false, isPlaying: false,
  required onTap,
})
// Layout: GlassImage(36×36) + title + [duration] + [download checkmark] | play icon
```

## Screen Template (copy-paste for new screens)

```dart
Scaffold(
  extendBodyBehindAppBar: true,
  appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
  body: GlassBackground(
    child: WatchSafeArea(
      child: /* content */,
    ),
  ),
)
```

## GlassSlider Template

```dart
SliderTheme(
  data: SliderTheme.of(context).copyWith(
    activeTrackColor: Color(0xFF6C63FF),
    inactiveTrackColor: Colors.white24,
    thumbColor: Color(0xFF6C63FF),
    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
    overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
    trackHeight: 3,
  ),
  child: Slider(value: v, onChanged: (v) => seek(dur * v)),
)
```

## New Component Rules

1. snake_case filename = component name
2. No barrel exports — import directly
3. No hardcoded color values — use design tokens above
4. Interactive elements: min 36dp touch radius
5. Complex widgets need dartdoc
6. Prefer GlassContainer wrapping over reimplementing BackdropFilter
