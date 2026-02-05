import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../audio/audio_manager.dart';
import '../data/game_state.dart';
import '../theme/app_theme.dart';
import 'achievements_screen.dart';
import 'map_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /* =======================
     CONSTANTS
     ======================= */

  static const int _initialPage = 1;
  static const int _pageCount = 3;

  /* =======================
     STATE
     ======================= */

  late final PageController _pageController = PageController(
    initialPage: _initialPage,
  );

  int _currentPage = _initialPage;
  bool _isUserSwipe = false;

  /* =======================
     LIFECYCLE
     ======================= */

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /* =======================
     NAVIGATION
     ======================= */

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    if (_isUserSwipe) {
      AudioManager().playSwipeSound();
    }
  }

  void _navigateToPage(int index) {
    if (index == _currentPage) return;

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /* =======================
     UI
     ======================= */

  @override
  Widget build(BuildContext context) {
    // Подписка нужна, чтобы HomeScreen корректно реагировал
    // на изменения глобального состояния (например, валюты)
    context.watch<GameState>();
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification &&
              notification.dragDetails != null) {
            _isUserSwipe = true;
          } else if (notification is ScrollEndNotification) {
            _isUserSwipe = false;
          }
          return false;
        },
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: const [ShopScreen(), MapScreen(), AchievementsScreen()],
        ),
      ),
      bottomNavigationBar: _BottomNavigationBar(
        currentIndex: _currentPage,
        onTap: _navigateToPage,
      ),
    );
  }
}

/* =======================
   BOTTOM NAV BAR
   ======================= */

class _BottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavigationBar({required this.currentIndex, required this.onTap});

  static const _icons = [
    'assets/images/icons/icon_shop.png',
    'assets/images/icons/icon_map.png',
    'assets/images/icons/icon_achievements.png',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          top: BorderSide(color: colors.track, width: 1.5),
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
        children: List.generate(_icons.length, (index) {
          return Expanded(
            child: _BottomNavItem(
              iconPath: _icons[index],
              isActive: index == currentIndex,
              onTap: () => onTap(index),
            ),
          );
        }),
      ),
    );
  }
}

/* =======================
   BOTTOM NAV ITEM
   ======================= */

class _BottomNavItem extends StatefulWidget {
  final String iconPath;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.iconPath,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<_BottomNavItem> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Center(
        child: AnimatedContainer(
          width: 56,
          height: 56,
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.translationValues(0, _isPressed ? 4 : 0, 0),
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: widget.isActive
                ? Border.all(color: colors.accent, width: 2)
                : null,
          ),
          child: Center(
            child: Image.asset(widget.iconPath, width: 32, height: 32),
          ),
        ),
      ),
    );
  }
}
