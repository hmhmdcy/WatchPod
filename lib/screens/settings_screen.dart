import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/storage_service.dart';
import '../services/rss_service.dart';
import '../services/top_podcast_service.dart';
import '../models/podcast_subscription.dart';
import '../widgets/glass_components.dart';
import '../widgets/wear_scale.dart';
import '../widgets/hot_podcast_list.dart';
import '../widgets/episode_preview_sheet.dart';
import 'tag_picker_page.dart';

/// 添加订阅页面
/// 新布局：顶部操作栏(添加订阅+刷新按钮) + 热门播客列表(最大化)
/// 数据层委托给 TopPodcastService，UI 委托给子组件
class SettingsScreen extends StatefulWidget {
  final StorageService storageService;

  const SettingsScreen({super.key, required this.storageService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _topService = TopPodcastService();
  final _rssService = RssService();

  bool _adding = false;
  bool _loadingTop = false;
  String? _error;
  String? _topPodcastsError;
  int _subscriptionCount = 0;
  List<TopPodcastItem> _topPodcasts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _loadTopPodcasts();
    await _loadSubscriptionCount();
  }

  Future<void> _loadSubscriptionCount() async {
    final subs = await widget.storageService.loadSubscriptions();
    if (mounted) setState(() => _subscriptionCount = subs.length);
  }

  Future<void> _loadTopPodcasts() async {
    if (kIsWeb) {
      _topPodcasts = [
        TopPodcastItem(name: '科技早知道', author: '硅谷徐老师', coverUrl: 'https://picsum.photos/seed/pod1/200/200', lookupId: '1', feedUrl: 'https://example.com/feed1.xml', summary: '聚焦科技前沿，解读行业动态'),
        TopPodcastItem(name: '忽左忽右', author: 'JustPod', coverUrl: 'https://picsum.photos/seed/pod2/200/200', lookupId: '2', feedUrl: 'https://example.com/feed2.xml', summary: '文化沙龙类节目'),
        TopPodcastItem(name: '故事FM', author: '寇爱哲', coverUrl: 'https://picsum.photos/seed/pod3/200/200', lookupId: '3', feedUrl: 'https://example.com/feed3.xml', summary: '用你的声音，讲述你的故事'),
        TopPodcastItem(name: '随机波动', author: '傅适野', coverUrl: 'https://picsum.photos/seed/pod4/200/200', lookupId: '4', feedUrl: 'https://example.com/feed4.xml', summary: '泛文化类播客'),
        TopPodcastItem(name: '不合时宜', author: '王磬', coverUrl: 'https://picsum.photos/seed/pod5/200/200', lookupId: '5', feedUrl: 'https://example.com/feed5.xml', summary: '一档由年轻人参与制作的播客'),
      ];
      setState(() => _loadingTop = false);
      return;
    }
    // 先返回缓存（不显示 loading，太快了用户看不到）
    try {
      final cacheDir = await widget.storageService.localPath;
      final items = await _topService.getTopPodcasts(cacheDir: cacheDir);
      if (!mounted) return;
      setState(() {
        _topPodcasts = items;
        _loadingTop = false;
        _topPodcastsError = null;
      });
      // 后台异步解析 feedUrl（不阻塞 UI）
      _topService.resolveFeedUrls(items).then((resolved) {
        if (mounted) setState(() => _topPodcasts = resolved);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingTop = false;
          _topPodcastsError = '加载失败: $e';
        });
      }
    }
  }

  Future<void> _showAddFeedDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ws = WearScale.of(ctx);
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ws.s(16)),
          ),
          title: Text(
            '添加 RSS 订阅',
            style: TextStyle(fontSize: ws.fs(14), color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(fontSize: ws.sp(13), color: Colors.white),
            decoration: InputDecoration(
              hintText: '粘贴 RSS 链接',
              hintStyle: TextStyle(
                fontSize: ws.sp(13),
                color: Colors.grey[500],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ws.s(10)),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ws.s(10)),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: Color(0xFF6C63FF)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: ws.s(12),
                vertical: ws.s(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('取消', style: TextStyle(fontSize: 12)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text(
                '添加',
                style: TextStyle(fontSize: 12, color: Color(0xFF6C63FF)),
              ),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result != null && result.isNotEmpty) {
      _subscribeToFeed(result);
    }
  }

  Future<void> _subscribeToFeed(String feedUrl) async {
    if (feedUrl.isEmpty) return;
    setState(() {
      _adding = true;
      _error = null;
    });

    try {
      final result = await _rssService.parseFeed(feedUrl);
      final subs = await widget.storageService.loadSubscriptions();
      if (subs.any((s) => s.feedUrl == feedUrl)) {
        setState(() {
          _error = '已订阅该播客';
          _adding = false;
        });
        return;
      }

      final suggested = PodcastSubscription.suggestTags(
        result.podcast.title,
        result.podcast.description,
      );

      if (mounted) {
        final tags = await _showTagPicker(result.podcast, suggested);
        if (tags == null) {
          setState(() => _adding = false);
          return;
        }

        final taggedPodcast = result.podcast.copyWith(tags: tags);
        await widget.storageService.addSubscription(taggedPodcast);
        await widget.storageService.saveEpisodes(
          taggedPodcast.id,
          result.episodes,
        );

        if (mounted) {
          setState(() => _subscriptionCount++);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => _error = '订阅失败: $e');
    } finally {
      setState(() => _adding = false);
    }
  }

  Future<void> _previewPodcast(TopPodcastItem item) async {
    if (item.feedUrl == null) return;
    try {
      final result = await _rssService.parseFeed(item.feedUrl!);
      if (!mounted) return;
      showEpisodePreview(
        context,
        item: item,
        podcast: result.podcast,
        episodes: result.episodes,
        onSubscribe: _subscribeToFeed,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = '加载节目失败: $e');
      }
    }
  }

  Future<List<String>?> _showTagPicker(
    PodcastSubscription podcast,
    List<String> suggested,
  ) {
    return TagPickerPage.show(
      context,
      podcast: podcast,
      suggested: suggested,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PopScope(
        canPop: true,
        child: GlassBackground(
          child: Stack(
            children: [
              // ── 内容部分（去掉 WatchSafeArea，改用 SafeArea + 卡片自适应 padding） ──
              SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: ws.s(60)),
                    // 热门播客标题
                    Padding(
                      padding: EdgeInsets.only(left: ws.s(24), bottom: ws.s(4)),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('🔥 苹果热门播客',
                            style: TextStyle(
                                fontSize: ws.sp(13),
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: ws.s(8)),
                        child: HotPodcastList(
                          items: _topPodcasts,
                          loading: _loadingTop,
                          error: _topPodcastsError,
                          subscribeError: _error,
                          showTitle: false,
                          onItemTap: (item) => _previewPodcast(item),
                          onSubscribe: (feedUrl) => _subscribeToFeed(feedUrl),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── 顶部三个按钮（悬浮在内容上） ──
              TopActionBar(
                actions: [
                  TopAction(
                    child: Icon(Icons.arrow_back, color: Colors.white70, size: ws.s(18)),
                    onTap: () => Navigator.pop(context),
                  ),
                  TopAction(
                    child: _loadingTop
                        ? SizedBox(
                            width: ws.s(14), height: ws.s(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white54,
                            ),
                          )
                        : Icon(Icons.refresh, color: Colors.white70, size: ws.s(18)),
                    onTap: _loadingTop
                        ? null
                        : () async {
                            await _topService.invalidateCache();
                            _loadTopPodcasts();
                          },
                  ),
                  TopAction(
                    child: _adding
                        ? SizedBox(
                            width: ws.s(14), height: ws.s(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white,
                            ),
                          )
                        : Icon(Icons.add, color: Colors.white, size: ws.s(18)),
                    onTap: _adding ? null : _showAddFeedDialog,
                    brighter: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
