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
  String? _error;

  // 临时保存解析结果的标签编辑状态

  // Popular Chinese podcast RSS feeds for quick add
  static const _presetFeeds = [
    ('故事FM', 'https://storyfm.cn/feed/episodes'),
    ('忽左忽右', 'https://justpodmedia.com/rss/left-right.xml'),
    ('声动早咖啡', 'https://feeds.fireside.fm/sheng-espresso/rss'),
    ('随机波动', 'https://feeds.fireside.fm/stovol/rss'),
    ('博物志', 'https://bowuzhi.fm/feed/podcast/'),
  ];

  void _addFeed(String feedUrl) async {
    if (feedUrl.isEmpty) return;
    setState(() {
      _adding = true;
      _error = null;
    });

    try {
      // Validate by parsing
      final rssService = RssService();
      final result = await rssService.parseFeed(feedUrl);

      // Check if already subscribed
      final subs = await widget.storageService.loadSubscriptions();
      if (subs.any((s) => s.feedUrl == feedUrl)) {
        setState(() {
          _error = '已订阅该播客';
          _adding = false;
        });
        return;
      }

      // 自动推荐标签
      final suggested = PodcastSubscription.suggestTags(
          result.podcast.title, result.podcast.description);

      // 弹出标签选择对话框
      if (mounted) {
        final tags = await _showTagPicker(result.podcast, suggested);
        if (tags == null) {
          setState(() => _adding = false);
          return; // 用户取消
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
              Text(
                '选择标签',
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                podcast.title,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (suggested.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '已根据内容推荐标签: ${suggested.join(', ')}',
                    style:
                        const TextStyle(fontSize: 10, color: Color(0xFF6C63FF)),
                  ),
                ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: PodcastSubscription.presetTags.map((tag) {
                final isSelected = selected.contains(tag);
                return GestureDetector(
                  onTap: () {
                    setDialogState(() {
                      if (isSelected) {
                        selected.remove(tag);
                      } else {
                        selected.add(tag);
                      }
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('确定',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    return result;
  }

  void _removeAllFeeds() async {
    final subs = await widget.storageService.loadSubscriptions();
    if (subs.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('确认删除',
            style: TextStyle(fontSize: 14, color: Colors.white)),
        content: Text('删除所有 ${subs.length} 个订阅？',
            style: TextStyle(fontSize: 12, color: Colors.grey[300])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除',
                style: TextStyle(fontSize: 12, color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      for (final sub in subs) {
        await widget.storageService.removeSubscription(sub.feedUrl);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  /// 查看已有订阅及标签
  void _showSubscriptions() async {
    final subs = await widget.storageService.loadSubscriptions();
    if (!mounted || subs.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('已订阅的播客',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...subs.map((sub) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassContainer(
                    blur: 4,
                    tintColor: Colors.white.withValues(alpha: 0.04),
                    borderRadius: 10,
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sub.title,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              if (sub.tags.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 2,
                                    children: sub.tags.map((tag) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6C63FF)
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(tag,
                                              style: const TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.white70)),
                                        )).toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
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
            onPressed: _showSubscriptions,
            tooltip: '查看已订阅',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '粘贴 RSS 链接',
                            hintStyle: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (v) => _addFeed(v.trim()),
                        ),
                      ),
                      GestureDetector(
                        onTap: _adding
                            ? null
                            : () => _addFeed(_urlController.text.trim()),
                        child: GlassContainer(
                          blur: 6,
                          tintColor: const Color(0xFF6C63FF).withValues(alpha: 0.6),
                          borderRadius: 18,
                          padding: const EdgeInsets.all(8),
                          child: _adding
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.add,
                                  color: Colors.white, size: 20),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(_error!,
                        style: const TextStyle(fontSize: 11, color: Colors.red)),
                  ),
                ],

                const SizedBox(height: 16),
                const Text('快速订阅',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold)),

                const SizedBox(height: 8),
                // 预设播客列表
                ..._presetFeeds.map((feed) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: GestureDetector(
                        onTap: () => _addFeed(feed.$2),
                        child: GlassContainer(
                          blur: 6,
                          tintColor: Colors.white.withValues(alpha: 0.06),
                          borderRadius: 10,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              GlassContainer(
                                blur: 4,
                                tintColor: Colors.white.withValues(alpha: 0.08),
                                borderRadius: 10,
                                padding: const EdgeInsets.all(6),
                                child: Icon(Icons.podcasts,
                                    size: 16, color: Colors.grey[300]),
                              ),
                              const SizedBox(width: 8),
                              Text(feed.$1,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white)),
                              const Spacer(),
                              const Icon(Icons.add_circle_outline,
                                  size: 16,
                                  color: Color(0xFF6C63FF)),
                            ],
                          ),
                        ),
                      ),
                    )),

                const SizedBox(height: 16),
                // 标签说明
                GlassContainer(
                  blur: 4,
                  tintColor: const Color(0xFF6C63FF).withValues(alpha: 0.08),
                  borderRadius: 8,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: const Text(
                    '💡 订阅时会自动根据播客内容推荐标签\n你也可以手动修改标签方便分类',
                    style: TextStyle(fontSize: 10, color: Colors.white60),
                  ),
                ),

                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _removeAllFeeds,
                  child: GlassContainer(
                    blur: 6,
                    tintColor: Colors.red.withValues(alpha: 0.12),
                    borderRadius: 10,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline,
                            size: 16, color: Colors.red),
                        SizedBox(width: 6),
                        Text('删除所有订阅',
                            style: TextStyle(fontSize: 12, color: Colors.red)),
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

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
