import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import '../models/podcast_subscription.dart';
import '../models/episode.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../services/rss_service.dart';
import '../widgets/episode_tile.dart';
import '../widgets/glass_components.dart';
import '../widgets/wear_scale.dart';
import 'player_screen.dart';

class EpisodesScreen extends StatefulWidget {
  final PodcastSubscription podcast;
  final AudioService audioService;
  final StorageService storageService;
  final RssService rssService;

  const EpisodesScreen({
    super.key,
    required this.podcast,
    required this.audioService,
    required this.storageService,
    required this.rssService,
  });

  @override
  State<EpisodesScreen> createState() => _EpisodesScreenState();
}

class _EpisodesScreenState extends State<EpisodesScreen> {
  List<Episode> _episodes = [];
  bool _loading = true;
  String? _error;
  String? _latestImageUrl;

  // 多选模式状态
  bool _selectionMode = false;
  final Set<Episode> _selectedEpisodes = {};

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
  }

  Future<void> _loadEpisodes() async {
    if (kIsWeb || Platform.isLinux) {
      // Web 调试：注入模拟剧集数据
      _episodes = List.generate(8, (i) => Episode(
        id: 'mock-ep-$i',
        podcastId: widget.podcast.id,
        title: '第${i + 1}期：${['AI 时代来临', '科技前沿', '文化漫谈', '生活感悟', '创业故事', '读书笔记', '音乐推荐', '深度访谈'][i]}',
        description: '这是一段节目简介，用来测试圆形屏幕下的列表布局效果。',
        audioUrl: null,
        imageUrl: widget.podcast.imageUrl,
        publishedAt: DateTime.now().subtract(Duration(days: i)),
        duration: Duration(minutes: 30 + i * 5),
        isDownloaded: i < 2,
      ));
      _latestImageUrl = widget.podcast.imageUrl;
      setState(() => _loading = false);
      return;
    }
    try {
      setState(() => _loading = true);
      final cached = await widget.storageService.loadEpisodes(widget.podcast.id);
      if (cached.isNotEmpty) {
        _episodes = cached;
        _latestImageUrl = _episodes
            .where((e) => e.imageUrl != null)
            .firstOrNull
            ?.imageUrl;
        setState(() => _loading = false);
      }
      final result = await widget.rssService.parseFeed(widget.podcast.feedUrl);
      await widget.storageService.saveEpisodes(widget.podcast.id, result.episodes);

      setState(() {
        _episodes = result.episodes;
        _latestImageUrl = _episodes
            .where((e) => e.imageUrl != null)
            .firstOrNull
            ?.imageUrl;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _playEpisode(Episode episode) async {
    await widget.audioService.play(episode);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(audioService: widget.audioService),
        ),
      );
    }
  }

  void _toggleSelection(Episode episode) {
    setState(() {
      if (_selectedEpisodes.contains(episode)) {
        _selectedEpisodes.remove(episode);
        if (_selectedEpisodes.isEmpty) _selectionMode = false;
      } else {
        _selectedEpisodes.add(episode);
        _selectionMode = true;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedEpisodes.clear();
    });
  }

  Future<void> _batchDelete() async {
    final count = _selectedEpisodes.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('删除节目', style: TextStyle(fontSize: 14, color: Colors.white)),
        content: Text('确定删除已选的 $count 个节目？',
            style: TextStyle(fontSize: 12, color: Colors.grey[300])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消', style: TextStyle(fontSize: 12))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除', style: TextStyle(fontSize: 12, color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      for (final ep in _selectedEpisodes) {
        await widget.storageService.removeEpisode(ep.id);
      }
      setState(() {
        _episodes.removeWhere((e) => _selectedEpisodes.contains(e));
        _exitSelectionMode();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除 $count 个节目'), duration: const Duration(seconds: 1)),
        );
      }
    }
  }

  Future<void> _batchDownload() async {
    int success = 0;
    for (final ep in _selectedEpisodes) {
      if (ep.audioUrl != null && !ep.isDownloaded) {
        try {
          final dir = await widget.storageService.downloadDir;
          final fileName = '${ep.id}.${ep.audioUrl!.split('.').last}';
          final path = '$dir/$fileName';
          final dio = Dio();
          await dio.download(ep.audioUrl!, path);
          final updated = ep.copyWith(isDownloaded: true, localPath: path);
          await widget.storageService.updateEpisode(updated);
          setState(() {
            final idx = _episodes.indexWhere((e) => e.id == ep.id);
            if (idx >= 0) _episodes[idx] = updated;
          });
          success++;
        } catch (_) {}
      }
    }
    _exitSelectionMode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ 已下载 $success 个节目'), duration: const Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);
    return Scaffold(
      body: GlassBackground(
        child: Stack(
          children: [
            // 内容
            Column(
              children: [
                // 顶部留空给 TopActionBar
                SizedBox(height: ws.s(60)),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _error != null
                          ? _buildError()
                          : _episodes.isEmpty
                              ? _buildEmpty()
                              : _buildEpisodeList(),
                ),
                // 底部操作栏（多选模式下显示）
                if (_selectionMode)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: ws.s(16), vertical: ws.s(8)),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
                      border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _batchDownload,
                            child: GlassContainer(
                              blur: 6,
                              tintColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                              borderRadius: 10,
                              padding: EdgeInsets.symmetric(vertical: ws.s(10)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.download, size: ws.s(16), color: const Color(0xFF6C63FF)),
                                  SizedBox(width: ws.s(6)),
                                  Text('下载', style: TextStyle(fontSize: ws.sp(12), color: const Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: ws.s(12)),
                        Expanded(
                          child: GestureDetector(
                            onTap: _batchDelete,
                            child: GlassContainer(
                              blur: 6,
                              tintColor: Colors.red.withValues(alpha: 0.15),
                              borderRadius: 10,
                              padding: EdgeInsets.symmetric(vertical: ws.s(10)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_outline, size: ws.s(16), color: Colors.red),
                                  SizedBox(width: ws.s(6)),
                                  Text('删除', style: TextStyle(fontSize: ws.sp(12), color: Colors.red, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            // TopActionBar — 条件显示返回/关闭按钮
            TopActionBar(
              actions: [
                TopAction(
                  child: Icon(
                    _selectionMode ? Icons.close : Icons.arrow_back,
                    size: ws.s(18),
                    color: Colors.white70,
                  ),
                  onTap: _selectionMode ? _exitSelectionMode : () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodeList() {
    final ws = WearScale.of(context);
    return ListView.builder(
      padding: EdgeInsets.only(top: ws.s(4), bottom: ws.s(64)),
      itemCount: _episodes.length,
      itemBuilder: (context, index) {
        final ep = _episodes[index];
        final isPlaying = widget.audioService.currentEpisode?.id == ep.id;
        final isSelected = _selectedEpisodes.contains(ep);
        return EpisodeTile(
          title: ep.title,
          duration: ep.formattedDuration,
          imageUrl: ep.imageUrl ?? _latestImageUrl,
          isDownloaded: ep.isDownloaded,
          isPlaying: isPlaying,
          isSelected: _selectionMode ? isSelected : null,
          onTap: _selectionMode
              ? () => _toggleSelection(ep)
              : () => _playEpisode(ep),
          onLongPress: _selectionMode
              ? null
              : () {
                  _toggleSelection(ep);
                },
        );
      },
    );
  }

  Widget _buildError() {
    final ws = WearScale.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassContainer(
            blur: 6, tintColor: Colors.red.withValues(alpha: 0.1), borderRadius: 20,
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.error_outline, size: 28, color: Colors.red),
          ),
          SizedBox(height: ws.s(8)),
          Text('加载失败', style: TextStyle(fontSize: ws.sp(13), color: Colors.grey[400])),
          SizedBox(height: ws.s(12)),
          GestureDetector(
            onTap: _loadEpisodes,
            child: GlassContainer(
              blur: 6, tintColor: Colors.white.withValues(alpha: 0.08), borderRadius: 20,
              padding: EdgeInsets.symmetric(horizontal: ws.s(20), vertical: ws.s(10)),
              child: Text('重试', style: TextStyle(fontSize: ws.sp(12), color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final ws = WearScale.of(context);
    return Center(
      child: Text('暂无节目', style: TextStyle(fontSize: ws.sp(13), color: Colors.grey[400])),
    );
  }
}
