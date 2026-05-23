# WatchPod Architecture Reference

> For AI consumption. Last updated: 2026-05-24.
> Primary context file: AGENTS.md (load first). Compliments: UI_COMPONENTS.md, docs/BUILD.md.

## Data Flow — Complete Call Chains

### Subscription Add

```
SettingsScreen._addFeed(url)
  → RssService.parseFeed(url)  [Dio GET → XmlDocument.parse]
    → returns (PodcastSubscription, List<Episode>)
  → [Tag picker dialog: auto-suggest + manual select]
  → StorageService.addSubscription(podcast)  [append to JSON, write all]
  → StorageService.saveEpisodes(podcastId, episodes)
  → Navigator.pop() → HomeScreen._loadSubscriptions()
```

### Episode Play

```
EpisodeTile.onTap → EpisodesScreen._playEpisode(ep)
  → AudioService.play(ep)
    ├─ source = isDownloaded ? AudioSource.file(localPath) : AudioSource.uri(audioUrl)
    ├─ if playbackPosition > 5s: setAudioSource(..., initialPosition: playbackPosition)
    └─ _player.play()
  → Navigator.push(PlayerScreen)
```

### Episode Refresh (Cache-First)

```
EpisodesScreen.initState → _loadEpisodes()
  ├─ Load cached: StorageService.loadEpisodes(podcastId) → setState (instant)
  ├─ Network refresh: RssService.parseFeed(feedUrl) → setState (async)
  │   └─ On error: keep showing cached data (no error, unless cache empty)
  └─ StorageService.saveEpisodes(podcastId, episodes)
```

### Download

```
Dismissible onDismissed → EpisodesScreen._downloadEpisode(ep)
  ├─ Guard: audioUrl != null && !isDownloaded
  ├─ Dio.download(audioUrl, "${downloadDir}/${ep.id}.${ext}")
  ├─ episode.copyWith(isDownloaded: true, localPath: path)
  └─ StorageService.updateEpisode(updated)
```

## Storage Performance Constraints

- `episodes.json` is flat array, O(n) append: read all → filter → add → write all.
- **Migrate at ~5000 episodes or ~10MB**: Hive (~200KB overhead) → Isar (~2MB, relational).
- **No schema migration**: `fromJson` returns `[]` on any parse failure. Field additions silently drop old data.

## Key Pitfalls for AI

1. **EpisodeTile.imageUrl chain**: `imageUrl` comes from RSS `<itunes:image href="...">` on each `<item>`. Many feeds don't provide per-episode images. Fallback (in EpisodesScreen): `ep.imageUrl ?? latestImageUrl` where `latestImageUrl` is the first non-null imageUrl from the loaded episode list. PodcastTile always uses `podcast.imageUrl`.

2. **Tag suggestion logic** is in `PodcastSubscription.suggestTags(title, description)`. Keyword-based (lowercased regex). Run this on subscription addition before showing the tag picker dialog.

3. **Slider + seek**: `PlayerScreen` uses raw `Slider` inside `ListenableBuilder`. The Slider's `onChanged` callback calls `audioService.seek(dur * v)`. Note: `dur` is `audioService.duration ?? Duration(seconds:1)`. During buffering, `duration` may be `Duration.zero` → divide by zero risk mitigated by `max(dur.inMilliseconds, 1)`.

4. **SettingsScreen RssService instance**: `_addFeed()` creates `final rssService = RssService()` locally, bypassing the injected singleton. Harmless but inconsistent pattern.

5. **GlassBackground requires `extendBodyBehindAppBar: true`** on every Scaffold. Forgetting this will cause app bar to have a solid black background instead of glass effect.

6. **Curious fact**: `cached_network_image` package is declared in pubspec.yaml but not actually imported anywhere (images use bare `Image.network`). This is dead weight — can be removed with no impact.

## Navigation Graph (Current)

```
                              ┌──────────────┐
                              │  HomeScreen  │
                              │  (PageView)  │
                              └──────┬───────┘
                     ┌───────────────┼───────────────┐
                     ▼               ▼               ▼
              ┌──────────┐   ┌──────────────┐   ┌────────────┐
              │ Settings │   │  Episodes    │   │  Player    │
              │  Screen  │   │   Screen     │   │  Screen    │
              └──────────┘   └──────┬───────┘   └────────────┘
                                    │ (tap episode)
                                    ▼
                              ┌────────────┐
                              │  Player    │
                              │  Screen    │
                              └────────────┘
```

## Stateful vs Stateless

| Widget | Type | Notes |
|--------|------|-------|
| HomeScreen | Stateful | setState for subscriptions + tag filter |
| EpisodesScreen | Stateful | setState for episode list + download state |
| PlayerScreen | **Stateless** | Uses ListenableBuilder — state lives in AudioService |
| SettingsScreen | Stateful | setState for form + loading |
| PodcastTile | Stateless | Pure render |
| EpisodeTile | Stateless | Pure render |
| GlassContainer | Stateless | Pure render |
| AudioService | ChangeNotifier | Position, duration, state streams |
