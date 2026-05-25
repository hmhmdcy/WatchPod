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
      home: (kIsWeb || Platform.isLinux)
          ? _WebDebugShell(
              audioService: audioService,
              storageService: storageService,
              rssService: rssService,
            )
          : HomeScreen(
              audioService: audioService,
              storageService: storageService,
              rssService: rssService,
            ),
    );
  }
}

/// Web 调试外壳：底部导航切换四个页面，方便视觉检查
/// Linux Desktop 调试外壳：固定 466×466 圆形窗口模拟 Huawei Watch 3
class _WebDebugShell extends StatelessWidget {
  final AudioService audioService;
  final StorageService storageService;
  final RssService rssService;

  const _WebDebugShell({
    required this.audioService,
    required this.storageService,
    required this.rssService,
  });

  static const double watchSize = 466;

  @override
  Widget build(BuildContext context) {
    final clipRadius = watchSize / 2;

    return Scaffold(
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(clipRadius),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: const Size(watchSize, watchSize),
            ),
            child: SizedBox(
              width: watchSize,
              height: watchSize,
              child: _LinuxDebugPages(
                initialPage: 1,
                audioService: audioService,
                storageService: storageService,
                rssService: rssService,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Linux Desktop 四页导航：Home / Episodes / Player / Settings / TagPicker
class _LinuxDebugPages extends StatefulWidget {
  final AudioService audioService;
  final StorageService storageService;
  final RssService rssService;
  final int initialPage;

  const _LinuxDebugPages({
    required this.audioService,
    required this.storageService,
    required this.rssService,
    this.initialPage = 0,  // 默认 HomeScreen（主页）
  });

  @override
  State<_LinuxDebugPages> createState() => _LinuxDebugPagesState();
}

class _LinuxDebugPagesState extends State<_LinuxDebugPages> {
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
        // TagPickerPage — 公开类，可直接引用
        TagPickerPage(
          podcast: _mockPodcastWithTags,
          suggested: _mockPodcastWithTags.tags,
        ),
      ],
    );
  }
}
