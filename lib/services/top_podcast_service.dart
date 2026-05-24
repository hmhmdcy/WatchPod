import 'dart:convert';
import 'dart:io';

/// 热门播客条目数据结构
class TopPodcastItem {
  final String name;
  final String author;
  final String coverUrl;
  final String lookupId;
  final String? feedUrl;
  final String summary;

  const TopPodcastItem({
    required this.name,
    required this.author,
    required this.coverUrl,
    required this.lookupId,
    this.feedUrl,
    this.summary = '',
  });

  TopPodcastItem copyWith({String? feedUrl, String? summary}) =>
      TopPodcastItem(
        name: name,
        author: author,
        coverUrl: coverUrl,
        lookupId: lookupId,
        feedUrl: feedUrl ?? this.feedUrl,
        summary: summary ?? this.summary,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'author': author,
        'coverUrl': coverUrl,
        'lookupId': lookupId,
        'feedUrl': feedUrl,
        'summary': summary,
      };

  factory TopPodcastItem.fromJson(Map<String, dynamic> json) =>
      TopPodcastItem(
        name: json['name'] as String,
        author: json['author'] as String? ?? '',
        coverUrl: json['coverUrl'] as String? ?? '',
        lookupId: json['lookupId'] as String,
        feedUrl: json['feedUrl'] as String?,
        summary: json['summary'] as String? ?? '',
      );
}

/// iTunes 热门播客数据服务
/// 带 24 小时内存缓存 + JSON 文件持久化
class TopPodcastService {
  static const String _topUrl =
      'https://itunes.apple.com/cn/rss/toppodcasts/limit=10/json';
  static const String _lookupUrl = 'https://itunes.apple.com/lookup';

  // 内存缓存
  List<TopPodcastItem>? _cachedItems;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(hours: 24);

  /// 获取热门播客列表。
  /// 优先返回缓存（24h内），过期时静默刷新。
  Future<List<TopPodcastItem>> getTopPodcasts({
    bool forceRefresh = false,
    String? cacheDir,
  }) async {
    // 有内存缓存且未过期 → 直接返回
    if (!forceRefresh && _cachedItems != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _cachedItems!;
      }
    }

    // 尝试从文件缓存加载（跨应用重启）
    if (!forceRefresh && cacheDir != null) {
      final loaded = await _loadFromFile(cacheDir);
      if (loaded != null) {
        _cachedItems = loaded;
        _cacheTime = DateTime.now();
        return loaded;
      }
    }

    // 真正从网络拉取
    try {
      final items = await _fetchFromNetwork();
      _cachedItems = items;
      _cacheTime = DateTime.now();

      // 异步写到文件缓存（不阻塞）
      if (cacheDir != null) {
        _saveToFile(cacheDir, items);
      }

      return items;
    } catch (e) {
      // 网络失败但内存有旧缓存 → 返回过期缓存
      if (_cachedItems != null) return _cachedItems!;
      rethrow;
    }
  }

  /// 后台解析 feedUrl（只在需要时调用）
  Future<List<TopPodcastItem>> resolveFeedUrls(
      List<TopPodcastItem> items,
      {bool forceRefresh = false}) async {
    // 检查是否所有 feedUrl 都已解析
    if (!forceRefresh && items.every((i) => i.feedUrl != null)) {
      return items;
    }

    final results = List<TopPodcastItem>.from(items);
    final client = HttpClient();
    try {
      for (int i = 0; i < results.length; i++) {
        if (!forceRefresh && results[i].feedUrl != null) continue;
        try {
          final request = await client.getUrl(
            Uri.parse('$_lookupUrl?id=${results[i].lookupId}&entity=podcast'),
          );
          final response = await request.close();
          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body);
          if (data['resultCount'] > 0) {
            final feedUrl = data['results'][0]['feedUrl'] as String?;
            if (feedUrl != null) {
              results[i] = results[i].copyWith(feedUrl: feedUrl);
            }
          }
        } catch (_) {}
      }
    } finally {
      client.close();
    }
    return results;
  }

  /// 强制刷新缓存（用户手动点刷新时调用）
  Future<void> invalidateCache() {
    _cachedItems = null;
    _cacheTime = null;
    return Future.value();
  }

  // ── 文件缓存 ──

  Future<List<TopPodcastItem>?> _loadFromFile(String dir) async {
    try {
      final file = File('$dir/top_podcasts_cache.json');
      if (!await file.exists()) return null;
      final data = await file.readAsString();
      final map = jsonDecode(data) as Map<String, dynamic>;
      final cachedTime = DateTime.tryParse(map['cached_at'] as String? ?? '');
      if (cachedTime == null) return null;
      // 文件缓存也是 24h 有效
      if (DateTime.now().difference(cachedTime) > _cacheDuration) {
        return null;
      }
      final list = map['items'] as List;
      return list
          .map((e) => TopPodcastItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToFile(String dir, List<TopPodcastItem> items) async {
    try {
      await Directory(dir).create(recursive: true);
      final file = File('$dir/top_podcasts_cache.json');
      final data = jsonEncode({
        'cached_at': DateTime.now().toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
      });
      await file.writeAsString(data);
    } catch (_) {}
  }

  // ── 网络请求 ──

  Future<List<TopPodcastItem>> _fetchFromNetwork() async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(_topUrl));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);
      final entries = data['feed']['entry'] as List;

      return entries.map((entry) {
        final name = entry['im:name']['label'] as String;
        final author = (entry['im:artist']?['label'] as String?) ?? '';
        final images = entry['im:image'] as List;
        final cover = images.isNotEmpty ? (images.last['label'] as String) : '';
        final summary = (entry['summary']?['label'] as String?) ?? '';
        final idStr = entry['id']['label'] as String;
        final podId =
            idStr.split('/').last.replaceAll('?uo=2', '').replaceAll('id', '');

        return TopPodcastItem(
          name: name,
          author: author,
          coverUrl: cover,
          lookupId: podId,
          summary: summary,
          feedUrl: null,
        );
      }).toList();
    } finally {
      client.close();
    }
  }

  // ── 工具方法 ──

  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static Future<String> getStorageInfo(Future<String> downloadDir) async {
    try {
      final dir = await downloadDir;
      int totalBytes = 0;
      await for (final entity in Directory(dir).list(recursive: true)) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
      return formatSize(totalBytes);
    } catch (_) {
      return '获取失败';
    }
  }
}
