import 'package:flutter/material.dart';
import 'glass_components.dart';

class EpisodeTile extends StatelessWidget {
  final String title;
  final String? duration;
  final String? imageUrl;
  final bool isDownloaded;
  final bool isPlaying;
  final VoidCallback onTap;

  const EpisodeTile({
    super.key,
    required this.title,
    this.duration,
    this.imageUrl,
    this.isDownloaded = false,
    this.isPlaying = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        blur: 6,
        tintColor: isPlaying
            ? const Color(0xFF6C63FF).withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: 12,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // 每集封面
            GlassImage(
              imageUrl: imageUrl,
              size: 36,
              borderRadius: 8,
            ),
            const SizedBox(width: 8),

            // 文字内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isPlaying ? FontWeight.bold : FontWeight.normal,
                      color: isPlaying
                          ? const Color(0xFF6C63FF)
                          : Colors.white,
                    ),
                  ),
                  if (duration != null || isDownloaded)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          if (duration != null)
                            Text(duration!,
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[400])),
                          if (isDownloaded)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(Icons.download_done,
                                  size: 12, color: Colors.green[400]),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // 播放图标
            GlassContainer(
              blur: 4,
              tintColor: isPlaying
                  ? const Color(0xFF6C63FF).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: 14,
              padding: const EdgeInsets.all(6),
              child: Icon(
                isPlaying ? Icons.play_arrow : Icons.play_circle_outline,
                size: 18,
                color: isPlaying
                    ? const Color(0xFF6C63FF)
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
