import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/game_state.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/map_screen.dart';

final ValueNotifier<String> currentBackground = ValueNotifier<String>('blue');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppLoader());
}

class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadGameStateAndCheckFirstLaunch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Пока загружается SharedPreferences, показываем пустой контейнер
          return const SizedBox.shrink();
        }

        final bool firstLaunch = snapshot.data!['firstLaunch'] as bool;
        final GameState gameState = snapshot.data!['gameState'] as GameState;

        return MultiProvider(
          providers: [
            ChangeNotifierProvider<GameState>.value(value: gameState),
          ],
          child: MyApp(showWelcomeScreen: firstLaunch),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadGameStateAndCheckFirstLaunch() async {
    final gameState = await GameState.load();
    final firstLaunch = await GameState.isFirstLaunch();
    return {'gameState': gameState, 'firstLaunch': firstLaunch};
  }
}

class MyApp extends StatelessWidget {
  final bool showWelcomeScreen;
  const MyApp({super.key, required this.showWelcomeScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF001B33),
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
  }
}
