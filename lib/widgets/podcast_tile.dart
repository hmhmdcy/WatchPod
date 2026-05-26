import 'package:flutter/material.dart';
import 'glass_components.dart';
import 'wear_scale.dart';

class PodcastTile extends StatelessWidget {
  final String title;
  final String? author;
  final String? imageUrl;
  final List<String> tags;
  final VoidCallback onTap;
  /// iPod 风格封面大小，默认 64px，可以传 96 等更大值
  final double coverSize;

  const PodcastTile({
    super.key,
    required this.title,
    this.author,
    this.imageUrl,
    this.tags = const [],
    required this.onTap,
    this.coverSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);
    // 封面用传进来的 coverSize，再被 WearScale.capped 限制最大 1.2 倍
    final displayCover = ws.capped(coverSize, maxScale: 1.2);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: ws.s(4), horizontal: ws.s(4)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 毛玻璃封面（自适应）
            GlassImage(
              imageUrl: imageUrl,
              size: displayCover,
              borderRadius: ws.s(18),
            ),
            SizedBox(height: ws.s(6)),
            // 标题
            Container(
              padding: EdgeInsets.symmetric(horizontal: ws.s(8), vertical: ws.s(3)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(ws.s(8)),
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: ws.sp(12),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (author != null) ...[
              SizedBox(height: ws.s(2)),
              Text(
                author!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: ws.sp(10), color: Colors.grey[400]),
              ),
            ],
            // 标签
            if (tags.isNotEmpty) ...[
              SizedBox(height: ws.s(3)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: tags.take(3).map((tag) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: ws.s(2)),
                    padding: EdgeInsets.symmetric(horizontal: ws.s(6), vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(ws.s(8)),
                      border: Border.all(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(fontSize: ws.sp(9), color: Colors.white70),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
