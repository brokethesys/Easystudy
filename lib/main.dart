import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'data/game_state.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/map_screen.dart';
import 'theme/app_theme.dart';

final ValueNotifier<String> currentBackground = ValueNotifier<String>('blue');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Загружаем GameState и проверяем первый запуск
  final gameState = await GameState.load();
  final firstLaunch = await GameState.isFirstLaunch();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<GameState>.value(value: gameState),
      ],
      child: MyApp(showWelcomeScreen: firstLaunch),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool showWelcomeScreen;
  const MyApp({super.key, required this.showWelcomeScreen});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: currentBackground,
      builder: (context, background, _) {
        final gameState = context.watch<GameState>();
        const Color darkBackground = Color(0xFF121F25);

        final ThemeMode mode = () {
          switch (gameState.themeMode) {
            case AppThemeMode.light:
              return ThemeMode.light;
            case AppThemeMode.dark:
              return ThemeMode.dark;
            case AppThemeMode.system:
            default:
              return ThemeMode.system;
          }
        }();

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(background: darkBackground),
          themeMode: mode,
          initialRoute: showWelcomeScreen ? '/welcome' : '/home',
          routes: {
            '/welcome': (context) => const WelcomeScreen(),
            '/home': (context) => const HomeScreen(),
            '/map': (context) => const MapScreen(),
          },
        );
      },
    );
  }
}
