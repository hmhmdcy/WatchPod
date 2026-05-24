import 'package:flutter/material.dart';
import '../models/podcast_subscription.dart';
import '../widgets/podcast_tile.dart';
import '../widgets/glass_components.dart';
import '../widgets/watch_safe_area.dart';
import '../widgets/wear_scale.dart';
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
                  : Row(
                      children: [
                        // ── 内容主体：左 2/3 ──
                        Expanded(
                          flex: 2,
                          child: WatchSafeArea(
                            child: _buildPodcastSection(ws),
                          ),
                        ),

                        // ── 右侧操作栏：约 1/4 宽，弧条贴表盘 ──
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 4.2,
                          child: ClipPath(
                            clipper: const _ArcShape(),
                            child: Container(
                              padding: EdgeInsets.only(top: ws.s(4), bottom: ws.s(4)),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  bottomLeft: Radius.circular(24),
                                ),
                              ),
                              child: Center(
                                child: _buildTopBar(ws),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  /// 右侧垂直居中操作栏，宽度填满 1/3 区域
  Widget _buildTopBar(WearScale ws) {
    final tags = _allTags;
    final hasTags = tags.isNotEmpty;
    final borderRadius = ws.s(14);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 「正在播放」按钮
        if (widget.audioService.currentEpisode != null)
          Padding(
            padding: EdgeInsets.only(bottom: ws.s(6)),
            child: GestureDetector(
              onTap: _openPlayer,
              child: Container(
                height: ws.s(36),
                padding: EdgeInsets.symmetric(horizontal: ws.s(8)),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: ws.s(8),
                      height: ws.s(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6C63FF),
                      ),
                    ),
                    SizedBox(width: ws.s(4)),
                    Icon(Icons.play_arrow, color: Colors.white, size: ws.s(16)),
                    SizedBox(width: ws.s(4)),
                    Text('正在播放',
                        style: TextStyle(
                            fontSize: ws.sp(11),
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),

        // 标签按钮（垂直排列，撑满宽度）
        if (hasTags)
          ...List.generate(_allTagItems.length, (i) {
            final tag = _allTagItems[i];
            final isActive = i == (_activeTag == null ? 0 : tags.indexOf(_activeTag!) + 1);
            return Padding(
              padding: EdgeInsets.only(bottom: ws.s(6)),
              child: GestureDetector(
                onTap: () => _selectTag(i),
                child: Container(
                  height: ws.s(36),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF6C63FF).withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: ws.sp(12),
                      color: isActive ? Colors.white : Colors.white70,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),

        // 添加订阅按钮
        GestureDetector(
          onTap: _openSettings,
          child: Container(
            height: ws.s(36),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.white, size: ws.s(18)),
                SizedBox(width: ws.s(4)),
                Text('添加',
                    style: TextStyle(
                        fontSize: ws.sp(12),
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
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
