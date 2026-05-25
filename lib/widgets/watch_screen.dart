import 'package:flutter/material.dart';
import 'glass_components.dart';

/// 圆形手表统一页面骨架
///
/// 自动提供：
/// - 透明 Scaffold（背景色由 [ThemeData.scaffoldBackgroundColor] 控制）
/// - [GlassBackground] 毛玻璃渐变背景
/// - [SafeArea] 包裹内容（可选，默认关闭）
/// - [Stack] + [TopActionBar]（可选）
///
/// 各页面只需关注内容布局，无需重复相同的骨架代码。
///
/// 使用示例：
/// ```dart
/// WatchScreen(
///   actions: [TopAction(icon: Icons.arrow_back, onTap: () => Navigator.pop(context))],
///   safeArea: true,
///   child: Column(children: [
///     SizedBox(height: WearScale.of(context).s(60)),  // 顶部间距（留给 TopActionBar）
///     // ... 页面内容
///   ]),
/// )
/// ```
///
/// 注意：顶部间距（留给 TopActionBar 的空间）仍需各页面自己添加，
/// 因为不同页面可能有不同的间距策略（SizedBox vs Spacer+padding）。
/// 推荐使用 `SizedBox(height: ws.s(60))` 作为统一间距。
class WatchScreen extends StatelessWidget {
  const WatchScreen({
    super.key,
    this.actions,
    this.extendBody = false,
    this.safeArea = false,
    required this.child,
  });

  /// 顶部操作按钮列表，null 或空列表时不显示 TopActionBar
  final List<TopAction>? actions;

  /// 是否启用 extendBodyBehindAppBar
  /// 仅 HomeScreen 等特殊页面需要
  final bool extendBody;

  /// 是否用 SafeArea 包裹内容
  /// 圆形手表建议启用，避免内容被系统状态栏/导航栏遮挡
  final bool safeArea;

  /// 页面主体内容
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (safeArea) {
      content = SafeArea(child: content);
    }

    if (actions != null && actions!.isNotEmpty) {
      content = Stack(
        children: [
          content,
          TopActionBar(actions: actions!),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: extendBody,
      body: GlassBackground(child: content),
    );
  }
}
