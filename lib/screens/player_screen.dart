import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../widgets/glass_components.dart';
import '../widgets/watch_safe_area.dart';

class PlayerScreen extends StatelessWidget {
  final AudioService audioService;

  const PlayerScreen({super.key, required this.audioService});

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h}:${m.toString().padLeft(2, "0")}:${s.toString().padLeft(2, "0")}';
    }
    return '${m}:${s.toString().padLeft(2, "0")}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        child: WatchSafeArea(
          child: ListenableBuilder(
            listenable: audioService,
            builder: (context, _) {
              final ep = audioService.currentEpisode;
              final pos = audioService.position;
              final dur = audioService.duration ?? Duration(seconds: 1);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 播客封面（毛玻璃）
                    GlassImage(
                      imageUrl: ep?.imageUrl,
                      size: 100,
                      borderRadius: 24,
                    ),
                    const SizedBox(height: 16),

                    // 剧集标题
                    GlassContainer(
                      blur: 6,
                      tintColor: Colors.white.withValues(alpha: 0.05),
                      borderRadius: 10,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Text(
                        ep?.title ?? '未播放',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 可滑动进度条
                    SizedBox(
                      width: 160,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF6C63FF),
                          inactiveTrackColor: Colors.white24,
                          thumbColor: const Color(0xFF6C63FF),
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14),
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: min(
                              pos.inMilliseconds /
                                  max(dur.inMilliseconds, 1)
                                      .toDouble(),
                              1.0),
                          onChanged: (v) {
                            audioService
                                .seek(dur * v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),

                    // 时间标签
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_formatDuration(pos),
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[400])),
                        const SizedBox(width: 8),
                        Text(_formatDuration(dur),
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[400])),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 播放控制按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 后退 15s（毛玻璃）
                        GestureDetector(
                          onTap: () {
                            final newPos = pos - const Duration(seconds: 15);
                            audioService.seek(newPos < Duration.zero
                                ? Duration.zero
                                : newPos);
                          },
                          child: GlassContainer(
                            blur: 8,
                            tintColor: Colors.white.withValues(alpha: 0.08),
                            borderRadius: 22,
                            padding: const EdgeInsets.all(10),
                            child: const Text('-15',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // 播放/暂停（毛玻璃带主色）
                        GestureDetector(
                          onTap: () => audioService.togglePlayPause(),
                          child: GlassContainer(
                            blur: 8,
                            tintColor:
                                const Color(0xFF6C63FF).withValues(alpha: 0.6),
                            borderRadius: 30,
                            padding: const EdgeInsets.all(14),
                            child: Icon(
                              audioService.isPlaying ||
                                      audioService.isBuffering
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // 前进 15s（毛玻璃）
                        GestureDetector(
                          onTap: () {
                            final newPos = pos + const Duration(seconds: 15);
                            audioService
                                .seek(newPos > dur ? dur : newPos);
                          },
                          child: GlassContainer(
                            blur: 8,
                            tintColor: Colors.white.withValues(alpha: 0.08),
                            borderRadius: 22,
                            padding: const EdgeInsets.all(10),
                            child: const Text('+15',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
