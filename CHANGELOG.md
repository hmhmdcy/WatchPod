# WatchPod Changelog

## v1.1.0 — 2026-05-24

### Added
- **Glassmorphism design system**: GlassContainer, GlassBackground, GlassImage (glass_components.dart)
- **Tag classification system**: PodcastSubscription.tags field, auto-suggest on add, tag filter bar on home
- **Seekable slider**: PlayerScreen progress bar → Slider widget (touch-draggable)
- **Per-episode cover image**: EpisodeTile.imageUrl, fallback to podcast.imageUrl
- **Modular documentation**: AGENTS.md / ARCHITECTURE.md / UI_COMPONENTS.md / CHANGELOG.md + docs/ dir

### Changed
- Theme primary color: `Colors.blue` → `#6C63FF`
- `withOpacity()` → `withValues(alpha:)` throughout (Flutter SDK compat)
- UI_COMPONENTS.md and docs/BUILD.md: condensed to AI-consumption format
- ARCHITECTURE.md: restructured with call chains, pitfalls, navigation graph
- AGENTS.md added: AI trigger conditions + cross-references

### Removed
- PROJECT.md (split into modular docs)
- `flutter_backdrop` dependency attempt (failed null safety)
- Unused `_pendingPodcast` / `_selectedTags` fields in settings_screen.dart

### Known
- `cached_network_image` in pubspec.yaml is dead weight (not imported anywhere)
- Pre-v1.1 subscriptions have no tags (tags set at subscription time only)

## v1.0.0 — 2026-05-24

### Added
- RSS subscription management (CRUD)
- RSS feed parsing (title, episodes, durations, images)
- Audio playback (play/pause/seek) via just_audio
- Episode download for offline
- Flat JSON persistence
- Cache-first loading
- Build pre-check script
- Wear OS round-screen safe area

### Fixed
- Release APK missing INTERNET permission (added to src/main/AndroidManifest.xml)
- 4/5 preset RSS URLs expired (replaced)
- Gradle OOM (Xmx8G → Xmx2G)
- Clash proxy killed by pkill (migrated to systemd user service)
