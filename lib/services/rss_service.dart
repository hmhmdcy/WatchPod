import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import '../models/episode.dart';
import '../models/podcast_subscription.dart';

class RssService {
  final Dio _dio;

  RssService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));

  Future<({PodcastSubscription podcast, List<Episode> episodes})>
      parseFeed(String feedUrl) async {
    final response = await _dio.get(feedUrl);
    final document = XmlDocument.parse(response.data);
    final rss = document.findAllElements('rss').firstOrNull;
    if (rss == null) throw Exception('Not a valid RSS feed');

    final channel = rss.findElements('channel').firstOrNull;
    if (channel == null) throw Exception('No channel element found');

    // Parse podcast info
    final title =
        _text(channel, 'title') ?? 'Unknown Podcast';
    final author = _text(channel, 'itunes:author') ??
        _text(channel, 'author');
    final description = _text(channel, 'description');
    final imageUrl = channel
            .findElements('image')
            .firstOrNull
            ?.findElements('url')
            .firstOrNull
            ?.innerText ??
        _attr(channel, 'itunes:image', 'href');

    final podcast = PodcastSubscription(
      id: feedUrl.hashCode.toString(),
      title: title,
      author: author,
      description: description,
      imageUrl: imageUrl?.isEmpty ?? true ? null : imageUrl,
      feedUrl: feedUrl,
    );

    // Parse episodes
    final episodes = <Episode>[];
    for (final item in channel.findElements('item')) {
      final itemTitle = _text(item, 'title');
      if (itemTitle == null) continue;

      // Find audio enclosure
      final enclosure = item.findElements('enclosure').firstOrNull;
      final audioUrl = enclosure?.getAttribute('url');

      // Also check media:content
      final mediaContent = item.findElements('media:content').firstOrNull;
      final mediaUrl = mediaContent?.getAttribute('url');

      final finalUrl = audioUrl ?? mediaUrl;
      if (finalUrl == null) continue;

      final guid = _text(item, 'guid') ??
          _text(item, 'link') ??
          itemTitle.hashCode.toString();

      final durationStr = _text(item, 'itunes:duration');
      final pubDateStr = _text(item, 'pubDate');
      final itemImage = _attr(item, 'itunes:image', 'href') ?? podcast.imageUrl;

      episodes.add(Episode(
        id: guid,
        podcastId: podcast.id,
        title: itemTitle,
        description: _text(item, 'description'),
        audioUrl: finalUrl,
        imageUrl: itemImage,
        duration: _parseDuration(durationStr),
        publishedAt: pubDateStr != null ? DateTime.tryParse(pubDateStr) : null,
      ));
    }

    return (podcast: podcast, episodes: episodes);
  }

  String? _text(XmlElement parent, String tag) {
    return parent.findElements(tag).firstOrNull?.innerText;
  }

  String? _attr(XmlElement parent, String tag, String attr) {
    return parent.findElements(tag).firstOrNull?.getAttribute(attr);
  }

  Duration? _parseDuration(String? duration) {
    if (duration == null) return null;
    final parts = duration.split(':');
    if (parts.length == 3) {
      return Duration(
        hours: int.tryParse(parts[0]) ?? 0,
        minutes: int.tryParse(parts[1]) ?? 0,
        seconds: int.tryParse(parts[2]) ?? 0,
      );
    }
    if (parts.length == 2) {
      return Duration(
        minutes: int.tryParse(parts[0]) ?? 0,
        seconds: int.tryParse(parts[1]) ?? 0,
      );
    }
    final secs = int.tryParse(duration);
    if (secs != null) return Duration(seconds: secs);
    return null;
  }
}
