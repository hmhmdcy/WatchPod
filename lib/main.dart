import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'services/rss_service.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/episodes_screen.dart';
import 'screens/player_screen.dart';
import 'screens/tag_picker_page.dart';
import 'models/podcast_subscription.dart';
import 'models/episode.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final audioService = AudioService();
  final storageService = StorageService();
  final rssService = RssService();

  runApp(WatchPodApp(
    audioService: audioService,
    storageService: storageService,
    rssService: rssService,
  ));
}

class WatchPodApp extends StatelessWidget {
  final AudioService audioService;
  final StorageService storageService;
  final RssService rssService;

  const WatchPodApp({
    super.key,
    required this.audioService,
    required this.storageService,
    required this.rssService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WatchPod',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF7C4DFF),
          surface: Color(0x1AFFFFFF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontSize: 14),
          bodyMedium: TextStyle(color: Colors.white, fontSize: 12),
          bodySmall: TextStyle(color: Colors.white70, fontSize: 10),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: const Color(0xFF6C63FF),
          inactiveTrackColor: Colors.white24,
          thumbColor: const Color(0xFF6C63FF),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          trackHeight: 3,
        ),
      ),
      /// 全局 builder：统一所有路由的圆形裁剪 + 固定尺寸
      /// 调试模式（Web / Linux Desktop）：ClipRRect 圆形 + 466×466
      /// 生产模式（Android）：透传，不影响真机
      builder: _circularScreenBuilder,
      home: _HomePage(
        audioService: audioService,
        storageService: storageService,
        rssService: rssService,
      ),
    );
  }

  /// 所有路由共享的圆形屏幕裁剪
  /// MaterialApp.builder 包裹 Navigator 的所有页面（home + push 路由）
  Widget _circularScreenBuilder(BuildContext context, Widget? child) {
    if (kIsWeb || Platform.isLinux) {
      const watchSize = 466.0;
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(watchSize / 2),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: const Size(watchSize, watchSize),
            ),
            child: SizedBox(
              width: watchSize,
              height: watchSize,
              child: child,
            ),
          ),
        ),
      );
    }
    return child!;
  }
}

/// 主页选择器
/// - 调试模式（Web / Linux Desktop）：IndexedStack 多页切换
/// - 生产模式（Android）：直接 HomeScreen
class _HomePage extends StatelessWidget {
  final AudioService audioService;
  final StorageService storageService;
  final RssService rssService;

  const _HomePage({
    required this.audioService,
    required this.storageService,
    required this.rssService,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || Platform.isLinux) {
      return _DebugPages(
        initialPage: 0,
        audioService: audioService,
        storageService: storageService,
        rssService: rssService,
      );
    }
    return HomeScreen(
      audioService: audioService,
      storageService: storageService,
      rssService: rssService,
    );
  }
}

/// Linux Desktop / Web 多页调试容器
/// IndexedStack 切换 5 个页面：Home / Episodes / Player / Settings / TagPicker
class _DebugPages extends StatefulWidget {
  final AudioService audioService;
  final StorageService storageService;
  final RssService rssService;
  final int initialPage;

  const _DebugPages({
    required this.audioService,
    required this.storageService,
    required this.rssService,
    this.initialPage = 0,
  });

  @override
  State<_DebugPages> createState() => _DebugPagesState();
}

class _DebugPagesState extends State<_DebugPages> {
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
  }

  static final _mockPodcast = PodcastSubscription(
    id: 'mock-1',
    title: '科技早知道',
    author: '硅谷徐老师',
    feedUrl: 'https://example.com/feed1.xml',
    imageUrl: 'https://picsum.photos/seed/pod1/200/200',
    tags: ['科技', '中文'],
  );

  static final _mockPodcastWithTags = PodcastSubscription(
    id: 'mock-2',
    title: '商业就是这样',
    feedUrl: 'https://example.com/feed2.xml',
    author: '商业团队',
    imageUrl: 'https://picsum.photos/seed/pod2/200/200',
    tags: ['商业', '投资'],
  );

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentPage,
      children: [
        HomeScreen(
          audioService: widget.audioService,
          storageService: widget.storageService,
          rssService: widget.rssService,
        ),
        EpisodesScreen(
          podcast: _mockPodcast,
          audioService: widget.audioService,
          storageService: widget.storageService,
          rssService: widget.rssService,
        ),
        PlayerScreen(audioService: widget.audioService),
        SettingsScreen(storageService: widget.storageService),
        TagPickerPage(
          podcast: _mockPodcastWithTags,
          suggested: _mockPodcastWithTags.tags,
        ),
      ],
    );
  }
}
