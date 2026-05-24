import 'package:flutter/material.dart';

/// Wear OS 自适应缩放工具
///
/// 根据屏幕短边（圆形屏 = 直径）动态调整字号、间距、控件大小。
/// 所有写死的 12px, 14px 等处应该用 [WearScale] 替代。
///
/// 设计基准：360dp（标准 Wear OS 模拟器）
///
/// 用法：
///   WearScale.of(context).s(12)   → 在 360dp 上 = 12, 在 466dp 上 = ~15.5
///   WearScale.of(context).sp(12)  → 同上但带字体缩放（推荐给字号）
///   WearScale.of(context).fs(12)  → 同上但确保不超过原始值（防止大屏上过大）
class WearScale {
  final double screenShortSide;

  WearScale._(this.screenShortSide);

  /// 基准尺寸
  /// 华为 Watch 3 分辨率 466x466px @ 320 DPI
  /// 物理像素 466px, 密度因子 2.0 → 逻辑 233dp
  /// 但 HarmonyOS 实际报告给 Flutter 的 shortestSide ≈ 370dp（有差异）
  /// 实测 base=280 → ratio≈1.32, ws.s(36)≈47.5dp ✅ 按钮够大
  static const double base = 280.0;

  /// 构建 WearScale，用 [MediaQuery] 的短边
  factory WearScale.of(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final short = size.shortestSide;
    return WearScale._(short);
  }

  /// 缩放因子
  double get ratio => screenShortSide / base;

  /// 字体缩放（同 sp，语义更清晰）
  double fs(double value) => value * ratio;

  /// 按比例缩放尺寸（适用于 padding, margin, iconSize, coverSize）
  /// 在 360dp = 原始值，466dp ≈ 1.29x
  double s(double value) => value * ratio;

  /// 带字体缩放（适用于 fontSize）
  /// 在 360dp = 原始值，466dp ≈ 1.29x
  double sp(double value) => value * ratio;

  /// 带上限的缩放（适用于不能太大的值，如 icon、封面）
  /// 最小 = 原始值，最大 = 原始值的 1.2 倍
  /// 适合：封面图片、大图标
  double capped(double value, {double maxScale = 1.15}) {
    final scaled = value * ratio;
    return scaled.clamp(value, value * maxScale);
  }

  /// 带下限的缩放（适用于不能太小的值，如触摸区域）
  /// 最小 = 原始值的 0.85 倍，最大 = 原始值
  /// 适合：最小触摸尺寸 40dp
  double floor(double value, {double minScale = 0.85}) {
    final scaled = value * ratio;
    return scaled.clamp(value * minScale, value);
  }

  /// 将 EdgeInsets 按比例缩放
  EdgeInsets pad(EdgeInsets insets) {
    return EdgeInsets.only(
      left: s(insets.left),
      top: s(insets.top),
      right: s(insets.right),
      bottom: s(insets.bottom),
    );
  }

  /// 将 EdgeInsets.symmetric 按比例缩放
  EdgeInsets sym({double? h, double? v}) => EdgeInsets.symmetric(
    horizontal: h != null ? s(h) : 0,
    vertical: v != null ? s(v) : 0,
  );

  /// 将 EdgeInsets.all 按比例缩放
  EdgeInsets all(double value) => EdgeInsets.all(s(value));
}
