import 'package:flutter/material.dart';
import 'dart:math';
import '../models/episode.dart';
import '../services/top_podcast_service.dart';
import 'wear_scale.dart';

/// 热门播客节目预览弹窗
/// 居中弹窗，标题为播客名称，节目列表可滚动到底部完全可见。
class EpisodePreviewSheet extends StatelessWidget {
  final TopPodcastItem item;
  final List<Episode> episodes;
  final Future<void> Function(String feedUrl) onSubscribe;

  const EpisodePreviewSheet({
    super.key,
    required this.item,
    required this.episodes,
    required this.onSubscribe,
  });

  static Future<void> show(
    BuildContext context, {
    required TopPodcastItem item,
    required List<Episode> episodes,
    required Future<void> Function(String feedUrl) onSubscribe,
  }) {
    return Navigator.push<void>(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return EpisodePreviewSheet(
            item: item,
            episodes: episodes,
            onSubscribe: onSubscribe,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _handleSubscribe(BuildContext context) {
    Navigator.pop(context);
    onSubscribe(item.feedUrl!);
  }

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);
    final screenSize = MediaQuery.of(context).size;

    // 动态计算卡片最大高度：保证在圆形可见区域内完整显示
    final topPadding = ws.s(42); // 卡片顶距，等于底距（保持上下对称）
    final cardWidth = ws.s(200);
    final radius = screenSize.height / 2; // 圆形屏幕正方形，半径=半高
    final halfCard = cardWidth / 2;
    // 圆在卡片底部位置的宽度 ≥ 卡片宽度  =>  y ≤ centerY + sqrt(r² - (w/2)²)
    final maxYFromCenter = sqrt((radius * radius) - (halfCard * halfCard));
    final maxCardBottomY = radius + maxYFromCenter;
    final availableHeight = maxCardBottomY - topPadding;

    // 使用 Material 确保 opaque: false 的 route 也有完整文字样式链
    return Material(
      color: Colors.transparent,
      child: Stack(
          children: [
            // 半透明背景遮罩 — 点击关闭
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ),
            // 顶部对齐弹窗（标题栏固定可见，列表可向下延伸超出屏幕）
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: ws.s(42)),
                child: Container(
                  width: ws.s(200),
                  constraints: BoxConstraints(
                    maxHeight: availableHeight,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(ws.s(20)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── 标题行：播客名称 + 订阅按钮 ──
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          ws.s(14),
                          ws.s(12),
                          ws.s(14),
                          0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: ws.sp(13),
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: ws.s(8)),
                            _SubscribeButton(
                              onTap: () => _handleSubscribe(context),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: ws.s(8)),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      SizedBox(height: ws.s(4)),
                      // ── 节目列表 ──
                      Expanded(
                        child: _EpisodeMiniList(episodes: episodes),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }
}

/// 半透明订阅按钮（glass 风格）
class _SubscribeButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SubscribeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ws.s(14),
          vertical: ws.s(6),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(ws.s(14)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Text(
          '订阅',
          style: TextStyle(
            fontSize: ws.sp(12),
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 节目标题列表（无封面缩略图，使用 ScrollController 可滚动）
class _EpisodeMiniList extends StatefulWidget {
  final List<Episode> episodes;

  const _EpisodeMiniList({required this.episodes});

  @override
  State<_EpisodeMiniList> createState() => _EpisodeMiniListState();
}

class _EpisodeMiniListState extends State<_EpisodeMiniList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);

    if (widget.episodes.isEmpty) {
      return Center(
        child: Text(
          '暂无节目',
          style: TextStyle(fontSize: ws.sp(12), color: Colors.grey[600]),
        ),
      );
    }

    final items = widget.episodes.length > 10 ? widget.episodes.sublist(0, 10) : widget.episodes;

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(bottom: ws.s(4)),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final ep = items[i];
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: ws.s(14), vertical: ws.s(9)),
          child: Row(
            children: [
              // 小圆点指示器
              Container(
                width: ws.s(4),
                height: ws.s(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF6C63FF),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: ws.s(8)),
              Expanded(
                child: Text(
                  ep.title,
                  style: TextStyle(
                    fontSize: ws.sp(10),
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (ep.duration != null)
                Text(
                  ep.formattedDuration,
                  style: TextStyle(
                    fontSize: ws.sp(9),
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
