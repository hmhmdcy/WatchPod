import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/audio_service.dart';
import '../widgets/glass_components.dart';
import '../widgets/wear_scale.dart';
import '../models/episode.dart';

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
      body: GlassBackground(
        child: Stack(
          children: [
            // 内容 — SafeArea 包裹，顶部留空给 TopActionBar
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: ws.s(48)),
                child: Center(
                  child: ListenableBuilder(
                    listenable: audioService,
                    builder: (context, _) {
              final ep = kIsWeb && audioService.currentEpisode == null
                  ? Episode(
                      id: 'mock-player-ep',
                      podcastId: 'mock-1',
                      title: '第3期：AI 时代来临 — 与硅谷业内人士深度对话',
                      description: '模拟剧集用于布局调试',
                      imageUrl: 'https://picsum.photos/seed/player/200/200',
                      publishedAt: DateTime.now(),
                      duration: Duration(minutes: 45, seconds: 30),
                    )
                  : audioService.currentEpisode;
              final pos = kIsWeb && audioService.currentEpisode == null
                  ? const Duration(minutes: 12, seconds: 34)
                  : audioService.position;
              final dur = kIsWeb && audioService.currentEpisode == null
                  ? const Duration(minutes: 45, seconds: 30)
                  : audioService.duration ?? Duration(seconds: 1);

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: ws.s(8)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // 顶部弹性（确保内容居中且在返回按钮之下）
                    const Spacer(flex: 1),

                    // ─── 中间内容区 ───
                    // 播客封面
                    GlassImage(
                      imageUrl: ep?.imageUrl,
                      size: ws.capped(68, maxScale: 1.2),
                      borderRadius: ws.s(18),
                    ),
                    SizedBox(height: ws.s(10)),

                    // ─── 剧集标题（紧凑版） ───
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: ws.s(8), vertical: ws.s(6)),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(ws.s(8)),
                      ),
                      child: Text(
                        ep?.title ?? '未播放',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: ws.fs(12),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: ws.s(10)),

                    // ─── 进度条 ───
                    SizedBox(
                      width: min(ws.s(160), MediaQuery.of(context).size.width * 0.70),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF6C63FF),
                          inactiveTrackColor: Colors.white24,
                          thumbColor: const Color(0xFF6C63FF),
                          thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius: ws.s(6)),
                          overlayShape: RoundSliderOverlayShape(
                              overlayRadius: ws.s(12)),
                          trackHeight: ws.s(3),
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
                    SizedBox(height: ws.s(3)),

                    // ─── 时间标签 ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_formatDuration(pos),
                            style: TextStyle(fontSize: ws.sp(10), color: Colors.grey[400])),
                        SizedBox(width: ws.s(8)),
                        Text(_formatDuration(dur),
                            style: TextStyle(fontSize: ws.sp(10), color: Colors.grey[400])),
                      ],
                    ),
                    SizedBox(height: ws.s(8)),

                    // ─── 播放控制按钮（弧形排列） ───
                    // -15 · play · +15 紧凑居中，两侧按钮上移呈弧形
                    // 整体底部留足安全距离，避免被圆形边界裁切
                    Padding(
                      padding: EdgeInsets.only(bottom: ws.s(16)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        // -15 — 上移 8dp 形成弧形感
                        Padding(
                          padding: EdgeInsets.only(bottom: ws.s(8)),
                          child: GestureDetector(
                            onTap: () {
                              final newPos = pos - const Duration(seconds: 15);
                              audioService.seek(newPos < Duration.zero
                                  ? Duration.zero
                                  : newPos);
                            },
                            child: Container(
                              width: ws.s(36),
                              height: ws.s(36),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(ws.s(18)),
                              ),
                              child: Center(
                                child: Text('-15',
                                    style: TextStyle(
                                        fontSize: ws.sp(10),
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: ws.s(6)),
                        // 播放/暂停
                        GestureDetector(
                          onTap: () => audioService.togglePlayPause(),
                          child: Container(
                            width: ws.s(52),
                            height: ws.s(52),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(ws.s(26)),
                            ),
                            child: Center(
                              child: Icon(
                                audioService.isPlaying || audioService.isBuffering
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: ws.s(26),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: ws.s(6)),
                        // +15 — 上移 8dp 形成弧形感
                        Padding(
                          padding: EdgeInsets.only(bottom: ws.s(8)),
                          child: GestureDetector(
                            onTap: () {
                              final newPos = pos + const Duration(seconds: 15);
                              audioService.seek(newPos > dur ? dur : newPos);
                            },
                            child: Container(
                              width: ws.s(36),
                              height: ws.s(36),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(ws.s(18)),
                              ),
                              child: Center(
                                child: Text('+15',
                                    style: TextStyle(
                                        fontSize: ws.sp(10),
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ),
                    ],
                  ),
                );
              },
          ),
                ),
              ),
            ),
            // TopActionBar — 返回按钮
            TopActionBar(
              actions: [
                TopAction(
                  child: Icon(Icons.arrow_back, size: ws.s(18), color: Colors.white70),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
