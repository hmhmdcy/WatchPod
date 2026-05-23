class PodcastSubscription {
  final String id;
  final String title;
  final String? author;
  final String? description;
  final String? imageUrl;
  final String feedUrl;
  final DateTime addedAt;
  final List<String> tags;

  PodcastSubscription({
    required this.id,
    required this.title,
    this.author,
    this.description,
    this.imageUrl,
    required this.feedUrl,
    DateTime? addedAt,
    List<String>? tags,
  })  : addedAt = addedAt ?? DateTime.now(),
        tags = tags ?? [];

  PodcastSubscription copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? imageUrl,
    String? feedUrl,
    DateTime? addedAt,
    List<String>? tags,
  }) =>
      PodcastSubscription(
        id: id ?? this.id,
        title: title ?? this.title,
        author: author ?? this.author,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        feedUrl: feedUrl ?? this.feedUrl,
        addedAt: addedAt ?? this.addedAt,
        tags: tags ?? List.from(this.tags),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'description': description,
        'imageUrl': imageUrl,
        'feedUrl': feedUrl,
        'addedAt': addedAt.toIso8601String(),
        'tags': tags,
      };

  factory PodcastSubscription.fromJson(Map<String, dynamic> json) =>
      PodcastSubscription(
        id: json['id'] as String,
        title: json['title'] as String,
        author: json['author'] as String?,
        description: json['description'] as String?,
        imageUrl: json['imageUrl'] as String?,
        feedUrl: json['feedUrl'] as String,
        addedAt: DateTime.tryParse(json['addedAt'] as String? ?? ''),
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      );

  /// 预置标签选项
  static const presetTags = [
    '科技',
    '商业',
    '文化',
    '社会',
    '故事',
    '新闻',
    '教育',
    '生活',
    '音乐',
    '搞笑',
  ];

  /// 基于标题和描述的自动标签推荐（简单规则）
  static List<String> suggestTags(String title, String? description) {
    final text = '$title ${description ?? ''}'.toLowerCase();
    final suggested = <String>[];
    if (text.contains(RegExp(r'科技|技术|ai|编程|代码|tech|digital|互联网'))) {
      suggested.add('科技');
    }
    if (text.contains(RegExp(r'商业|创业|投资|经济|business|startup|market'))) {
      suggested.add('商业');
    }
    if (text.contains(
        RegExp(r'文化|电影|音乐|艺术|文学|books|movie|art|culture'))) {
      suggested.add('文化');
    }
    if (text.contains(RegExp(r'社会|时事|新闻|政治|society|news|politics'))) {
      suggested.add('社会');
    }
    if (text.contains(RegExp(r'故事|故事|story|fm|叙事'))) {
      suggested.add('故事');
    }
    if (text.contains(RegExp(r'教育|学习|课程|课程|edu|learn|知识'))) {
      suggested.add('教育');
    }
    if (text.contains(RegExp(r'生活|健康|美食|旅行|life|health|food|travel'))) {
      suggested.add('生活');
    }
    return suggested;
  }
}
