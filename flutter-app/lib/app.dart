import 'package:cotune_mobile/screens/profile_screen.dart';
import 'package:cotune_mobile/services/p2p_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'services/storage_service.dart';
import 'services/audio_player_service.dart';
import 'screens/search_screen.dart';
import 'screens/my_music_screen.dart';
import 'widgets/mini_player.dart';
import 'widgets/bottom_nav.dart';

class AppSettings extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  String _locale = 'ru';

  ThemeMode get themeMode => _mode;
  String get locale => _locale;

  void setThemeMode(ThemeMode m) {
    _mode = m;
    notifyListeners();
  }

  void setLocale(String l) {
    _locale = l;
    notifyListeners();
  }
}

class CotuneApp extends StatelessWidget {
  const CotuneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StorageService()),
        Provider(create: (_) => AudioPlayerService()),
        ChangeNotifierProvider(create: (_) => AppSettings()),
        Provider(
          create: (_) {
            final p2p = P2PService();
            return p2p;
          },
        ),
      ],
      child: Consumer<AppSettings>(
        builder: (context, appSettings, _) {
          return MaterialApp(
            title: 'CoTune',
            theme: CotuneTheme.lightTheme(),
            darkTheme: CotuneTheme.darkTheme(),
            debugShowCheckedModeBanner: false,
            themeMode: appSettings.themeMode,
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 1;

  final _pages = const [
    SearchScreen(),
    MyMusicScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      body: IndexedStack(
        index: _index,
        children: _pages,
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(), // или MiniPlayerModern()
            const SizedBox(height: 0),
            BottomNav(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
            ),
          ],
        ),
      ),
    );
  }
}

