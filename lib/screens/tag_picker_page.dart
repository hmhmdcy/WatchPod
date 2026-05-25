import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../models/podcast_subscription.dart';
import '../widgets/glass_components.dart';
import '../widgets/watch_screen.dart';
import '../widgets/wear_scale.dart';

/// 全屏标签选择页面
///
/// 用户在添加订阅时选择标签。提供预设标签网格 + 推荐标签提示。
///
/// 使用方式:
/// ```dart
/// final tags = await TagPickerPage.show(
///   context,
///   podcast: myPodcast,
///   suggested: ['科技'],
/// );
/// ```
class TagPickerPage extends StatefulWidget {
  final PodcastSubscription podcast;
  final List<String> suggested;

  const TagPickerPage({
    super.key,
    required this.podcast,
    required this.suggested,
  });

  /// 便捷路由：弹出标签选择页，返回选中的标签列表
  static Future<List<String>?> show(
    BuildContext context, {
    required PodcastSubscription podcast,
    required List<String> suggested,
  }) {
    return Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => TagPickerPage(
          podcast: podcast,
          suggested: suggested,
        ),
      ),
    );
  }

  @override
  State<TagPickerPage> createState() => _TagPickerPageState();
}

class _TagPickerPageState extends State<TagPickerPage> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.suggested);
  }

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);
    return WatchScreen(
      safeArea: true,
      actions: [
        TopAction(
          child: Icon(Icons.close, size: ws.s(20), color: Colors.white),
          onTap: () => Navigator.pop(context),
        ),
      ],
      child: Center(
        child: SizedBox(
          width: ws.s(192),
          child: Stack(
            children: [
              // 内容层：标题 + 推荐标签 + 标签网格（可滚动）
                  // Positioned.fill 让内容占满整个 Stack 垂直空间
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: ws.s(60),
                        bottom: ws.s(4),
                      ),
                      child: SingleChildScrollView(
                        // 大 bottom padding = 按钮高度(约30dp) + 间距(20dp) + 安全区
                        padding: EdgeInsets.only(bottom: ws.s(80)),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                          children: [
                            // 标题 — 稍大，与顶部按钮拉开距离
                            Padding(
                              padding: EdgeInsets.only(bottom: ws.s(6)),
                              child: Text(
                                widget.podcast.title,
                                style: TextStyle(
                                  fontSize: ws.sp(14),
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (widget.suggested.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(bottom: ws.s(8)),
                                child: Wrap(
                                  spacing: ws.s(4),
                                  runSpacing: ws.s(2),
                                  alignment: WrapAlignment.center,
                                  children: [
                                    Text(
                                      '已推荐: ',
                                      style: TextStyle(
                                        fontSize: ws.sp(10),
                                        color: const Color(0xFF6C63FF),
                                      ),
                                    ),
                                    ...widget.suggested.map(
                                      (tag) => Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: ws.s(6),
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF6C63FF,
                                          ).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(ws.s(6)),
                                        ),
                                        child: Text(
                                          tag,
                                          style: TextStyle(
                                            fontSize: ws.sp(9),
                                            color: const Color(0xFF6C63FF),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // 标签网格 — 2列，居中，稍宽
                            LayoutBuilder(
                              builder: (ctx, constraints) {
                                final tagWidth =
                                    (constraints.maxWidth - ws.s(3) * 3) / 2;
                                return Wrap(
                                  spacing: ws.s(8),
                                  runSpacing: ws.s(5),
                                  alignment: WrapAlignment.center,
                                  children: PodcastSubscription.presetTags.map((tag) {
                                    final isSelected = _selected.contains(tag);
                                    return GestureDetector(
                                      onTap: () => setState(() {
                                        if (isSelected) {
                                          _selected.remove(tag);
                                        } else {
                                          _selected.add(tag);
                                        }
                                      }),
                                      child: Container(
                                        width: tagWidth,
                                        padding: EdgeInsets.symmetric(vertical: ws.s(7)),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(
                                                  0xFF6C63FF,
                                                ).withValues(alpha: 0.4)
                                              : Colors.white.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(ws.s(14)),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF6C63FF)
                                                : Colors.white.withValues(alpha: 0.1),
                                          ),
                                        ),
                                        child: Text(
                                          tag,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: ws.sp(12),
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.white70,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                  // 底部确认按钮 — 半透明毛玻璃，透出下方标签，暗示可滚动
                  Positioned(
                    left: 0, right: 0, bottom: ws.s(8),
                    child: Center(
                      child: SizedBox(
                        width: ws.s(100),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(ws.s(16)),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context, _selected),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: ws.s(8)),
                                decoration: BoxDecoration(
                                  color: _selected.isEmpty
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : const Color(0xFF6C63FF).withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(ws.s(16)),
                                  border: Border.all(
                                    color: _selected.isEmpty
                                        ? Colors.white.withValues(alpha: 0.15)
                                        : const Color(0xFF6C63FF).withValues(alpha: 0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check, size: ws.s(14), color: Colors.white),
                                    SizedBox(width: ws.s(4)),
                                    Text(
                                      _selected.isEmpty ? '跳过标签' : '确定 (${_selected.length})',
                                      style: TextStyle(
                                        fontSize: ws.sp(12),
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ));
  }
}
