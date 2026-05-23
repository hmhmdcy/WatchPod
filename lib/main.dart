import 'package:flutter/material.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'services/rss_service.dart';
import 'screens/home_screen.dart';

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
      home: HomeScreen(
        audioService: audioService,
        storageService: storageService,
        rssService: rssService,
      ),
    );
  }
}
