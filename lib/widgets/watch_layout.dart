import 'package:flutter/material.dart';
import 'glass_components.dart';
import 'watch_safe_area.dart';
import 'wear_scale.dart';

/// 统一手表布局 — 双分区模式
///
/// 将页面分为两个区域：
///   1. 内容区（可滑动） — 用 [contentBuilder] 提供
///   2. 底部操作栏（固定） — 用 [actions] 或 [actionBar] 提供
///
/// 所有尺寸通过 [WearScale] 自适应，适配 360×360 ~ 466×466 屏幕。
class WatchLayout extends StatelessWidget {
  final String? title;
  final bool showBack;
  final Widget Function(BuildContext context, BoxConstraints constraints)
      contentBuilder;
  final List<WatchAction>? actions;
  final Widget? actionBar;
  final List<Widget>? appBarActions;
  final bool showAppBar;
  final bool useGlassBackground;
  final bool showActionGradient;

  const WatchLayout({
    super.key,
    this.title,
    this.showBack = true,
    required this.contentBuilder,
    this.actions,
    this.actionBar,
    this.appBarActions,
    this.showAppBar = true,
    this.useGlassBackground = true,
    this.showActionGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: showAppBar ? _buildAppBar(context) : null,
      body: PopScope(
        canPop: true,
        child: useGlassBackground
          ? GlassBackground(
              child: LayoutBuilder(
                builder: (context, constraints) =>
                    _buildBody(context, constraints),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) =>
                  _buildBody(context, constraints),
            ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final ws = WearScale.of(context);
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBack)
            Padding(
              padding: EdgeInsets.only(right: ws.s(8)),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back, size: ws.s(18), color: Colors.white70),
              ),
            ),
          if (title != null)
            Text(
              title!,
              style: TextStyle(
                fontSize: ws.fs(14),
                fontWeight: FontWeight.bold,
              ),
            ),
          if (appBarActions != null && appBarActions!.isNotEmpty)
            ...appBarActions!.map((action) => Padding(
              padding: EdgeInsets.only(left: ws.s(8)),
              child: action,
            )),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, BoxConstraints constraints) {
    final hasActions =
        (actions != null && actions!.isNotEmpty) || actionBar != null;
    final ws = WearScale.of(context);
    final actionBarHeight = ws.s(48);

    return Column(
      children: [
        Expanded(
          child: WatchSafeArea(
            child: SingleChildScrollView(
              child: contentBuilder(context, constraints),
            ),
          ),
        ),
        if (hasActions)
          Container(
            height: actionBarHeight + ws.s(8),
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              gradient: showActionGradient
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1A1A2E).withValues(alpha: 0.0),
                        const Color(0xFF1A1A2E).withValues(alpha: 0.95),
                      ],
                    )
                  : null,
              color: showActionGradient
                  ? null
                  : const Color(0xFF1A1A2E).withValues(alpha: 0.95),
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: ws.s(4)),
              child: actionBar ?? _buildActionRow(context),
            ),
          ),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context) {
    if (actions == null || actions!.isEmpty) return const SizedBox.shrink();
    final ws = WearScale.of(context);

    return Row(
      children: actions!.map((action) {
        final isLast = action == actions!.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: ws.s(4),
              right: isLast ? ws.s(4) : ws.s(2),
              bottom: ws.s(4),
            ),
            child: GestureDetector(
              onTap: action.onTap,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: ws.s(8)),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(ws.s(12)),
                  border: Border.all(
                    color: action.color.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (action.icon != null) ...[
                      Icon(action.icon, size: ws.s(14), color: action.color),
                      SizedBox(width: ws.s(4)),
                    ],
                    Text(
                      action.label,
                      style: TextStyle(
                        fontSize: ws.sp(11),
                        color: action.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 底部操作栏的单个按钮定义
class WatchAction {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;

  const WatchAction({
    required this.label,
    this.icon,
    this.color = Colors.white,
    this.onTap,
  });
}

/// 简单的滚动列表布局 — 适用于节目列表页、播客列表页
class WatchScrollContent extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final Widget? emptyWidget;

  const WatchScrollContent({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0 && emptyWidget != null) {
      return Center(child: emptyWidget!);
    }

    final ws = WearScale.of(context);
    return ListView.builder(
      padding: padding ?? EdgeInsets.only(top: ws.s(4), bottom: ws.s(4)),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
