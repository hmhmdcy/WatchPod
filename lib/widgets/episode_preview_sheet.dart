import 'package:flutter/material.dart';
import '../models/episode.dart';
import '../models/podcast_subscription.dart';
import '../services/top_podcast_service.dart';
import '../widgets/wear_scale.dart';

/// 热门播客节目预览弹窗
/// 显示播客信息 + 最新 10 个节目列表 + 订阅按钮
void showEpisodePreview(
  BuildContext context, {
  required TopPodcastItem item,
  required PodcastSubscription podcast,
  required List<Episode> episodes,
  required Future<void> Function(String feedUrl) onSubscribe,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1A2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (ctx) {
      final ws = WearScale.of(ctx);
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) {
          return Padding(
            padding: EdgeInsets.all(ws.s(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 播客信息头部
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(ws.s(10)),
                      child: Image.network(
                        item.coverUrl,
                        width: ws.s(40),
                        height: ws.s(40),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: ws.s(40),
                          height: ws.s(40),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(ws.s(10)),
                          ),
                          child: const Icon(Icons.podcasts,
                              size: 20, color: Colors.grey),
                        ),
                      ),
                    ),
                    SizedBox(width: ws.s(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: TextStyle(
                                  fontSize: ws.sp(13),
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(item.author,
                              style: TextStyle(
                                  fontSize: ws.sp(10),
                                  color: Colors.grey[400]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        onSubscribe(item.feedUrl!);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: ws.s(12), vertical: ws.s(6)),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(ws.s(14)),
                        ),
                        child: Text('订阅',
                            style: TextStyle(
                                fontSize: ws.sp(11),
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ws.s(8)),
                Text(
                  item.summary.isNotEmpty ? item.summary : '暂无描述',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: ws.sp(10), color: Colors.grey[500]),
                ),
                SizedBox(height: ws.s(10)),
                Divider(color: Colors.white.withValues(alpha: 0.08)),
                SizedBox(height: ws.s(4)),
                Text('最新节目 (${episodes.length})',
                    style: TextStyle(
                        fontSize: ws.sp(11),
                        color: Colors.grey,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: ws.s(6)),
                Expanded(
                  child: episodes.isEmpty
                      ? Center(
                          child: Text('暂无节目',
                              style: TextStyle(
                                  fontSize: ws.sp(12),
                                  color: Colors.grey[600])))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount:
                              episodes.length > 10 ? 10 : episodes.length,
                          itemBuilder: (ctx, i) {
                            final ep = episodes[i];
                            return Container(
                              margin: EdgeInsets.only(bottom: ws.s(4)),
                              padding: EdgeInsets.all(ws.s(8)),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius:
                                    BorderRadius.circular(ws.s(8)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(ws.s(4)),
                                    child: Image.network(
                                      ep.imageUrl ?? item.coverUrl,
                                      width: ws.s(24),
                                      height: ws.s(24),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(
                                        width: ws.s(24),
                                        height: ws.s(24),
                                        color: Colors.white
                                            .withValues(alpha: 0.05),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: ws.s(6)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(ep.title,
                                            style: TextStyle(
                                                fontSize: ws.sp(10),
                                                color: Colors.white),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                        if (ep.duration != null)
                                          Text(ep.formattedDuration,
                                              style: TextStyle(
                                                  fontSize: ws.sp(8),
                                                  color: Colors.grey[600])),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
