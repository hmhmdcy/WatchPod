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

/// 统一顶部操作按钮栏 — 玻璃风格，Stack+Positioned 悬浮在内容之上
///
/// 所有操作按钮使用统一的 40dp 圆形样式，居中排列，间距 ws.s(6)。
/// 替代 AppBar（解决 AppBar 底部深色残留问题）。
/// 用法: 在 Stack 中放在内容层之上。
///
/// [compact] = true（默认）：按钮为 40×40 圆形，适合纯图标按钮。
/// [compact] = false 时，每个按钮根据 child 的 intrinsic width 自适应宽度（最小 40dp），
/// 圆角仍为 ws.s(20)，适合 icon+text 双元素按钮。
class TopActionBar extends StatelessWidget {
  final List<TopAction> actions;
  final bool compact;

  const TopActionBar({super.key, required this.actions, this.compact = true});

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);
    return Positioned(
      top: ws.s(12),
      left: 0,
      right: 0,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              if (i > 0) SizedBox(width: ws.s(6)),
              compact ? _buildCompactButton(ws, actions[i]) : _buildWideButton(ws, actions[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactButton(WearScale ws, TopAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        height: ws.s(40),
        width: ws.s(40),
        decoration: BoxDecoration(
          color: action.brighter
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(ws.s(20)),
          border: Border.all(
            color: action.brighter
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Center(child: action.child),
      ),
    );
  }

  Widget _buildWideButton(WearScale ws, TopAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        height: ws.s(40),
        constraints: BoxConstraints(minWidth: ws.s(40)),
        padding: EdgeInsets.symmetric(horizontal: ws.s(12)),
        decoration: BoxDecoration(
          color: action.brighter
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(ws.s(20)),
          border: Border.all(
            color: action.brighter
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Center(child: action.child),
      ),
    );
  }
}

/// 顶部操作栏中的单个按钮定义
class TopAction {
  final Widget child;
  final VoidCallback? onTap;
  final bool brighter;

  const TopAction({
    required this.child,
    this.onTap,
    this.brighter = false,
  });
}
