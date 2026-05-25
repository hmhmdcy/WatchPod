import 'dart:math';
import 'dart:async';
import 'dart:io' show File;
import 'dart:ui' show PictureRecorder, Canvas, Picture;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'wear_scale.dart';

/// 右侧紧贴圆形表盘的弧线滑条
///
/// 架构：
/// - 容器 SizedBox(40, screenHeight)，用 ClipRect 限制触摸区域
/// - 弧线用 Stack + OverflowBox 扩展到全屏绘制，避免坐标转换问题
/// - 手势在 SizedBox 内检测，弧线在全屏坐标下绘制
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
  double _dragY = 0;
  double _dragArcX = 0;  // 弧线点的 X 坐标（用于气泡沿弧线定位）
  bool _isDragging = false;
  String? _hoverLabel;
  bool _showAddHint = false;
  Timer? _bottomTimer;

  late List<String> _allLabels;

  // 弧线参数（全局屏幕坐标）
  double _arcTop = 0;
  double _arcBottom = 0;
  Offset _circleCenter = Offset.zero;
  double _arcRadius = 0;
  double _startAngleRad = -45 * pi / 180;
  double _endAngleRad = 45 * pi / 180;

  @override
  void initState() {
    super.initState();
    _allLabels = ['全部', ...widget.tags];
  }

  @override
  void didUpdateWidget(TagTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tags != widget.tags) {
      _allLabels = ['全部', ...widget.tags];
    }
  }

  @override
  void dispose() {
    _bottomTimer?.cancel();
    super.dispose();
  }

  void _startBottomTimer() {
    _bottomTimer?.cancel();
    _bottomTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) widget.onAddSubscription();
    });
  }

  void _cancelBottomTimer() {
    _bottomTimer?.cancel();
    _bottomTimer = null;
  }

  void _updateFromY(double rawY, double height) {
    if (_arcRadius <= 0) return;
    debugPrint('TAGTRACK: rawY=$rawY, height=$height, arcTop=$_arcTop, arcBottom=$_arcBottom, center=${_circleCenter.dy}, radius=$_arcRadius');
    final clampedY = rawY.clamp(_arcTop, _arcBottom);
    final dy = clampedY - _circleCenter.dy;
    final clampedDy = dy.clamp(-_arcRadius, _arcRadius);
    final theta = asin(clampedDy / _arcRadius);
    final totalArcRad = _endAngleRad - _startAngleRad;
    if (totalArcRad <= 0) return;
    final ratio = (theta - _startAngleRad) / totalArcRad;
    debugPrint('TAGTRACK: clampedY=$clampedY, dy=$dy, theta=$theta, ratio=$ratio');

    final index = (ratio * (_allLabels.length - 1)).round().clamp(0, _allLabels.length - 1);
    final isBottom = ratio >= 0.85;
    final label = _allLabels[index];
    debugPrint('TAGTRACK: STATE: _isDragging=$_isDragging, index=$index, label=$label, isBottom=$isBottom');

    setState(() {
      _hoverLabel = label;
      _showAddHint = isBottom;
      _dragY = clampedY;
      // 计算弧线上对应点的 X 坐标（圆方程）
      _dragArcX = _circleCenter.dx + _arcRadius * cos(theta);
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
      widget.onTagChanged(_hoverLabel == '全部' ? null : _hoverLabel);
    }
    setState(() {
      _isDragging = false;
      _showAddHint = false;
    });
  }

  void _calcArcParameters(Size screenSize) {
    final h = screenSize.height;
    final w = screenSize.width;
    final r = min(w, h) / 2;
    final center = Offset(w / 2, h / 2);

    const startDeg = -45.0;
    const endDeg = 45.0;
    final startRad = startDeg * pi / 180;
    final endRad = endDeg * pi / 180;

    _arcTop = center.dy + r * sin(startRad);
    _arcBottom = center.dy + r * sin(endRad);
    _circleCenter = center;
    _arcRadius = r;
    _startAngleRad = startRad;
    _endAngleRad = endRad;
  }

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);
    final screenSize = MediaQuery.of(context).size;

    _calcArcParameters(screenSize);

    return SizedBox(
      width: 40,
      height: screenSize.height,
      child: Stack(
        clipBehavior: Clip.none,  // 允许浮层溢出到左侧
        children: [
          // 弧线绘制：用 OverflowBox 溢出到全屏
          Positioned.fill(
            child: OverflowBox(
              minWidth: screenSize.width,
              maxWidth: screenSize.width,
              minHeight: screenSize.height,
              maxHeight: screenSize.height,
              alignment: Alignment.topLeft,
              child: CustomPaint(
                size: screenSize,
                painter: _TagTrackArcPainter(
                  startAngleRad: _startAngleRad,
                  endAngleRad: _endAngleRad,
                  arcTop: _arcTop,
                  arcBottom: _arcBottom,
                  arcRadius: _arcRadius,
                  arcCenterX: _circleCenter.dx,
                  arcCenterY: _circleCenter.dy,
                  strokeWidth: 10,
                  strokeColor: const Color(0xB0FFFFFF),
                  isDragging: _isDragging,
                  dragY: _isDragging ? _dragY : null,
                  showAddHint: _showAddHint,
                  ws: ws,
                ),
              ),
            ),
          ),
          // 手势检测：拖拽弧线标签切换 + 点击提交
          // 使用 translucent 确保 40dp 窄条也能响应触摸
          // behavior: HitTestBehavior.translucent 让空白区域也能接收事件
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragStart: (details) {
                setState(() => _isDragging = true);
                _updateFromY(details.localPosition.dy, screenSize.height);
              },
              onVerticalDragUpdate: (details) {
                _updateFromY(details.localPosition.dy, screenSize.height);
              },
              onVerticalDragEnd: (_) => _commitLabel(),
              onTapUp: (details) {
                _updateFromY(details.localPosition.dy, screenSize.height);
                _commitLabel();
              },
              child: const SizedBox.expand(),
            ),
          ),
          // 标签浮层 — 拖拽时渲染
          // 浮层也放在 OverflowBox 中，使用全屏坐标系
          // 气泡沿弧线运动，且气泡右边缘紧贴弧线左侧
          if (_isDragging)
            Positioned.fill(
              child: OverflowBox(
                minWidth: screenSize.width,
                maxWidth: screenSize.width,
                minHeight: screenSize.height,
                maxHeight: screenSize.height,
                alignment: Alignment.topLeft,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (_hoverLabel != null && !_showAddHint)
                      Positioned(
                        top: _dragY - ws.s(12),
                        // 气泡右边缘 = 弧线点 X 向左偏移 29px (弧线半宽5 + 间隙24)
                        // right 从全屏右边缘算起 = 屏幕宽度 - 气泡右边缘X
                        right: screenSize.width - _dragArcX + 29.0,
                        child: _buildLabelBubble(_hoverLabel!, ws),
                      ),
                    if (_showAddHint)
                      Positioned(
                        top: _dragY - ws.s(30),
                        right: screenSize.width - _dragArcX + 29.0,
                        child: _buildAddBubble(ws),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabelBubble(String label, WearScale ws) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ws.s(8), vertical: ws.s(4)),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(ws.s(8)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: ws.sp(10),
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500)),
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

/// 弧线绘制器
///
/// CustomPaint 在全屏尺寸下绘制，canvas 原点 (0,0) = 屏幕 (0,0)
/// 弧线用圆方程直接在屏幕全局坐标中计算，紧贴圆形周长
class _TagTrackArcPainter extends CustomPainter {
  final double startAngleRad;
  final double endAngleRad;
  final double arcTop;
  final double arcBottom;
  final double arcRadius;
  final double arcCenterX;
  final double arcCenterY;
  final double strokeWidth;
  final Color strokeColor;
  final bool isDragging;
  final double? dragY;
  final bool showAddHint;
  final WearScale ws;

  _TagTrackArcPainter({
    required this.startAngleRad,
    required this.endAngleRad,
    required this.arcTop,
    required this.arcBottom,
    required this.arcRadius,
    required this.arcCenterX,
    required this.arcCenterY,
    required this.strokeWidth,
    required this.strokeColor,
    required this.isDragging,
    required this.dragY,
    required this.showAddHint,
    required this.ws,
  });

  Offset _pointOnCircle(double angleRad) {
    return Offset(
      arcCenterX + arcRadius * cos(angleRad),
      arcCenterY + arcRadius * sin(angleRad),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final totalAngle = endAngleRad - startAngleRad;

    // 毛玻璃效果：底层模糊
    final blurPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // 上层半透明白色
    final trackPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const steps = 48;

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final angle = startAngleRad + totalAngle * t;
      final pt = _pointOnCircle(angle);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }

    // 先画模糊底层（毛玻璃光晕）
    canvas.drawPath(path, blurPaint);
    // 再画清晰上层
    canvas.drawPath(path, trackPaint);

    // ── 滑块圆点 ──
    if (dragY != null && isDragging) {
      final dotRadius = ws.s(6);
      final showAdd = showAddHint;
      final dotPaint = Paint()
        ..color = showAdd ? const Color(0xFF6C63FF) : Colors.white
        ..style = PaintingStyle.fill;

      final ratio = (dragY! - arcTop) / max(1.0, arcBottom - arcTop);
      final angle = startAngleRad + totalAngle * ratio.clamp(0.0, 1.0);
      final dotPt = _pointOnCircle(angle);

      canvas.drawCircle(Offset(dotPt.dx, dotPt.dy), dotRadius, dotPaint);

      if (showAdd) {
        final glowPaint = Paint()
          ..color = const Color(0xFF6C63FF).withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(dotPt.dx, dotPt.dy), dotRadius * 2.5, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_TagTrackArcPainter oldDelegate) =>
      oldDelegate.dragY != dragY ||
      oldDelegate.isDragging != isDragging ||
      oldDelegate.showAddHint != showAddHint;
}
