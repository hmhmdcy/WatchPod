import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'services/rss_service.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/episodes_screen.dart';
import 'screens/player_screen.dart';
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
      home: kIsWeb
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
class _WebDebugShell extends StatefulWidget {
  final AudioService audioService;
  final StorageService storageService;
  final RssService rssService;

  const _WebDebugShell({
    required this.audioService,
    required this.storageService,
    required this.rssService,
  });

  @override
  State<_WebDebugShell> createState() => _WebDebugShellState();
}

class _WebDebugShellState extends State<_WebDebugShell> {
  int _currentPage = 0;

  static final _mockPodcast = PodcastSubscription(
    id: 'mock-1',
    title: '科技早知道',
    author: '硅谷徐老师',
    feedUrl: 'https://example.com/feed1.xml',
    imageUrl: 'https://picsum.photos/seed/pod1/200/200',
    tags: ['科技', '中文'],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
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
        ],
      ),
    );
  }

  Widget _navBtn(int index, String label) {
    final active = _currentPage == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentPage = index),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: active ? const Color(0xFF6C63FF) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active ? const Color(0xFF6C63FF) : Colors.white54,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
