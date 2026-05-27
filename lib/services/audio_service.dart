import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:just_audio/just_audio.dart';
import '../models/episode.dart';

enum PlaybackState { stopped, playing, paused, buffering }

class AudioService extends ChangeNotifier {
  AudioPlayer? _player;
  Episode? _currentEpisode;
  PlaybackState _state = PlaybackState.stopped;
  Duration _position = Duration.zero;
  Duration? _duration;
  bool _available = true;

  AudioService() {
    try {
      _player = AudioPlayer();
      _player!.playerStateStream.listen((state) {
        switch (state.processingState) {
          case ProcessingState.idle:
          case ProcessingState.completed:
          case ProcessingState.loading:
            _state = PlaybackState.stopped;
            break;
          case ProcessingState.buffering:
            _state = PlaybackState.buffering;
            break;
          case ProcessingState.ready:
            _state = state.playing ? PlaybackState.playing : PlaybackState.paused;
            break;
        }
        notifyListeners();
      });

      _player!.positionStream.listen((pos) {
        _position = pos;
        notifyListeners();
      });

      _player!.durationStream.listen((dur) {
        _duration = dur;
        notifyListeners();
      });
    } catch (_) {
      _available = false;
      _player = null;
    }

    // Linux Desktop 调试：注入假播放状态
    if (!kIsWeb && Platform.isLinux) {
      _currentEpisode = Episode(
        id: 'mock-episode',
        podcastId: 'mock-podcast',
        title: '测试节目',
        duration: const Duration(minutes: 30),
        publishedAt: DateTime.now(),
        description: '',
      );
    }
  }

  Episode? get currentEpisode => _currentEpisode;
  PlaybackState get state => _state;
  Duration get position => _position;
  Duration? get duration => _duration;
  bool get isPlaying => _state == PlaybackState.playing;
  bool get isBuffering => _state == PlaybackState.buffering;
  bool get available => _available;

  Future<void> play(Episode episode) async {
    if (_player == null || episode.audioUrl == null) return;
    _currentEpisode = episode;
    final source = episode.isDownloaded && episode.localPath != null
        ? AudioSource.file(episode.localPath!)
        : AudioSource.uri(Uri.parse(episode.audioUrl!));

    if (episode.playbackPosition != null &&
        episode.playbackPosition!.inSeconds > 5) {
      await _player!.setAudioSource(source,
          initialPosition: episode.playbackPosition);
    } else {
      await _player!.setAudioSource(source);
    }
    await _player!.play();
  }

  Future<void> pause() async => await _player?.pause();
  Future<void> resume() async => await _player?.play();
  Future<void> seek(Duration position) async => await _player?.seek(position);

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else if (_currentEpisode != null) {
      await resume();
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }
}
