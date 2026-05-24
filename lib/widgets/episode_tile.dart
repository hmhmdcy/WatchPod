import 'package:flutter/material.dart';
import 'glass_components.dart';
import 'wear_scale.dart';

class EpisodeTile extends StatelessWidget {
  final String title;
  final String? duration;
  final String? imageUrl;
  final bool isDownloaded;
  final bool isPlaying;
  final bool? isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const EpisodeTile({
    super.key,
    required this.title,
    this.duration,
    this.imageUrl,
    this.isDownloaded = false,
    this.isPlaying = false,
    this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);
    final showCheck = isSelected != null;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: ws.s(4), vertical: ws.s(4)),
        padding: EdgeInsets.all(ws.s(10)),
        decoration: BoxDecoration(
          color: isSelected == true
              ? const Color(0xFF6C63FF).withValues(alpha: 0.15)
              : isPlaying
                  ? const Color(0xFF6C63FF).withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(ws.s(12)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            if (showCheck) ...[
              Container(
                width: ws.s(20),
                height: ws.s(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected == true
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: isSelected == true
                        ? const Color(0xFF6C63FF)
                        : Colors.white24,
                  ),
                ),
                child: isSelected == true
                    ? Icon(Icons.check, size: ws.s(14), color: Colors.white)
                    : null,
              ),
              SizedBox(width: ws.s(8)),
            ],
            // 封面
            GlassImage(
              imageUrl: imageUrl,
              size: ws.capped(36, maxScale: 1.1),
              borderRadius: ws.s(8),
            ),
            SizedBox(width: ws.s(8)),

            // 文字
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: ws.sp(13),
                      fontWeight:
                          isPlaying ? FontWeight.bold : FontWeight.normal,
                      color: isPlaying
                          ? const Color(0xFF6C63FF)
                          : Colors.white,
                    ),
                  ),
                  if (duration != null || isDownloaded)
                    Padding(
                      padding: EdgeInsets.only(top: ws.s(3)),
                      child: Row(
                        children: [
                          if (duration != null)
                            Text(duration!,
                                style: TextStyle(
                                    fontSize: ws.sp(11),
                                    color: Colors.grey[400])),
                          if (isDownloaded)
                            Padding(
                              padding: EdgeInsets.only(left: ws.s(6)),
                              child: Icon(Icons.download_done,
                                  size: ws.s(14), color: Colors.green[400]),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // 播放按钮
            Container(
              padding: EdgeInsets.all(ws.s(6)),
              decoration: BoxDecoration(
                color: isPlaying
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(ws.s(14)),
              ),
              child: Icon(
                isPlaying ? Icons.play_arrow : Icons.play_circle_outline,
                size: ws.s(20),
                color: isPlaying ? const Color(0xFF6C63FF) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
