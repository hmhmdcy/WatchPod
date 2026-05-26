import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../models/podcast_subscription.dart';
import '../widgets/podcast_tile.dart';
import '../widgets/glass_components.dart';
import '../widgets/watch_safe_area.dart';
import '../widgets/wear_scale.dart';
import 'episodes_screen.dart';
import 'player_screen.dart';
import 'settings_screen.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../services/rss_service.dart';

/// WatchPod 首页 — Stack 布局 + 左侧分页点列 + 右侧标签列
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
  bool _isTagDragging = false;
  int _tagDragIndex = 0;

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

  List<String> get _allTagItems => ['全部', ..._allTags];

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

  PodcastSubscription get _currentPodcast {
    final filtered = _filteredSubscriptions;
    if (_currentPage >= 0 && _currentPage < filtered.length) {
      return filtered[_currentPage];
    }
    return _subscriptions.isNotEmpty ? _subscriptions.first : _subscriptions[0];
  }

  List<String> get _currentPodcastTags => _currentPodcast.tags;

  void _updateTagDragFromY(double y) {
    final height = MediaQuery.of(context).size.height;
    final ratio = (y / height).clamp(0.0, 1.0);
    final index = (ratio * (_allTagItems.length - 1)).round().clamp(0, _allTagItems.length - 1);
    if (index != _tagDragIndex) {
      setState(() => _tagDragIndex = index);
    }
  }

  void _commitTagDrag() {
    if (!_isTagDragging) return;
    final label = _allTagItems[_tagDragIndex];
    setState(() {
      _activeTag = label == '全部' ? null : label;
      _currentPage = 0;
      _isTagDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        child: Stack(
          children: [
            // 内容区域
            SafeArea(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _subscriptions.isEmpty
                      ? _buildEmptyState(ws)
                      : SizedBox.expand(
                          child: WatchSafeArea(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: ws.s(14),
                                right: ws.s(42),
                              ),
                              child: _buildPodcastSection(ws),
                            ),
                          ),
                        ),
            ),
            // 左侧垂直页面指示小点
            if (!_loading && _subscriptions.isNotEmpty)
              Positioned(
                left: ws.s(3),
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildPageIndicator(ws),
                ),
              ),
            // 右侧标签列（常驻显示当前播客标签 / 拖拽切换筛选）
            if (!_loading && _subscriptions.isNotEmpty)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: 40,
                  child: _buildTagColumn(ws),
                ),
              ),
            // 顶部「正在播放」按钮
            if (!_loading && widget.audioService.currentEpisode != null)
              Positioned(
                top: ws.s(6),
                left: 0,
                right: 0,
                child: Center(
                  child: _buildNowPlayingButton(ws),
                ),
              ),
            // 底部「添加订阅」按钮
            if (!_loading)
              Positioned(
                bottom: ws.s(10),
                left: 0,
                right: 0,
                child: Center(
                  child: _buildAddButton(ws),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 左侧垂直页面指示点列
  Widget _buildPageIndicator(WearScale ws) {
    final count = _filteredSubscriptions.length;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        return Container(
          width: ws.s(5),
          height: ws.s(5),
          margin: EdgeInsets.symmetric(vertical: ws.s(3)),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == _currentPage
                ? const Color(0xFF6C63FF)
                : Colors.grey[600],
          ),
        );
      }),
    );
  }

  /// 右侧标签列 — 双模式
  ///   静态：显示当前播客的标签属性
  ///   拖拽：切换为标签筛选模式
  Widget _buildTagColumn(WearScale ws) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: (details) {
        setState(() => _isTagDragging = true);
        _updateTagDragFromY(details.localPosition.dy);
      },
      onVerticalDragUpdate: (details) {
        _updateTagDragFromY(details.localPosition.dy);
      },
      onVerticalDragEnd: (_) => _commitTagDrag(),
      child: Container(
        alignment: Alignment.center,
        child: _isTagDragging ? _buildDraggingTags(ws) : _buildStaticTags(ws),
      ),
    );
  }

  /// 静态模式：当前播客的标签
  Widget _buildStaticTags(WearScale ws) {
    final tags = _currentPodcastTags;
    if (tags.isEmpty) {
      return Text('⋯',
          style: TextStyle(color: Colors.grey[500], fontSize: ws.sp(9)));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: tags.map((tag) => Padding(
        padding: EdgeInsets.symmetric(vertical: ws.s(2)),
        child: Text(
          tag,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: ws.sp(10),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      )).toList(),
    );
  }

  /// 拖拽模式：所有可用标签，高亮当前选中
  Widget _buildDraggingTags(WearScale ws) {
    final items = _allTagItems;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(items.length, (i) {
        final isSelected = i == _tagDragIndex;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: ws.s(2)),
          child: Text(
            items[i],
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
              fontSize: ws.sp(isSelected ? 11 : 9),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }),
    );
  }

  /// 顶部「正在播放」按钮（紫色药丸样式）
  Widget _buildNowPlayingButton(WearScale ws) {
    return GestureDetector(
      onTap: _openPlayer,
      child: Container(
        height: ws.s(28),
        padding: EdgeInsets.symmetric(horizontal: ws.s(10)),
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(ws.s(14)),
          border: Border.all(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: ws.s(6),
              height: ws.s(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF6C63FF),
              ),
            ),
            SizedBox(width: ws.s(3)),
            Icon(Icons.play_arrow, color: Colors.white, size: ws.s(14)),
            SizedBox(width: ws.s(3)),
            Text('正在播放',
                style: TextStyle(
                    fontSize: ws.sp(10),
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  /// 底部「添加订阅」按钮
  Widget _buildAddButton(WearScale ws) {
    return GestureDetector(
      onTap: _openSettings,
      child: Container(
        height: ws.s(32),
        padding: EdgeInsets.symmetric(horizontal: ws.s(16)),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ws.s(16)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: ws.s(14)),
            SizedBox(width: ws.s(3)),
            Text('添加订阅',
                style: TextStyle(
                    fontSize: ws.sp(11),
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
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
