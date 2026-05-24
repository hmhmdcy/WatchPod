import 'package:flutter/material.dart';
import 'wear_scale.dart';

/// 添加订阅页底部信息栏
/// 显示：订阅数量 + 存储空间使用情况
class SettingsInfoBar extends StatelessWidget {
  final int subscriptionCount;
  final Future<String> storageInfoFuture;

  const SettingsInfoBar({
    super.key,
    required this.subscriptionCount,
    required this.storageInfoFuture,
  });

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);
    final borderRadius = ws.s(18);

    return Container(
      height: ws.s(44),
      margin: EdgeInsets.only(bottom: ws.s(8)),
      child: FutureBuilder<String>(
        future: storageInfoFuture,
        builder: (ctx, snapshot) {
          final storageInfo = snapshot.data ?? '计算中...';
          return Center(
            child: Container(
              constraints: BoxConstraints(minWidth: ws.s(160)),
              padding: EdgeInsets.symmetric(
                  horizontal: ws.s(14), vertical: ws.s(7)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.subscriptions,
                      size: ws.s(14),
                      color: const Color(0xFF6C63FF)),
                  SizedBox(width: ws.s(4)),
                  Text('$subscriptionCount 个订阅',
                      style: TextStyle(
                          fontSize: ws.sp(10), color: Colors.white70)),
                  Container(
                    width: 1,
                    height: ws.s(14),
                    margin: EdgeInsets.symmetric(horizontal: ws.s(8)),
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  Icon(Icons.storage,
                      size: ws.s(14),
                      color: const Color(0xFF6C63FF)),
                  SizedBox(width: ws.s(4)),
                  Text('$storageInfo',
                      style: TextStyle(
                          fontSize: ws.sp(10), color: Colors.white70)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
