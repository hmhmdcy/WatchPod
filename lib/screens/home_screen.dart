import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../models/podcast_subscription.dart';
import '../widgets/podcast_tile.dart';
import '../widgets/glass_components.dart';
import '../widgets/watch_safe_area.dart';
import '../widgets/wear_scale.dart';
import '../widgets/home_tag_track.dart';
import 'episodes_screen.dart';
import 'settings_screen.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../services/rss_service.dart';

/// WatchPod 首页 — Stack 布局 + 右侧弧线标签导航条
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

  String? _activeTag;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    if (kIsWeb || !Platform.isAndroid) {
      // Web / Linux Desktop 调试：注入模拟播客数据
      // Web 调试：注入模拟播客数据
      _subscriptions = [
        PodcastSubscription(
          id: 'mock-1',
          title: '科技早知道',
          author: '硅谷徐老师',
          feedUrl: 'https://example.com/feed1.xml',
          imageUrl: 'https://picsum.photos/seed/pod1/200/200',
          tags: ['科技', '中文'],
        ),
        PodcastSubscription(
          id: 'mock-2',
          title: '忽左忽右',
          author: 'JustPod',
          feedUrl: 'https://example.com/feed2.xml',
          imageUrl: 'https://picsum.photos/seed/pod2/200/200',
          tags: ['文化', '中文'],
        ),
        PodcastSubscription(
          id: 'mock-3',
          title: '故事FM',
          author: '寇爱哲',
          feedUrl: 'https://example.com/feed3.xml',
          imageUrl: 'https://picsum.photos/seed/pod3/200/200',
          tags: ['故事', '中文'],
        ),
      ];
      setState(() => _loading = false);
      return;
    }
    final subs = await widget.storageService.loadSubscriptions();
    setState(() {
      _subscriptions = subs;
      _loading = false;
    });
  }

  List<String> get _allTags {
    final tags = <String>{};
    for (final sub in _subscriptions) {
      tags.addAll(sub.tags);
    }
    return tags.toList()..sort();
  }

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

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        child: Stack(
          children: [
            // 内容区域（SafeArea 保护不被圆边裁切）
            SafeArea(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _subscriptions.isEmpty
                      ? Stack(
                          children: [
                            Center(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: ws.s(42)),
                                child: _buildEmptyState(ws),
                              ),
                            ),
                            Positioned(
                              bottom: ws.s(16),
                              left: 0,
                              right: 0,
                              child: Center(
                                child: GestureDetector(
                                  onTap: _openSettings,
                                  child: Container(
                                    height: ws.s(42),
                                    padding: EdgeInsets.symmetric(horizontal: ws.s(24)),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(ws.s(21)),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add, color: Colors.white, size: ws.s(18)),
                                        SizedBox(width: ws.s(4)),
                                        Text('添加',
                                            style: TextStyle(
                                                fontSize: ws.sp(14),
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : SizedBox.expand(
                          child: WatchSafeArea(
                            child: _buildPodcastSection(ws),
                          ),
                        ),
            ),
            // 右侧弧线滑条（在 SafeArea 外部，触摸区域直达屏幕边缘）
            if (!_loading && _subscriptions.isNotEmpty)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: _buildTopBar(ws),
              ),
          ],
        ),
      ),
    );
  }

  /// 右侧贴合弧边的毛玻璃滑条（标签切换 + 添加订阅）
  Widget _buildTopBar(WearScale ws) {
    final tags = _allTags;

    return TagTrack(
      tags: tags,
      activeTag: _activeTag,
      onTagChanged: (tag) {
        setState(() => _activeTag = tag);
      },
      onAddSubscription: _openSettings,
    );
  }

  /// 封面区（居中盖茨比大封面）
  Widget _buildPodcastSection(WearScale ws) {
    final filtered = _filteredSubscriptions;

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _activeTag != null ? '该分类暂无播客' : '还没有订阅播客',
          style: TextStyle(fontSize: ws.sp(13), color: Colors.grey[400]),
        ),
      );
    }

    final count = filtered.length;

    if (count <= 1) {
      return Center(
        child: PodcastTile(
          title: filtered[0].title,
          author: filtered[0].author,
          imageUrl: filtered[0].imageUrl,
          tags: filtered[0].tags,
          coverSize: ws.capped(96, maxScale: 1.2),
          onTap: () => _openEpisodes(filtered[0]),
        ),
      );
    }

    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: count,
      onPageChanged: (i) => setState(() => _currentPage = i),
      itemBuilder: (context, index) {
        final sub = filtered[index];
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PodcastTile(
              title: sub.title,
              author: sub.author,
              imageUrl: sub.imageUrl,
              tags: sub.tags,
              coverSize: ws.capped(96, maxScale: 1.2),
              onTap: () => _openEpisodes(sub),
            ),
            SizedBox(height: ws.s(8)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(count, (i) {
                return Container(
                  width: ws.s(6),
                  height: ws.s(6),
                  margin: EdgeInsets.symmetric(horizontal: ws.s(3)),
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

  Widget _buildEmptyState(WearScale ws) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(ws.s(16)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(ws.s(32)),
            ),
            child: Icon(Icons.podcasts, size: ws.s(40), color: Colors.grey),
          ),
          SizedBox(height: ws.s(16)),
          Text('还没有订阅播客',
              style: TextStyle(fontSize: ws.fs(14), color: Colors.grey)),
          SizedBox(height: ws.s(4)),
          Text('添加一个订阅开始收听',
              style: TextStyle(fontSize: ws.sp(11), color: Colors.grey[600])),
        ],
      ),
    );
  }
}
