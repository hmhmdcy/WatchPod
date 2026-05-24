import 'dart:io';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/rss_service.dart';
import '../services/top_podcast_service.dart';
import '../models/podcast_subscription.dart';
import '../models/episode.dart';
import '../widgets/glass_components.dart';
import '../widgets/wear_scale.dart';
import '../widgets/watch_safe_area.dart';
import '../widgets/settings_add_bar.dart';
import '../widgets/hot_podcast_list.dart';
import '../widgets/settings_info_bar.dart';
import '../widgets/episode_preview_sheet.dart';

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
  ) async {
    return Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _TagPickerPage(podcast: podcast, suggested: suggested),
      ),
    );
  }

  Future<String> _getStorageInfo() =>
      TopPodcastService.getStorageInfo(widget.storageService.downloadDir);

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);
    final borderRadius = ws.s(18);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 返回按钮
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: ws.s(36),
                width: ws.s(36),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white70,
                    size: ws.s(18),
                  ),
                ),
              ),
            ),
            SizedBox(width: ws.s(6)),
            // 刷新按钮
            GestureDetector(
              onTap: _loadingTop
                  ? null
                  : () async {
                      await _topService.invalidateCache();
                      _loadTopPodcasts();
                    },
              child: Container(
                height: ws.s(36),
                width: ws.s(36),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Center(
                  child: _loadingTop
                      ? SizedBox(
                          width: ws.s(14),
                          height: ws.s(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white54,
                          ),
                        )
                      : Icon(
                          Icons.refresh,
                          color: Colors.white70,
                          size: ws.s(18),
                        ),
                ),
              ),
            ),
            SizedBox(width: ws.s(6)),
            // 添加订阅按钮（+）
            GestureDetector(
              onTap: _adding ? null : _showAddFeedDialog,
              child: Container(
                height: ws.s(36),
                width: ws.s(36),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: _adding
                      ? SizedBox(
                          width: ws.s(14),
                          height: ws.s(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.add, color: Colors.white, size: ws.s(20)),
                ),
              ),
            ),
          ],
        ),
      ),
      body: PopScope(
        canPop: true,
        child: GlassBackground(
          child: Column(
            children: [
              // ── 热门播客列表（剩余空间）──
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: ws.s(12)),
                  child: WatchSafeArea(
                    child: HotPodcastList(
                      items: _topPodcasts,
                      loading: _loadingTop,
                      error: _topPodcastsError,
                      subscribeError: _error,
                      showTitle: true,
                      onItemTap: (item) => _previewPodcast(item),
                      onSubscribe: (feedUrl) => _subscribeToFeed(feedUrl),
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
}

// ─── _TagPickerPage（全屏标签选择）─ 仍作为私有页面保留 ───

class _TagPickerPage extends StatefulWidget {
  final PodcastSubscription podcast;
  final List<String> suggested;

  const _TagPickerPage({required this.podcast, required this.suggested});

  @override
  State<_TagPickerPage> createState() => _TagPickerPageState();
}

class _TagPickerPageState extends State<_TagPickerPage> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.suggested);
  }

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close, size: ws.s(20), color: Colors.white),
              SizedBox(width: ws.s(6)),
              Text(
                '选择标签',
                style: TextStyle(
                  fontSize: ws.fs(14),
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ws.s(16),
                  vertical: ws.s(4),
                ),
                child: Text(
                  widget.podcast.title,
                  style: TextStyle(
                    fontSize: ws.sp(12),
                    color: Colors.grey[400],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: ws.s(4)),
              if (widget.suggested.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: ws.s(8)),
                  child: Wrap(
                    spacing: ws.s(4),
                    runSpacing: ws.s(2),
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        '已推荐: ',
                        style: TextStyle(
                          fontSize: ws.sp(10),
                          color: const Color(0xFF6C63FF),
                        ),
                      ),
                      ...widget.suggested.map(
                        (tag) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ws.s(6),
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF6C63FF,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(ws.s(6)),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: ws.sp(9),
                              color: const Color(0xFF6C63FF),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final tagWidth =
                          (constraints.maxWidth - ws.s(12) * 3) / 4;
                      return Wrap(
                        spacing: ws.s(6),
                        runSpacing: ws.s(6),
                        alignment: WrapAlignment.center,
                        children: PodcastSubscription.presetTags.map((tag) {
                          final isSelected = _selected.contains(tag);
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (isSelected) {
                                _selected.remove(tag);
                              } else {
                                _selected.add(tag);
                              }
                            }),
                            child: Container(
                              width: tagWidth,
                              padding: EdgeInsets.symmetric(vertical: ws.s(8)),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(
                                        0xFF6C63FF,
                                      ).withValues(alpha: 0.4)
                                    : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(ws.s(14)),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF6C63FF)
                                      : Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                tag,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: ws.sp(12),
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(ws.s(16)),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, _selected),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: ws.s(12)),
                    decoration: BoxDecoration(
                      color: _selected.isEmpty
                          ? Colors.grey.withValues(alpha: 0.2)
                          : const Color(0xFF6C63FF).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(ws.s(22)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: ws.s(16), color: Colors.white),
                        SizedBox(width: ws.s(6)),
                        Text(
                          _selected.isEmpty
                              ? '跳过标签'
                              : '确定 (${_selected.length})',
                          style: TextStyle(
                            fontSize: ws.sp(13),
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
}
