import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/rss_service.dart';
import '../models/podcast_subscription.dart';
import '../widgets/glass_components.dart';
import '../widgets/watch_safe_area.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storageService;

  const SettingsScreen({super.key, required this.storageService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  bool _adding = false;
  bool _loadingTop = false;
  String? _error;

  /// 苹果热门播客数据缓存
  List<_TopPodcastItem> _topPodcasts = [];
  String? _topPodcastsError;

  @override
  void initState() {
    super.initState();
    _loadTopPodcasts();
  }

  /// 从 iTunes API 获取中国区热门播客
  Future<void> _loadTopPodcasts() async {
    setState(() => _loadingTop = true);
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('https://itunes.apple.com/cn/rss/toppodcasts/limit=10/json'),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);
      final entries = data['feed']['entry'] as List;

      final items = <_TopPodcastItem>[];
      for (final entry in entries) {
        final name = entry['im:name']['label'] as String;
        final author = (entry['im:artist']?['label'] as String?) ?? '';
        final images = entry['im:image'] as List;
        final cover = images.isNotEmpty ? (images.last['label'] as String) : '';
        // 从 id 中提取播客 id 用于 lookup
        final idStr = entry['id']['label'] as String;
        final podId = idStr.split('/').last.replaceAll('?uo=2', '').replaceAll('id', '');
        
        items.add(_TopPodcastItem(
          name: name,
          author: author,
          coverUrl: cover,
          lookupId: podId,
          feedUrl: null, // 稍后查询
        ));
      }
      setState(() {
        _topPodcasts = items;
        _loadingTop = false;
        _topPodcastsError = null;
      });
      // 异步查询每个播客的 RSS feed URL
      _resolveFeedUrls();
    } catch (e) {
      setState(() {
        _loadingTop = false;
        _topPodcastsError = '加载热门失败: $e';
      });
    }
  }

  Future<void> _resolveFeedUrls() async {
    for (int i = 0; i < _topPodcasts.length; i++) {
      if (_topPodcasts[i].feedUrl != null) continue;
      try {
        final client = HttpClient();
        final request = await client.getUrl(
          Uri.parse('https://itunes.apple.com/lookup?id=${_topPodcasts[i].lookupId}&entity=podcast'),
        );
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        if (data['resultCount'] > 0) {
          final feedUrl = data['results'][0]['feedUrl'] as String?;
          if (feedUrl != null) {
            setState(() {
              _topPodcasts[i] = _topPodcasts[i].copyWith(feedUrl: feedUrl);
            });
          }
        }
      } catch (_) {
        // 单个查询失败不阻塞整体
      }
    }
  }

  void _addFeed(String feedUrl) async {
    if (feedUrl.isEmpty) return;
    setState(() {
      _adding = true;
      _error = null;
    });

    try {
      final rssService = RssService();
      final result = await rssService.parseFeed(feedUrl);
      final subs = await widget.storageService.loadSubscriptions();
      if (subs.any((s) => s.feedUrl == feedUrl)) {
        setState(() {
          _error = '已订阅该播客';
          _adding = false;
        });
        return;
      }

      final suggested = PodcastSubscription.suggestTags(
          result.podcast.title, result.podcast.description);

      if (mounted) {
        final tags = await _showTagPicker(result.podcast, suggested);
        if (tags == null) {
          setState(() => _adding = false);
          return;
        }

        final taggedPodcast = result.podcast.copyWith(tags: tags);
        await widget.storageService.addSubscription(taggedPodcast);
        await widget.storageService.saveEpisodes(
            taggedPodcast.id, result.episodes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ 已订阅: ${taggedPodcast.title}'),
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => _error = '订阅失败: $e');
    } finally {
      setState(() => _adding = false);
    }
  }

  Future<List<String>?> _showTagPicker(
      PodcastSubscription podcast, List<String> suggested) async {
    final selected = List<String>.from(suggested);

    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('选择标签',
                  style: const TextStyle(
                      fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(podcast.title,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              if (suggested.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('已推荐: ${suggested.join(', ')}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF6C63FF))),
                ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 6, runSpacing: 6,
              children: PodcastSubscription.presetTags.map((tag) {
                final isSelected = selected.contains(tag);
                return GestureDetector(
                  onTap: () => setDialogState(() {
                    if (isSelected) { selected.remove(tag); } else { selected.add(tag); }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6C63FF).withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6C63FF)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(tag,
                        style: TextStyle(fontSize: 12,
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('确定',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    return result;
  }

  /// 长按订阅进入多选模式
  Future<void> _showSubscriptionSelector() async {
    final subs = await widget.storageService.loadSubscriptions();
    if (!mounted || subs.isEmpty) return;

    final selected = <PodcastSubscription>{};

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('已订阅的播客',
                      style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (selected.isNotEmpty)
                    GestureDetector(
                      onTap: () => setSheetState(() => selected.clear()),
                      child: const Text('取消选择', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: subs.length,
                  itemBuilder: (ctx, i) {
                    final sub = subs[i];
                    final isSelected = selected.contains(sub);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => setSheetState(() {
                          if (isSelected) { selected.remove(sub); } else { selected.add(sub); }
                        }),
                        child: GlassContainer(
                          blur: 4,
                          tintColor: isSelected
                              ? const Color(0xFF6C63FF).withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: 10,
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              // 选中指示器
                              Container(
                                width: 18, height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? const Color(0xFF6C63FF) : Colors.white.withValues(alpha: 0.1),
                                  border: Border.all(color: isSelected ? const Color(0xFF6C63FF) : Colors.white24),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sub.title, style: const TextStyle(fontSize: 12, color: Colors.white),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    if (sub.tags.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Wrap(spacing: 4, runSpacing: 2,
                                          children: sub.tags.map((tag) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(tag, style: const TextStyle(fontSize: 9, color: Colors.white70)),
                                          )).toList(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (selected.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final count = selected.length;
                          final confirmed = await showDialog<bool>(
                            context: ctx,
                            builder: (ctx2) => AlertDialog(
                              backgroundColor: const Color(0xFF1A1A2E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('删除订阅', style: TextStyle(fontSize: 14, color: Colors.white)),
                              content: Text('确定删除已选的 $count 个订阅及所有节目？',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[300])),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx2, false),
                                    child: const Text('取消', style: TextStyle(fontSize: 12))),
                                TextButton(onPressed: () => Navigator.pop(ctx2, true),
                                    child: const Text('删除', style: TextStyle(fontSize: 12, color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            for (final s in selected) {
                              await widget.storageService.removeSubscription(s.feedUrl);
                            }
                            Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('已删除 ${selected.length} 个订阅'), duration: const Duration(seconds: 1)),
                              );
                            }
                          }
                        },
                        child: GlassContainer(
                          blur: 6,
                          tintColor: Colors.red.withValues(alpha: 0.15),
                          borderRadius: 10,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Text('删除所选 (${selected.length})',
                                style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('添加订阅',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list, size: 18),
            onPressed: _showSubscriptionSelector,
            tooltip: '管理订阅',
          ),
        ],
      ),
      body: GlassBackground(
        child: WatchSafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Manual URL input
                GlassContainer(
                  blur: 6,
                  tintColor: Colors.white.withValues(alpha: 0.06),
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '粘贴 RSS 链接',
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (v) => _addFeed(v.trim()),
                        ),
                      ),
                      GestureDetector(
                        onTap: _adding ? null : () => _addFeed(_urlController.text.trim()),
                        child: GlassContainer(
                          blur: 6,
                          tintColor: const Color(0xFF6C63FF).withValues(alpha: 0.6),
                          borderRadius: 18,
                          padding: const EdgeInsets.all(8),
                          child: _adding
                              ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 8),
                  GlassContainer(
                    blur: 4,
                    tintColor: Colors.red.withValues(alpha: 0.1),
                    borderRadius: 8,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(_error!, style: const TextStyle(fontSize: 11, color: Colors.red)),
                  ),
                ],

                const SizedBox(height: 16),
                const Text('🔥 苹果热门播客',
                    style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                if (_loadingTop && _topPodcasts.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                  ))
                else if (_topPodcastsError != null && _topPodcasts.isEmpty)
                  GlassContainer(
                    blur: 4,
                    tintColor: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: 8,
                    padding: const EdgeInsets.all(10),
                    child: Text(_topPodcastsError!, style: const TextStyle(fontSize: 10, color: Colors.orange)),
                  )
                else
                  ..._topPodcasts.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: GestureDetector(
                      onTap: item.feedUrl != null ? () => _addFeed(item.feedUrl!) : null,
                      child: GlassContainer(
                        blur: 6,
                        tintColor: Colors.white.withValues(alpha: 0.06),
                        borderRadius: 10,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            // 封面缩略图
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                item.coverUrl,
                                width: 32, height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.podcasts, size: 16, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name,
                                      style: const TextStyle(fontSize: 12, color: Colors.white),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  if (item.author.isNotEmpty)
                                    Text(item.author,
                                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            if (item.feedUrl == null)
                              const SizedBox(width: 14, height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24))
                            else
                              const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF6C63FF)),
                          ],
                        ),
                      ),
                    ),
                  )),

                const SizedBox(height: 16),
                // 存储空间显示
                FutureBuilder<String>(
                  future: _getStorageInfo(),
                  builder: (ctx, snapshot) {
                    final info = snapshot.data ?? '计算中...';
                    return GlassContainer(
                      blur: 4,
                      tintColor: const Color(0xFF6C63FF).withValues(alpha: 0.08),
                      borderRadius: 8,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.storage, size: 14, color: Color(0xFF6C63FF)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('📦 存储: $info',
                                style: const TextStyle(fontSize: 10, color: Colors.white60)),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    // 删除所有订阅
                    final subs = await widget.storageService.loadSubscriptions();
                    if (subs.isEmpty) return;
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A2E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('确认删除', style: TextStyle(fontSize: 14, color: Colors.white)),
                        content: Text('删除所有 ${subs.length} 个订阅？',
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
                      for (final sub in subs) {
                        await widget.storageService.removeSubscription(sub.feedUrl);
                      }
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: GlassContainer(
                    blur: 6,
                    tintColor: Colors.red.withValues(alpha: 0.12),
                    borderRadius: 10,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        SizedBox(width: 6),
                        Text('删除所有订阅', style: TextStyle(fontSize: 12, color: Colors.red)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String> _getStorageInfo() async {
    try {
      final dir = await widget.storageService.downloadDir;
      int totalBytes = 0;
      await for (final entity in Directory(dir).list(recursive: true)) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
      final dirSize = _formatSize(totalBytes);
      return '已用 $dirSize';
    } catch (_) {
      return '存储信息获取失败';
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}

/// 热门播客条目数据结构
class _TopPodcastItem {
  final String name;
  final String author;
  final String coverUrl;
  final String lookupId;
  final String? feedUrl;

  const _TopPodcastItem({
    required this.name,
    required this.author,
    required this.coverUrl,
    required this.lookupId,
    this.feedUrl,
  });

  _TopPodcastItem copyWith({String? feedUrl}) =>
      _TopPodcastItem(name: name, author: author, coverUrl: coverUrl, lookupId: lookupId, feedUrl: feedUrl ?? this.feedUrl);
}
