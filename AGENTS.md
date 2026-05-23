# WatchPod — Agent Context

> DEVICE: Wear OS smartwatch (round, ~360×360)
> SDK: Flutter 3.44 / Dart 3.12 / Android SDK 35+36
> PACKAGE: com.watchpod.watchpod
> TARGET: release APK for ARM64 (primary), ARMv7, x86_64

## TRIGGER CONDITIONS

WHEN task involves:
- **UI layout / component** → read UI_COMPONENTS.md
- **build / CI / APK** → read docs/BUILD.md
- **error / crash / network** → read docs/TROUBLESHOOTING.md
- **new feature / large refactor** → read docs/ROADMAP.md + ARCHITECTURE.md
- **version tracking** → read CHANGELOG.md, update it after changes

## ARCHITECTURE

### Layer: Screen → Service → Model (3-layer, no state library)

lib/
├── main.dart                          # Entry: init 3 services, run WatchPodApp
├── models/
│   ├── episode.dart                   # Episode data + JSON roundtrip
│   └── podcast_subscription.dart      # PodcastSubscription + tags + tag suggestion
├── screens/
│   ├── home_screen.dart               # Home: PageView grid + tag filter bar
│   ├── episodes_screen.dart           # Episode list: network-refresh, download, play
│   ├── player_screen.dart             # Player: seekable Slider + play/pause + skip
│   └── settings_screen.dart           # Settings: RSS add (URL + presets) + tag picker
├── services/
│   ├── audio_service.dart             # AudioService (ChangeNotifier): just_audio wrapper
│   ├── rss_service.dart               # RssService: Dio GET → XML parse → models
│   └── storage_service.dart           # StorageService: flat JSON file persistence
└── widgets/
    ├── glass_components.dart          # GlassContainer, GlassBackground, GlassImage
    ├── episode_tile.dart              # Episode list row (with cover image)
    ├── podcast_tile.dart              # Podcast card (with tag chips)
    └── watch_safe_area.dart           # Round-screen clip + safe padding

### Dependency Injection: Constructor-passed singletons (no DI framework)

3 services created in main.dart → passed through widget constructors (4 screens share them).
SettingsScreen._addFeed() creates a RssService() locally — bypasses singleton, acceptable for MVP.

### State Management

Screen           | Mechanism        | Why
-----------------|------------------|----
HomeScreen       | setState         | Simple list + loading
EpisodesScreen   | setState         | Local list + download flags
PlayerScreen     | ListenableBuilder | Reacts to AudioService (ChangeNotifier)
SettingsScreen   | setState         | Form input + loading

AudioService (ChangeNotifier): broadcasts position (sub-second), duration, state (playing/paused/buffering/stopped).

### Navigation: Raw Navigator (no go_router)

```
/ → HomeScreen (all services)
HomeScreen → SettingsScreen / EpisodesScreen / PlayerScreen
EpisodesScreen → PlayerScreen
```

Known issues — no deep linking, manual DI plumbing, no named routes.

## DATA MODELS

### Episode

```dart
// fromJson/toJson roundtrip exists
id: String              // RSS guid, fallback: title.hashCode
podcastId: String       // feedUrl.hashCode.toString()
title: String
description: String?
audioUrl: String?       // enclosure.url or media:content.url
imageUrl: String?       // itunes:image (per-episode cover, RSS item-level)
duration: Duration?     // parsed from itunes:duration (HH:MM:SS / MM:SS / raw seconds)
publishedAt: DateTime?  // pubDate
isDownloaded: bool      // default false
localPath: String?      // absolute path to downloaded file
playbackPosition: Duration?  // resume point
formattedDuration: String?  // computed: "1h 23m" / "45m"
```

### PodcastSubscription

```dart
id: String              // feedUrl.hashCode.toString()
title: String           // channel > title
author: String?         // itunes:author or author
description: String?    // channel > description
imageUrl: String?       // channel > image > url or itunes:image href
feedUrl: String         // canonical identity (used for dedup)
tags: List<String>      // added in v1.1. Preset: 科技,商业,文化,社会,故事,新闻,教育,生活,音乐,搞笑
```

### Storage: Flat JSON files

File               | Size cap   | Performance warning
-------------------|------------|-------------------
subscriptions.json | <50KB      | O(n) fine at this scale
episodes.json      | 5-20MB     | ⚠️ Full read/write every op. Migrate when >5000 episodes.

StorageService silently returns [] on any parse failure (no migration support — field additions break old JSON).

## KEY CROSS-REFERENCES

- **PlayerScreen + AudioService**: PlayerScreen_ uses `ListenableBuilder(audioService)` for reactive UI. positionStream updates ~4x/sec. seek() is unbuffered — slider drag triggers multiple seeks.
- **RssService parseFeed()**: Called from SettingsScreen (add subscription) and EpisodesScreen (refresh list). EpisodesScreen does cache-first: show local, then network-refresh.
- **EpisodeTile.imageUrl**: Falls back to podcast imageUrl if episode-level imageUrl is null.
- **Tag system**: Tags are set once on subscription addition (auto-suggest + manual picker). No post-hoc tag editing UI yet.
- **WatchSafeArea**: Must wrap every screen body. Round screen clip + safe padding.
- **GlassBackground + Scaffold**: Requires `extendBodyBehindAppBar: true` on Scaffold.

## DEPLOYMENT LOG

Every environment change must be recorded in ~/.hermes/deployment-log/YYYY-MM-DD-<desc>.md with:
- What was installed/changed + exact commands
- WHY (root cause / context)
- Rollback steps

This is critical: the build environment is proxy-dependent (Clash @ :7890) on 4GB RAM WSL. OOM kills Gateway → kills Clash → all downstream errors are red herrings.
