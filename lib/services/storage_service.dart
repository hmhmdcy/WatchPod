import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/podcast_subscription.dart';
import '../models/episode.dart';

class StorageService {
  static const _subscriptionsFile = 'subscriptions.json';
  static const _episodesFile = 'episodes.json';

  Future<String> get _localPath async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<File> get _subscriptionsFileHandle async {
    final path = await _localPath;
    return File('$path/$_subscriptionsFile');
  }

  Future<File> get _episodesFileHandle async {
    final path = await _localPath;
    return File('$path/$_episodesFile');
  }

  // ---- Subscriptions ----

  Future<List<PodcastSubscription>> loadSubscriptions() async {
    try {
      final file = await _subscriptionsFileHandle;
      if (!await file.exists()) return [];
      final data = await file.readAsString();
      final list = jsonDecode(data) as List;
      return list
          .map((e) => PodcastSubscription.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSubscriptions(List<PodcastSubscription> subs) async {
    final file = await _subscriptionsFileHandle;
    final data = jsonEncode(subs.map((s) => s.toJson()).toList());
    await file.writeAsString(data);
  }

  Future<void> addSubscription(PodcastSubscription sub) async {
    final subs = await loadSubscriptions();
    subs.add(sub);
    await saveSubscriptions(subs);
  }

  Future<void> removeSubscription(String feedUrl) async {
    final subs = await loadSubscriptions();
    subs.removeWhere((s) => s.feedUrl == feedUrl);
    await saveSubscriptions(subs);
  }

  // ---- Episodes ----

  Future<List<Episode>> loadEpisodes(String podcastId) async {
    try {
      final all = await _loadAllEpisodes();
      return all.where((e) => e.podcastId == podcastId).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Episode>> loadAllEpisodes() async {
    try {
      return await _loadAllEpisodes();
    } catch (_) {
      return [];
    }
  }

  Future<List<Episode>> _loadAllEpisodes() async {
    final file = await _episodesFileHandle;
    if (!await file.exists()) return [];
    final data = await file.readAsString();
    final list = jsonDecode(data) as List;
    return list
        .map((e) => Episode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveEpisodes(String podcastId, List<Episode> episodes) async {
    final all = await _loadAllEpisodes();
    all.removeWhere((e) => e.podcastId == podcastId);
    all.addAll(episodes);
    final file = await _episodesFileHandle;
    await file.writeAsString(jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  Future<void> updateEpisode(Episode episode) async {
    final all = await _loadAllEpisodes();
    final idx = all.indexWhere((e) => e.id == episode.id);
    if (idx >= 0) {
      all[idx] = episode;
    } else {
      all.add(episode);
    }
    final file = await _episodesFileHandle;
    await file.writeAsString(jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  // ---- Download paths ----

  Future<String> get downloadDir async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadPath = '${dir.path}/downloads';
    await Directory(downloadPath).create(recursive: true);
    return downloadPath;
  }
}
