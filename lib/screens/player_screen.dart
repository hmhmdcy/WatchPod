import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../widgets/glass_components.dart';
import '../widgets/wear_scale.dart';

class PlayerScreen extends StatelessWidget {
  final AudioService audioService;

  const PlayerScreen({super.key, required this.audioService});

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, "0")}:${s.toString().padLeft(2, "0")}';
    }
    return '$m:${s.toString().padLeft(2, "0")}';
  }

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 16, color: Colors.white70),
                SizedBox(width: 6),
                Text('返回', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
      body: GlassBackground(
        child: Center(
              child: ListenableBuilder(
                listenable: audioService,
                builder: (context, _) {
                  final ep = audioService.currentEpisode;
                  final pos = audioService.position;
                  final dur = audioService.duration ?? Duration(seconds: 1);

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: ws.s(8)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 播客封面
                        GlassImage(
                          imageUrl: ep?.imageUrl,
                          size: ws.capped(90, maxScale: 1.2),
                          borderRadius: ws.s(24),
                        ),
                        SizedBox(height: ws.s(14)),

                        // 剧集标题
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: ws.s(10), vertical: ws.s(8)),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(ws.s(10)),
                          ),
                          child: Text(
                            ep?.title ?? '未播放',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: ws.fs(13),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: ws.s(14)),

                        // 进度条
                        SizedBox(
                          width: ws.s(180),
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF6C63FF),
                              inactiveTrackColor: Colors.white24,
                              thumbColor: const Color(0xFF6C63FF),
                              thumbShape: RoundSliderThumbShape(
                                  enabledThumbRadius: ws.s(8)),
                              overlayShape: RoundSliderOverlayShape(
                                  overlayRadius: ws.s(16)),
                              trackHeight: ws.s(4),
                            ),
                            child: Slider(
                              value: min(
                                  pos.inMilliseconds /
                                      max(dur.inMilliseconds, 1).toDouble(),
                                  1.0),
                              onChanged: (v) => audioService.seek(dur * v),
                            ),
                          ),
                        ),
                        SizedBox(height: ws.s(4)),

                        // 时间标签
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_formatDuration(pos),
                                style: TextStyle(fontSize: ws.sp(11), color: Colors.grey[400])),
                            SizedBox(width: ws.s(10)),
                            Text(_formatDuration(dur),
                                style: TextStyle(fontSize: ws.sp(11), color: Colors.grey[400])),
                          ],
                        ),
                        SizedBox(height: ws.s(16)),

                        // 播放控制按钮
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 后退 15s
                            GestureDetector(
                              onTap: () {
                                final newPos = pos - const Duration(seconds: 15);
                                audioService.seek(newPos < Duration.zero
                                    ? Duration.zero
                                    : newPos);
                              },
                              child: Container(
                                padding: EdgeInsets.all(ws.s(12)),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(ws.s(24)),
                                ),
                                child: Text('-15',
                                    style: TextStyle(
                                        fontSize: ws.sp(14),
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                            SizedBox(width: ws.s(22)),

                            // 播放/暂停
                            GestureDetector(
                              onTap: () => audioService.togglePlayPause(),
                              child: Container(
                                padding: EdgeInsets.all(ws.s(16)),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C63FF).withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(ws.s(32)),
                                ),
                                child: Icon(
                                  audioService.isPlaying || audioService.isBuffering
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: ws.s(32),
                                ),
                              ),
                            ),
                            SizedBox(width: ws.s(22)),

                            // 前进 15s
                            GestureDetector(
                              onTap: () {
                                final newPos = pos + const Duration(seconds: 15);
                                audioService.seek(newPos > dur ? dur : newPos);
                              },
                              child: Container(
                                padding: EdgeInsets.all(ws.s(12)),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(ws.s(24)),
                                ),
                                child: Text('+15',
                                    style: TextStyle(
                                        fontSize: ws.sp(14),
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                ),
                SizedBox(height: ws.s(16)),
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
