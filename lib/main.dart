import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/game_state.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/map_screen.dart';

final ValueNotifier<String> currentBackground = ValueNotifier<String>('blue');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        Color scaffoldColor = const Color(0xFF001B33);
        if (background == 'white') {
          scaffoldColor = Colors.white;
        } else if (background == 'blue') {
          scaffoldColor = const Color(0xFF001B33);
        } else if (background == 'dark') {
          scaffoldColor = const Color(0xFF131F24);
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: scaffoldColor,
            fontFamily: 'Roboto',
            useMaterial3: true,
          ),
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
