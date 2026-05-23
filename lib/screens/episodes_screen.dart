import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/podcast_subscription.dart';
import '../models/episode.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../services/rss_service.dart';
import '../widgets/episode_tile.dart';
import '../widgets/glass_components.dart';
import '../widgets/watch_safe_area.dart';
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
  // 保存播客的最新封面
  String? _latestImageUrl;

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
  }

  Future<void> _loadEpisodes() async {
    try {
      setState(() => _loading = true);
      // Try cached first, then refresh from network
      final cached = await widget.storageService.loadEpisodes(widget.podcast.id);
      if (cached.isNotEmpty) {
        _episodes = cached;
        _latestImageUrl = _episodes
            .where((e) => e.imageUrl != null)
            .firstOrNull
            ?.imageUrl;
        setState(() => _loading = false);
      }
      // Refresh from network — 自动获取最新封面
      final result = await widget.rssService.parseFeed(widget.podcast.feedUrl);
      await widget.storageService.saveEpisodes(
          widget.podcast.id, result.episodes);

      // 更新播客的最新封面
      if (result.podcast.imageUrl != null &&
          result.podcast.imageUrl != widget.podcast.imageUrl) {
        // 封面更新了！下次进入首页时生效
      }

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
          builder: (_) =>
              PlayerScreen(audioService: widget.audioService),
        ),
      );
    }
  }

  void _downloadEpisode(Episode episode) async {
    if (episode.audioUrl == null || episode.isDownloaded) return;
    try {
      final dir = await widget.storageService.downloadDir;
      final fileName =
          '${episode.id}.${episode.audioUrl!.split('.').last}';
      final path = '$dir/$fileName';

      final dio = Dio();
      await dio.download(episode.audioUrl!, path);

      final updated = episode.copyWith(
        isDownloaded: true,
        localPath: path,
      );
      await widget.storageService.updateEpisode(updated);

      setState(() {
        final idx = _episodes.indexWhere((e) => e.id == episode.id);
        if (idx >= 0) _episodes[idx] = updated;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ 下载完成'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.podcast.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: _loading ? null : _loadEpisodes,
          ),
        ],
      ),
      body: GlassBackground(
        child: WatchSafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : _error != null
                  ? _buildError()
                  : _episodes.isEmpty
                      ? _buildEmpty()
                      : _buildEpisodeList(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassContainer(
            blur: 6,
            tintColor: Colors.red.withValues(alpha: 0.1),
            borderRadius: 20,
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.error_outline, size: 28, color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text('加载失败', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _loadEpisodes,
            child: GlassContainer(
              blur: 6,
              tintColor: Colors.white.withValues(alpha: 0.08),
              borderRadius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text('重试', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text('暂无节目',
          style: TextStyle(fontSize: 13, color: Colors.grey[400])),
    );
  }

  Widget _buildEpisodeList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      itemCount: _episodes.length,
      itemBuilder: (context, index) {
        final ep = _episodes[index];
        final isPlaying = widget.audioService.currentEpisode?.id == ep.id;
        return Dismissible(
          key: Key(ep.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: const Color(0xFF6C63FF),
            child: const Icon(Icons.download, color: Colors.white, size: 24),
          ),
          onDismissed: (_) => _downloadEpisode(ep),
          child: EpisodeTile(
            title: ep.title,
            duration: ep.formattedDuration,
            imageUrl: ep.imageUrl ?? _latestImageUrl,
            isDownloaded: ep.isDownloaded,
            isPlaying: isPlaying,
            onTap: () => _playEpisode(ep),
          ),
        );
      },
    );
  }
}
