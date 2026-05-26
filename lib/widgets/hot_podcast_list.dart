import 'package:flutter/material.dart';
import '../services/top_podcast_service.dart';
import '../widgets/wear_scale.dart';

/// 热门播客列表组件
/// 包含：标题 → 加载中/错误/列表三种状态
/// 每个条目：封面(36dp) + 名称(14sp) + 作者(11sp) + 订阅按钮(40dp)
class HotPodcastList extends StatelessWidget {
  final List<TopPodcastItem> items;
  final bool loading;
  final String? error;
  final String? subscribeError;
  final bool showTitle;
  final void Function(TopPodcastItem item)? onItemTap;
  final void Function(String feedUrl)? onSubscribe;
  final void Function(TopPodcastItem item)? onPreview;

  const HotPodcastList({
    super.key,
    required this.items,
    this.loading = false,
    this.error,
    this.subscribeError,
    this.showTitle = false,
    this.onItemTap,
    this.onSubscribe,
    this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final ws = WearScale.of(context);

    return Column(
      children: [
        // 错误提示（渐变透明 + 居中）— 浮在列表上方，不参与滚动
        if (subscribeError != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ws.s(8))
                .copyWith(bottom: ws.s(4)),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: ws.s(12), vertical: ws.s(3)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.red.withValues(alpha: 0.08),
                      Colors.red.withValues(alpha: 0.02),
                      Colors.red.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(ws.s(8)),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                ),
                child: Text(subscribeError!,
                    style: TextStyle(
                        fontSize: ws.sp(9), color: Colors.red.withValues(alpha: 0.9))),
              ),
            ),
          ),
        // 内容区：loading/error 占满，或列表（标题+卡片一起滚动）
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: ws.s(8)),
            child: loading && items.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white54))
                : error != null && items.isEmpty
                    ? Center(
                        child: Text(error!,
                            style: TextStyle(
                                fontSize: ws.sp(10), color: Colors.orange)))
                    : ListView(
                        children: [
                          // 标题 — 作为列表头部，随列表滚动
                          if (showTitle)
                            Padding(
                              padding:
                                  EdgeInsets.only(top: ws.s(4), bottom: ws.s(8)),
                              child: SizedBox(
                                width: double.infinity,
                                child: Text('🔥 苹果热门播客',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: ws.sp(13),
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          // 列表卡片
                          ...items.map((item) =>
                              _buildItem(context, ws, item)),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, WearScale ws, TopPodcastItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: ws.s(8)),
      padding: EdgeInsets.all(ws.s(14)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(ws.s(14)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          // 点击封面/文字 → 预览节目
          Expanded(
            child: GestureDetector(
              onTap: () => onItemTap?.call(item),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(ws.s(10)),
                    child: Image.network(
                      item.coverUrl,
                      width: ws.s(42),
                      height: ws.s(42),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: ws.s(42),
                        height: ws.s(42),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(ws.s(10)),
                        ),
                        child: Icon(Icons.podcasts,
                            size: ws.s(22), color: Colors.grey),
                      ),
                    ),
                  ),
                  SizedBox(width: ws.s(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: TextStyle(
                                fontSize: ws.sp(15),
                                color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (item.author.isNotEmpty)
                          Text(item.author,
                              style: TextStyle(
                                  fontSize: ws.sp(12),
                                  color: Colors.grey[500]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: ws.s(8)),
          // 右侧订阅按钮
          if (item.feedUrl == null)
            SizedBox(
              width: ws.s(22),
              height: ws.s(22),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white24,
              ),
            )
          else
            GestureDetector(
              onTap: () => onSubscribe?.call(item.feedUrl!),
              child: Container(
                width: ws.s(34),
                height: ws.s(34),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(ws.s(17)),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(Icons.add,
                    color: const Color(0xFF6C63FF), size: ws.s(18)),
              ),
            ),
        ],
      ),
    );
  }
}
