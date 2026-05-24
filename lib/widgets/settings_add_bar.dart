import 'package:flutter/material.dart';
import 'wear_scale.dart';

/// 添加订阅页顶部操作栏 — 添加订阅按钮 + 刷新按钮
/// 两按钮均为毛玻璃样式。compact=true 时按钮更小（适配顶部单行布局）
class SettingsAddBar extends StatelessWidget {
  final bool isLoading;
  final bool isAdding;
  final VoidCallback? onAddTap;
  final VoidCallback? onRefreshTap;
  final double borderRadius;
  final bool compact;

  const SettingsAddBar({
    super.key,
    this.isLoading = false,
    this.isAdding = false,
    this.onAddTap,
    this.onRefreshTap,
    required this.borderRadius,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);

    if (compact) return _buildCompact(ws);
    return _buildDefault(ws);
  }

  Widget _buildCompact(WearScale ws) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: isAdding ? null : onAddTap,
            child: Container(
              height: ws.s(30),
              padding: EdgeInsets.symmetric(horizontal: ws.s(10)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAdding)
                    SizedBox(
                      width: ws.s(12),
                      height: ws.s(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  else
                    Icon(Icons.add, color: Colors.white, size: ws.s(14)),
                  SizedBox(width: ws.s(4)),
                  Text(
                    isAdding ? '添加中' : '添加订阅',
                    style: TextStyle(
                      fontSize: ws.sp(11),
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: ws.s(6)),
          GestureDetector(
            onTap: isLoading ? null : onRefreshTap,
            child: Container(
              width: ws.s(30),
              height: ws.s(30),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: ws.s(12),
                        height: ws.s(12),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white54),
                      )
                    : Icon(Icons.refresh,
                        color: Colors.white70, size: ws.s(15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefault(WearScale ws) {
    return Container(
      height: ws.s(46),
      margin: EdgeInsets.only(top: ws.s(4)),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: isAdding ? null : onAddTap,
              child: Container(
                constraints: BoxConstraints(minWidth: ws.s(100)),
                padding: EdgeInsets.symmetric(
                    horizontal: ws.s(14), vertical: ws.s(8)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isAdding)
                      SizedBox(
                        width: ws.s(16),
                        height: ws.s(16),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    else
                      Icon(Icons.add, color: Colors.white, size: ws.s(16)),
                    SizedBox(width: ws.s(6)),
                    Text(
                      isAdding ? '添加中' : '添加订阅',
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
            SizedBox(width: ws.s(8)),
            GestureDetector(
              onTap: isLoading ? null : onRefreshTap,
              child: Container(
                width: ws.s(36),
                height: ws.s(36),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: ws.s(16),
                          height: ws.s(16),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white54),
                        )
                      : Icon(Icons.refresh,
                          color: Colors.white70, size: ws.s(18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
