import 'dart:math';
import 'package:flutter/material.dart';

/// Clips content to a circular shape for round smartwatch screens.
/// Provides safe padding so content doesn't get cut off at corners.
class WatchSafeArea extends StatelessWidget {
  final Widget child;
  final double padding;

  const WatchSafeArea({super.key, required this.child, this.padding = 8.0});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final radius =
          min(constraints.maxWidth, constraints.maxHeight) / 2 - padding;
      return ClipRRect(
        borderRadius: BorderRadius.circular(constraints.maxWidth / 2),
        child: Padding(
          padding: EdgeInsets.all(padding + (radius * 0.12)),
          child: child,
        ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: size * 0.45),
            if (label != null)
              Text(label!,
                  style: TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
