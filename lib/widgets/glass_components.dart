import 'dart:ui';
import 'package:flutter/material.dart';
import 'wear_scale.dart';

/// 毛玻璃容器 — 带 BackdropFilter 的模糊效果容器
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color tintColor;
  final double? borderOpacity;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.blur = 12,
    this.tintColor = const Color(0x1AFFFFFF),
    this.borderOpacity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 如果提供了 borderRadius 但没经过缩放，用上下文缩放
    // 注意：这里假设调用方传入的 borderRadius 已经是经过 ws.s() 处理的
    // 或者使用默认值

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tintColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: borderOpacity ?? 0.08),
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(margin: margin, child: content),
      );
    }

    return Container(margin: margin, child: content);
  }
}

/// 毛玻璃背景 — 铺满整个屏幕
class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
                Color(0xFF0F3460),
              ],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -40,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withValues(alpha: 0.08),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purple.withValues(alpha: 0.06),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// 毛玻璃圆角图片 — 适用于播客封面
class GlassImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double borderRadius;

  const GlassImage({
    super.key,
    this.imageUrl,
    this.size = 56,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    // 用 WarnScale.capped 限制封面最大尺寸
    final ws = WearScale.of(context);
    final imgSize = ws.capped(size, maxScale: 1.15);
    final imgRadius = ws.s(borderRadius);

    return ClipRRect(
      borderRadius: BorderRadius.circular(imgRadius),
      child: Container(
        width: imgSize,
        height: imgSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(imgRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Stack(
          children: [
            if (imageUrl != null)
              Positioned.fill(
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, a, b) => const Icon(Icons.podcasts,
                      size: 28, color: Colors.grey),
                ),
              )
            else
              const Center(
                child: Icon(Icons.podcasts, size: 28, color: Colors.grey),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(imgRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
