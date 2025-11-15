import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/game_state.dart';
import 'map_screen.dart';
import 'shop_screen.dart';
import 'achievements_screen.dart';
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
        _indicatorPosition = ((_pageController.page ?? _currentPage).clamp(
          0.0,
          2.0,
        )).toDouble();
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

    const icons = [Icons.shop, Icons.map_rounded, Icons.workspace_premium];
    const labels = ['Магазин', 'Уровни', 'Достижения'];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 67, 91, 112),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [ShopScreen(), MapScreen(), AchievementsScreen()],
      ),
      bottomNavigationBar: _buildBottomBar(icons, labels),
    );
  }

  Widget _buildBottomBar(List<IconData> icons, List<String> labels) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: const Color(0xFF131F24), // фон как у достижений
        border: Border(
          top: BorderSide(
            color: const Color(0xFF37464F),
            width: 1.5,
          ), // обводка сверху
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
        children: List.generate(3, (i) {
          final bool active = _currentPage == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _onBottomNavTap(i);
              },
              child: Container(
                margin: const EdgeInsets.all(
                  8,
                ), // отступ, чтобы выглядел квадратом
                decoration: BoxDecoration(
                  color: const Color(0xFF131F24), // фон квадрата
                  border: active
                      ? Border.all(
                          color: const Color(
                            0xFF3C85A7,
                          ), // рамка текущего экрана
                          width: 2,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    icons[i],
                    size: 32,
                    color: active ? Colors.white : Colors.white70,
                    shadows: active
                        ? [
                            const Shadow(
                              color: Colors.black,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
