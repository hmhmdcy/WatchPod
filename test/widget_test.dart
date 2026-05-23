import 'package:flutter_test/flutter_test.dart';
import 'package:watchpod/models/podcast_subscription.dart';
import 'package:watchpod/models/episode.dart';

void main() {
  test('PodcastSubscription serialization', () {
    final sub = PodcastSubscription(
      id: '123',
      title: 'Test Podcast',
      author: 'Test Author',
      feedUrl: 'https://example.com/feed.xml',
    );
    final json = sub.toJson();
    final restored = PodcastSubscription.fromJson(json);
    expect(restored.title, 'Test Podcast');
    expect(restored.feedUrl, 'https://example.com/feed.xml');
  });

  test('Episode serialization', () {
    final ep = Episode(
      id: 'ep1',
      podcastId: '123',
      title: 'Test Episode',
      audioUrl: 'https://example.com/audio.mp3',
    );
    final json = ep.toJson();
    final restored = Episode.fromJson(json);
    expect(restored.title, 'Test Episode');
    expect(restored.audioUrl, 'https://example.com/audio.mp3');
  });
}
