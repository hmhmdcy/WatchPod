import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'wear_scale.dart';

/// 右侧紧贴弧形表盘的毛玻璃滑条
///
/// 设计目标：
/// - 视觉上只露出一条极细的弧线（3dp 宽），紧贴圆形屏幕右边缘内侧
/// - 手指触摸/拖拽时显示滑块圆点 + 标签浮层
/// - 滑到底部停 2 秒触发添加订阅
class TagTrack extends StatefulWidget {
  final List<String> tags;
  final String? activeTag;
  final ValueChanged<String?> onTagChanged;
  final VoidCallback onAddSubscription;

  const TagTrack({
    super.key,
    required this.tags,
    required this.activeTag,
    required this.onTagChanged,
    required this.onAddSubscription,
  });

  @override
  State<TagTrack> createState() => _TagTrackState();
}

class _TagTrackState extends State<TagTrack> {
  // 滑条状态
  double _dragY = 0;
  bool _isDragging = false;
  String? _hoverLabel;
  bool _showAddHint = false;
  Timer? _bottomTimer;

  // 标签列表（始终包含 "全部"）
  late List<String> _allLabels;
  // 弧线参数（按屏幕尺寸计算）
  double _arcTop = 0;
  double _arcBottom = 0;
  double _arcCenterX = 0; // 弧线的 x 坐标（屏幕坐标）
  double _trackInset = 0; // 弧线离屏幕右边缘的距离

  @override
  void initState() {
    super.initState();
    _allLabels = ['全部', ...widget.tags];
  }

  @override
  void dispose() {
    _bottomTimer?.cancel();
    super.dispose();
  }

  void _startBottomTimer() {
    _bottomTimer?.cancel();
    _bottomTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onAddSubscription();
      }
    });
  }

  void _cancelBottomTimer() {
    _bottomTimer?.cancel();
    _bottomTimer = null;
  }

  /// 根据 y 坐标（弧线轨迹上的位置）计算当前标签 / 是否在底部区域
  void _updateFromY(double rawY, double height) {
    // 将 y 映射到弧线轨迹上
    final clampedY = rawY.clamp(_arcTop, _arcBottom);
    final arcLen = _arcBottom - _arcTop;
    final ratio = arcLen > 0 ? (clampedY - _arcTop) / arcLen : 0.0;
    // 顶部≈0 → "全部"，底部≈1 → 最末标签
    final index = (ratio * (_allLabels.length - 1)).round().clamp(0, _allLabels.length - 1);
    final isBottom = ratio >= 0.85;

    final label = _allLabels[index];

    setState(() {
      _hoverLabel = label;
      _showAddHint = isBottom;
      _dragY = clampedY;
    });

    if (isBottom) {
      _startBottomTimer();
    } else {
      _cancelBottomTimer();
    }
  }

  void _commitLabel() {
    if (_showAddHint) {
      _cancelBottomTimer();
      widget.onAddSubscription();
    } else if (_hoverLabel != null) {
      final newTag = _hoverLabel == '全部' ? null : _hoverLabel;
      widget.onTagChanged(newTag);
    }
    setState(() {
      _isDragging = false;
      _showAddHint = false;
    });
  }

  /// 根据屏幕尺寸计算弧线参数
  void _calcArcParameters(Size screenSize) {
    final h = screenSize.height;
    final w = screenSize.width;
    // 圆的半径取宽高中的较小者
    final r = min(w, h) / 2;
    // 弧线位置：从右上约 30° 到右下约 30°
    // 最右边缘是 (w, h/2)
    // 我们想让弧线在圆内边缘，距离右侧边约 4dp
    _trackInset = 4;
    final arcCenterX = w - _trackInset;
    // 圆的圆心坐标（假设屏幕是圆形的 WatchSafeArea）
    final circleCenter = Offset(w / 2, h / 2);
    final circleR = r;

    // 弧线在右边缘，以圆心到 arcCenterX 的距离作为弦的参考
    // 弧线贴圆：arcCenterX 与圆心的水平距离
    final dxFromCenter = arcCenterX - circleCenter.dx;
    if (dxFromCenter < circleR) {
      // 弧线顶部 y：当 x=arcCenterX 时，圆上的 y 值
      final halfChord = sqrt(max(0.0, circleR * circleR - dxFromCenter * dxFromCenter));
      _arcTop = circleCenter.dy - halfChord + 8;  // 留 8dp 边距
      _arcBottom = circleCenter.dy + halfChord - 8;
    } else {
      _arcTop = h * 0.1;
      _arcBottom = h * 0.9;
    }
    _arcCenterX = arcCenterX;
  }

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);
    final screenSize = MediaQuery.of(context).size;

    // 计算弧线参数
    _calcArcParameters(screenSize);

    return GestureDetector(
      onPanStart: (details) {
        // 检查触摸位置是否接近弧线（扩大命中区域到 20dp）
        final dx = (details.localPosition.dx - (_arcCenterX));
        if (dx.abs() > 20) return; // 太远不响应
        setState(() => _isDragging = true);
        _updateFromY(details.localPosition.dy, screenSize.height);
      },
      onPanUpdate: (details) {
        _updateFromY(details.localPosition.dy, screenSize.height);
      },
      onPanEnd: (_) => _commitLabel(),
      onPanCancel: () {
        _cancelBottomTimer();
        setState(() => _isDragging = false);
      },
      child: SizedBox(
        width: 40, // 触摸区域宽度
        height: screenSize.height,
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size(40, screenSize.height),
            painter: _TagTrackPainter(
              dragY: _isDragging ? _dragY : null,
              arcTop: _arcTop,
              arcBottom: _arcBottom,
              arcCenterX: _arcCenterX,
              dragX: _isDragging ? _arcCenterX : null,
              isDragging: _isDragging,
              showAddHint: _showAddHint,
              trackInset: _trackInset,
              ws: ws,
            ),
            child: _isDragging
                ? Stack(
                    children: [
                      // 标签浮层
                      if (_hoverLabel != null && !_showAddHint)
                        Positioned(
                          top: _dragY - ws.s(12),
                          left: 0,
                          child: _buildLabelBubble(_hoverLabel!, ws),
                        ),
                      // "添加订阅" 提示
                      if (_showAddHint)
                        Positioned(
                          top: _dragY - ws.s(30),
                          left: 0,
                          child: _buildAddBubble(ws),
                        ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildLabelBubble(String label, WearScale ws) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ws.s(10), vertical: ws.s(6)),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(ws.s(10)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: ws.sp(12),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAddBubble(WearScale ws) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ws.s(10), vertical: ws.s(8)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(ws.s(10)),
        border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, color: Colors.white, size: ws.s(14)),
          SizedBox(width: ws.s(4)),
          Text('添加订阅',
              style: TextStyle(
                  fontSize: ws.sp(11),
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// 滑条绘制器
class _TagTrackPainter extends CustomPainter {
  final double? dragY;
  final double? dragX;
  final double arcTop;
  final double arcBottom;
  final double arcCenterX;
  final bool isDragging;
  final bool showAddHint;
  final double trackInset;
  final WearScale ws;

  _TagTrackPainter({
    required this.dragY,
    required this.dragX,
    required this.arcTop,
    required this.arcBottom,
    required this.arcCenterX,
    required this.isDragging,
    required this.showAddHint,
    required this.trackInset,
    required this.ws,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    // ── 弧线轨道：紧贴圆右边缘的一条细弧线 ──
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // 弧线从 arcTop 到 arcBottom，在 arcCenterX 位置
    final arcH = arcBottom - arcTop - 8; // 向内缩4dp，上下各留4dp避免贴边被吞
    if (arcH > 0) {
      const steps = 24;
      for (int i = 0; i <= steps; i++) {
        final t = i / steps;
        final y = arcTop + 4 + arcH * t; // 整体下移4dp补偿顶部收缩
        // 弧线略微凸出 — 中间更靠左（贴合圆）
        final bulge = sin(t * pi) * 6; // 最大凸出 6dp
        final x = w - bulge - 3; // 再向左缩3dp，避免贴边被裁切
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    } else {
      // fallback：直线
      path.moveTo(w * 0.5, arcTop);
      path.lineTo(w * 0.5, arcBottom);
    }
    canvas.drawPath(path, trackPaint);

    // ── 滑块圆点 ──
    if (dragY != null && isDragging) {
      final dotRadius = ws.s(6);
      final showAdd = showAddHint;

      final dotPaint = Paint()
        ..color = showAdd ? const Color(0xFF6C63FF) : Colors.white
        ..style = PaintingStyle.fill;

      // 滑块 x 位置：弧线位置
      final t = (dragY! - arcTop) / max(1.0, arcBottom - arcTop);
      final bulge = sin(t.clamp(0, 1.0) * pi) * 6;
      final dotX = w - bulge;

      canvas.drawCircle(
        Offset(dotX, dragY!),
        dotRadius,
        dotPaint,
      );

      if (showAdd) {
        final glowPaint = Paint()
          ..color = const Color(0xFF6C63FF).withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(dotX, dragY!),
          dotRadius * 2.5,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TagTrackPainter oldDelegate) {
    return oldDelegate.dragY != dragY ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.showAddHint != showAddHint;
  }
}
