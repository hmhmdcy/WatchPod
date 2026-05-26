import 'dart:math';
import 'package:flutter/material.dart';
import 'wear_scale.dart';

/// Adaptive padding via [WearScale]: smaller relative padding on large screens.
/// NOTE: The circular screen clipping is now handled globally by MaterialApp.builder (ClipRRect).
/// This widget only provides adaptive padding — it does NOT clip.
class WatchSafeArea extends StatelessWidget {
  final Widget child;
  final double padding;

  const WatchSafeArea({super.key, required this.child, this.padding = 6.0});

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);
    final safePadding = ws.s(padding); // use passed padding
    return LayoutBuilder(builder: (context, constraints) {
      final radius =
          min(constraints.maxWidth, constraints.maxHeight) / 2 - safePadding;
      return Padding(
        padding: EdgeInsets.all(safePadding + (radius * 0.06)),
        child: child,
      );
    });
  }
}

/// A large touch-friendly button optimized for watch screens
class WatchButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final double size;

  const WatchButton({
    super.key,
    required this.icon,
    this.label,
    this.onTap,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);
    final btnSize = ws.s(size);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: btnSize,
        height: btnSize,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: btnSize * 0.45),
            if (label != null)
              Text(
                label!,
                style: TextStyle(fontSize: ws.sp(10), color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }
}
