import 'package:flutter/material.dart';
import '../models/podcast_subscription.dart';
import '../widgets/glass_components.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close, size: ws.s(20), color: Colors.white),
              SizedBox(width: ws.s(6)),
              Text(
                '选择标签',
                style: TextStyle(
                  fontSize: ws.fs(14),
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ws.s(16),
                  vertical: ws.s(4),
                ),
                child: Text(
                  widget.podcast.title,
                  style: TextStyle(
                    fontSize: ws.sp(12),
                    color: Colors.grey[400],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: ws.s(4)),
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
              Expanded(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final tagWidth =
                          (constraints.maxWidth - ws.s(12) * 3) / 4;
                      return Wrap(
                        spacing: ws.s(6),
                        runSpacing: ws.s(6),
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
                              padding: EdgeInsets.symmetric(vertical: ws.s(8)),
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
                ),
              ),
              Padding(
                padding: EdgeInsets.all(ws.s(16)),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, _selected),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: ws.s(12)),
                    decoration: BoxDecoration(
                      color: _selected.isEmpty
                          ? Colors.grey.withValues(alpha: 0.2)
                          : const Color(0xFF6C63FF).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(ws.s(22)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: ws.s(16), color: Colors.white),
                        SizedBox(width: ws.s(6)),
                        Text(
                          _selected.isEmpty
                              ? '跳过标签'
                              : '确定 (${_selected.length})',
                          style: TextStyle(
                            fontSize: ws.sp(13),
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
