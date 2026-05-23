import 'package:flutter/material.dart';
import '../models/podcast_subscription.dart';
import '../widgets/podcast_tile.dart';
import '../widgets/glass_components.dart';
import '../widgets/watch_safe_area.dart';
import 'episodes_screen.dart';
import 'settings_screen.dart';
import 'player_screen.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../services/rss_service.dart';

class HomeScreen extends StatefulWidget {
  final AudioService audioService;
  final StorageService storageService;
  final RssService rssService;

  const HomeScreen({
    super.key,
    required this.audioService,
    required this.storageService,
    required this.rssService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PodcastSubscription> _subscriptions = [];
  int _currentPage = 0;
  bool _loading = true;

  // 分类筛选
  String? _activeTag; // null = 全部

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    final subs = await widget.storageService.loadSubscriptions();
    setState(() {
      _subscriptions = subs;
      _loading = false;
    });
  }

  /// 获取所有可用标签（去重）
  List<String> get _allTags {
    final tags = <String>{};
    for (final sub in _subscriptions) {
      tags.addAll(sub.tags);
    }
    return tags.toList()..sort();
  }

  /// 按标签筛选后的订阅列表
  List<PodcastSubscription> get _filteredSubscriptions {
    if (_activeTag == null) return _subscriptions;
    return _subscriptions.where((s) => s.tags.contains(_activeTag)).toList();
  }

  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(storageService: widget.storageService),
      ),
    );
    _loadSubscriptions();
  }

  void _openEpisodes(PodcastSubscription sub) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EpisodesScreen(
          podcast: sub,
          audioService: widget.audioService,
          storageService: widget.storageService,
          rssService: widget.rssService,
        ),
      ),
    );
  }

  void _openPlayer() {
    if (widget.audioService.currentEpisode != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(audioService: widget.audioService),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        child: WatchSafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : _subscriptions.isEmpty
                  ? _buildEmptyState()
                  : _buildContent(),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.audioService.currentEpisode != null)
            GestureDetector(
              onTap: _openPlayer,
              child: GlassContainer(
                blur: 8,
                tintColor: const Color(0xFF6C63FF).withValues(alpha: 0.6),
                borderRadius: 20,
                padding: const EdgeInsets.all(8),
                child: Icon(
                  widget.audioService.isPlaying
                      ? Icons.play_arrow
                      : Icons.pause,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _openSettings,
            child: GlassContainer(
              blur: 8,
              tintColor: Colors.white.withValues(alpha: 0.1),
              borderRadius: 20,
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassContainer(
            blur: 6,
            tintColor: Colors.white.withValues(alpha: 0.05),
            borderRadius: 32,
            padding: const EdgeInsets.all(16),
            child: const Icon(Icons.podcasts, size: 40, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text('还没有订阅播客',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 4),
          Text('点击右下角 + 添加 RSS 订阅',
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final tags = _allTags;
    final filtered = _filteredSubscriptions;

    return Column(
      children: [
        // 标签筛选栏
        if (tags.isNotEmpty) _buildTagFilter(tags),
        // 播客列表
        Expanded(child: _buildSubscriptionsContent(filtered)),
      ],
    );
  }

  Widget _buildTagFilter(List<String> tags) {
    return Container(
      height: 32,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // "全部" 标签
          GestureDetector(
            onTap: () => setState(() => _activeTag = null),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _activeTag == null
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                '全部',
                style: TextStyle(
                  fontSize: 11,
                  color: _activeTag == null ? Colors.white : Colors.white70,
                  fontWeight:
                      _activeTag == null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          // 各标签
          ...tags.map((tag) => GestureDetector(
                onTap: () => setState(() => _activeTag = tag),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _activeTag == tag
                        ? const Color(0xFF6C63FF).withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          _activeTag == tag ? Colors.white : Colors.white70,
                      fontWeight: _activeTag == tag
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsContent(List<PodcastSubscription> subs) {
    if (subs.isEmpty) {
      return Center(
        child: Text(
          _activeTag != null ? '该分类暂无播客' : '还没有订阅播客',
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
      );
    }

    final itemsPerPage = subs.length;

    if (itemsPerPage <= 1) {
      return Center(
        child: PodcastTile(
          title: subs[0].title,
          author: subs[0].author,
          imageUrl: subs[0].imageUrl,
          tags: subs[0].tags,
          onTap: () => _openEpisodes(subs[0]),
        ),
      );
    }

    return PageView.builder(
      itemCount: itemsPerPage,
      onPageChanged: (i) => setState(() => _currentPage = i),
      itemBuilder: (context, index) {
        final sub = subs[index];
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PodcastTile(
              title: sub.title,
              author: sub.author,
              imageUrl: sub.imageUrl,
              tags: sub.tags,
              onTap: () => _openEpisodes(sub),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(itemsPerPage, (i) {
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _currentPage
                        ? const Color(0xFF6C63FF)
                        : Colors.grey[600],
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
