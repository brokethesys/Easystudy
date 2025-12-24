import 'dart:async'; // Добавьте этот импорт
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/game_state.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
// Глобальное значение текущего выбранного фона.
final ValueNotifier<String> currentBackground = ValueNotifier<String>('blue');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // БЫСТРЫЙ запуск - минимум задержек
  runApp(const AppLoader());
}

class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GameState>(
      future: _loadGameState(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Показываем ОЧЕНЬ БЫСТРЫЙ загрузочный экран
          return _LoadingScreen();
        }
        
        if (snapshot.hasData) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<GameState>.value(value: snapshot.data!),
            ],
            child: const MyApp(),
          );
        }
        
        // Если ошибка - всё равно показываем приложение
        return const MyApp();
      },
    );
  }
  
  Future<GameState> _loadGameState() async {
    // Минимальная задержка чтобы увидеть загрузочный экран
    await Future.delayed(const Duration(milliseconds: 800));
    return await GameState.load();
  }
}

class _LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Центральный логотип
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF58A700),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 80,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
            
            // Нижняя полоса прогресса (анимированная)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    _AnimatedProgressBar(),
                    const SizedBox(height: 10),
                    _ProgressPercentage(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedProgressBar extends StatefulWidget {
  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.8 * _animation.value,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF58A700),
                      Color(0xFF8BC34A),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressPercentage extends StatefulWidget {
  @override
  State<_ProgressPercentage> createState() => _ProgressPercentageState();
}

class _ProgressPercentageState extends State<_ProgressPercentage> {
  int _percent = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (mounted) {
        setState(() {
          _percent = (_percent + 2) % 101;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      "$_percent%",
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF001B33),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}