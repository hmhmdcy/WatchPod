import 'package:flutter/material.dart';
import 'glass_components.dart';

class PodcastTile extends StatelessWidget {
  final String title;
  final String? author;
  final String? imageUrl;
  final List<String> tags;
  final VoidCallback onTap;

  const PodcastTile({
    super.key,
    required this.title,
    this.author,
    this.imageUrl,
    this.tags = const [],
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 毛玻璃封面
            GlassImage(
              imageUrl: imageUrl,
              size: 72,
              borderRadius: 20,
            ),
            const SizedBox(height: 8),
            // 标题
            GlassContainer(
              blur: 6,
              tintColor: Colors.white.withValues(alpha: 0.05),
              borderRadius: 10,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (author != null) ...[
              const SizedBox(height: 2),
              Text(
                author!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
            ],
            // 标签
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: tags.take(3).map((tag) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(fontSize: 9, color: Colors.white70),
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
