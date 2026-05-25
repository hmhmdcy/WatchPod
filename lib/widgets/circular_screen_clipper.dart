import 'dart:math';
import 'package:flutter/material.dart';

/// 圆形屏幕裁剪路径 — 将内容裁剪到手表圆形可见区域
///
/// 用于 Dialog/Sheet 等 Overlay 层的内容，使其不超出圆形屏幕边界。
/// 使用 [PageRouteBuilder] 时，配合 `opaque: false` 保持底层可见。
class CircularScreenClipper extends CustomClipper<Path> {
  const CircularScreenClipper();

  @override
  Path getClip(Size size) {
    final r = min(size.width, size.height) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    return Path()..addOval(Rect.fromCircle(center: center, radius: r));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
