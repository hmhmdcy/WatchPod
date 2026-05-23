class Episode {
  final String id;
  final String podcastId;
  final String title;
  final String? description;
  final String? audioUrl;
  final String? imageUrl;
  final Duration? duration;
  final DateTime? publishedAt;
  final bool isDownloaded;
  final String? localPath;
  final Duration? playbackPosition;

  Episode({
    required this.id,
    required this.podcastId,
    required this.title,
    this.description,
    this.audioUrl,
    this.imageUrl,
    this.duration,
    this.publishedAt,
    this.isDownloaded = false,
    this.localPath,
    this.playbackPosition,
  });

  Episode copyWith({
    String? id,
    String? podcastId,
    String? title,
    String? description,
    String? audioUrl,
    String? imageUrl,
    Duration? duration,
    DateTime? publishedAt,
    bool? isDownloaded,
    String? localPath,
    Duration? playbackPosition,
  }) =>
      Episode(
        id: id ?? this.id,
        podcastId: podcastId ?? this.podcastId,
        title: title ?? this.title,
        description: description ?? this.description,
        audioUrl: audioUrl ?? this.audioUrl,
        imageUrl: imageUrl ?? this.imageUrl,
        duration: duration ?? this.duration,
        publishedAt: publishedAt ?? this.publishedAt,
        isDownloaded: isDownloaded ?? this.isDownloaded,
        localPath: localPath ?? this.localPath,
        playbackPosition: playbackPosition ?? this.playbackPosition,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'podcastId': podcastId,
        'title': title,
        'description': description,
        'audioUrl': audioUrl,
        'imageUrl': imageUrl,
        'durationMs': duration?.inMilliseconds,
        'publishedAt': publishedAt?.toIso8601String(),
        'isDownloaded': isDownloaded,
        'localPath': localPath,
        'playbackPositionMs': playbackPosition?.inMilliseconds,
      };

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
        id: json['id'] as String,
        podcastId: json['podcastId'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        audioUrl: json['audioUrl'] as String?,
        imageUrl: json['imageUrl'] as String?,
        duration: json['durationMs'] != null
            ? Duration(milliseconds: json['durationMs'] as int)
            : null,
        publishedAt: json['publishedAt'] != null
            ? DateTime.tryParse(json['publishedAt'] as String)
            : null,
        isDownloaded: json['isDownloaded'] as bool? ?? false,
        localPath: json['localPath'] as String?,
        playbackPosition: json['playbackPositionMs'] != null
            ? Duration(milliseconds: json['playbackPositionMs'] as int)
            : null,
      );

  String get formattedDuration {
    if (duration == null) return '';
    final h = duration!.inHours;
    final m = duration!.inMinutes.remainder(60);
    final s = duration!.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, "0")}m';
    return '${m}:${s.toString().padLeft(2, "0")}';
  }
}
