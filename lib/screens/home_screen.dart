import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/podcast_subscription.dart';
import '../widgets/podcast_tile.dart';
import '../widgets/glass_components.dart';
import '../widgets/watch_safe_area.dart';
import '../widgets/wear_scale.dart';
import '../widgets/home_tag_track.dart';
import 'episodes_screen.dart';
import 'settings_screen.dart';
import 'player_screen.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../services/rss_service.dart';

/// 弧形裁剪路径 — 左侧边缘为圆形弧线，贴合圆形表盘
/// 保留路径内部的区域（面板内容），左侧按弧线裁剪
class _ArcShape extends CustomClipper<Path> {
  const _ArcShape();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // 弧的最大凸出量（往右凸）— 面板宽度的 40%
    final bulge = w * 0.4;

    // 左上角 — 从 (bulge, 0) 开始（弧的起点）
    // 上端逐渐向右凸出，到中部最凸
    path.moveTo(0, 0);
    // 曲线到左下角 — 中部向右凸出
    path.quadraticBezierTo(bulge, h * 0.5, 0, h);

    // 底部、右侧、顶部
    path.lineTo(w, h);
    path.lineTo(w, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(_ArcShape old) => false;
}

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
    if (kIsWeb) {
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

  List<String> get _allTagItems => ['全部', ..._allTags];

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

  void _selectTag(int index) {
    setState(() {
      _activeTag == null ? _activeTag = _allTags[0] : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _subscriptions.isEmpty
                  ? Stack(
                      children: [
                        // 居中空状态（整体上移，给底部按钮让空间）
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: ws.s(42)),
                            child: _buildEmptyState(ws),
                          ),
                        ),
                        // 底部「添加」按钮
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
                  : Stack(
                      children: [
                        // 圆形裁剪覆盖全屏，确保内容居中
                        Positioned.fill(
                          child: WatchSafeArea(
                            child: _buildPodcastSection(ws),
                          ),
                        ),
                        // 右侧弧线滑条（紧贴圆边，无面板）
                        Positioned.fill(
                          child: _buildTopBar(ws),
                        ),
                      ],
                    ),
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
