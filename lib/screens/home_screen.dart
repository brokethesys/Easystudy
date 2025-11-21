import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/game_state.dart';
import 'map_screen.dart';
import 'shop_screen.dart';
import 'achievements_screen.dart';
import 'profile_screen.dart';        // ← добавлено
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(initialPage: 1);
  int _currentPage = 1;
  double _indicatorPosition = 1.0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _indicatorPosition = ((_pageController.page ?? _currentPage)
                .clamp(0.0, 3.0))
            .toDouble();
      });
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  void _onBottomNavTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<GameState>();

    const icons = [
      Icons.person,           // Профиль ← новая кнопка
      Icons.shop,             // Магазин
      Icons.map_rounded,      // Уровни
      Icons.workspace_premium // Достижения
    ];

    const labels = [
      'Профиль',
      'Магазин',
      'Уровни',
      'Достижения',
    ];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 67, 91, 112),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          ProfileScreen(),     // ← новая 4-я страница
          ShopScreen(),
          MapScreen(),
          AchievementsScreen()
        ],
      ),
      bottomNavigationBar: _buildBottomBar(icons, labels),
    );
  }

  Widget _buildBottomBar(List<IconData> icons, List<String> labels) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: const Color(0xFF131E22),
        border: const Border(
          top: BorderSide(color: Color(0xFF37464F), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: List.generate(4, (i) {        // ← было 3, стало 4
          final bool active = _currentPage == i;
          bool isPressed = false;

          return Expanded(
            child: StatefulBuilder(
              builder: (context, setState) {
                return GestureDetector(
                  onTapDown: (_) => setState(() => isPressed = true),
                  onTapUp: (_) {
                    setState(() => isPressed = false);
                    HapticFeedback.lightImpact();
                    _onBottomNavTap(i);
                  },
                  onTapCancel: () => setState(() => isPressed = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    transform: Matrix4.translationValues(
                      0,
                      isPressed ? 4 : 0,
                      0,
                    ),
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131F24),
                      border: active
                          ? Border.all(color: const Color(0xFF3C85A7), width: 2)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        icons[i],
                        size: 32,
                        color: active ? Colors.white : Colors.white70,
                        shadows: active
                            ? const [Shadow(
                                  color: Colors.black,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}