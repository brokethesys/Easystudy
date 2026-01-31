import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/game_state.dart';
import 'quiz_screen.dart';
import '../widgets/top_hud.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  // =======================
  // Constants
  // =======================
  static const int totalLevels = 25;
  static const double nodeSize = 75.0;
  static const double stepY = 100.0;
  static const double topPadding = 120.0;
  static const double bottomPadding = 100.0;

  // =======================
  // Controllers
  // =======================
  late final AnimationController _xpController;
  late Animation<double> _xpAnimation;
  late final ScrollController _scrollController;

  // Для анимации нажатия
  final Map<int, AnimationController> _tapControllers = {};
  final Map<int, Animation<double>> _tapAnimations = {};

  double _previousXpRatio = 0.0;

  @override
  void initState() {
    super.initState();

    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _xpAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _xpController, curve: Curves.easeOutCubic),
    );

    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _xpController.dispose();
    _scrollController.dispose();
    // Диспос всех контроллеров нажатия
    for (final controller in _tapControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final state = context.watch<GameState>();
    final newRatio = state.currentXP / state.xpForNextLevel;

    if (newRatio != _previousXpRatio) {
      _animateXp(newRatio);
    }
  }

  // =======================
  // XP animation
  // =======================
  void _animateXp(double targetRatio) {
    _xpAnimation =
        Tween<double>(begin: _previousXpRatio, end: targetRatio).animate(
          CurvedAnimation(parent: _xpController, curve: Curves.easeOutCubic),
        )..addListener(() {
          setState(() {});
        });

    _xpController.forward(from: 0);
    _previousXpRatio = targetRatio;
  }

  // =======================
  // Tap animation methods
  // =======================
  void _initializeTapController(int levelNumber) {
    if (_tapControllers.containsKey(levelNumber)) return;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    final animation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );

    _tapControllers[levelNumber] = controller;
    _tapAnimations[levelNumber] = animation;
  }

  void _onTapDown(int levelNumber) {
    _initializeTapController(levelNumber);
    final controller = _tapControllers[levelNumber]!;
    controller.forward(from: 0);
  }

  void _onTapUp(int levelNumber) {
    final controller = _tapControllers[levelNumber];
    if (controller != null) {
      controller.reverse();
    }
  }

  // =======================
  // Map layout
  // =======================
  List<Offset> _calculateLevelPositions(Size screenSize, double mapHeight) {
    final centerX = screenSize.width / 2;
    final rand = Random(42);

    double currentY = mapHeight - bottomPadding;

    return List.generate(totalLevels, (index) {
      if (index != 0) currentY -= stepY;

      final xOffset = index == 0
          ? 0.0
          : sin(index * 1.3) * 60 + (rand.nextDouble() * 10 - 5);

      return Offset(centerX + xOffset - nodeSize / 2, currentY);
    });
  }

  List<Widget> _buildLevelNodes(
    BuildContext context,
    GameState state,
    List<Offset> positions,
  ) {
    return List.generate(positions.length, (index) {
      final levelNumber = index + 1;
      final pos = positions[index];

      final isCompleted =
          state.completedLevels[state.currentSubject]?.contains(levelNumber) ??
              false;

      final isCurrent = levelNumber == state.currentLevel;
      final isLocked = levelNumber > state.currentLevel;

      return Positioned(
        top: pos.dy,
        left: pos.dx,
        child: _LevelNode(
          levelNumber: levelNumber,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          isLocked: isLocked,
          nodeSize: nodeSize, // Передаем константу как параметр
          onTapDown: () => _onTapDown(levelNumber),
          onTapUp: () => _onTapUp(levelNumber),
          onTap: () async {
            if (isLocked) return;

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuizScreen(ticketId: levelNumber),
              ),
            );

            if (result == true) {
              state.completeLevel(levelNumber);
              state.addXP(50);
              _animateXp(state.currentXP / state.xpForNextLevel);
            }
          },
        ),
      );
    });
  }

  // =======================
  // Build
  // =======================
  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    final hudHeight = 48 + 16; // Высота TopHUD + отступ
    final safeZoneHeight = hudHeight;

    final mapHeight = topPadding + bottomPadding + (totalLevels - 1) * stepY;
    final totalHeight = mapHeight + safeZoneHeight + padding.top;

    final positions = _calculateLevelPositions(size, mapHeight);

    return Scaffold(
      backgroundColor: const Color(0xFF131F24),
      body: Stack(
        children: [
          // Заливка над safe area (статус бар и т.д.)
          Positioned.fill(
            child: Container(
              color: const Color(0xFF131F24),
            ),
          ),
          
          SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  reverse: true,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    height: totalHeight,
                    child: Stack(
                      children: [
                        // Фоновая заливка сверху (скрывает часть карты над HUD)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: safeZoneHeight.toDouble(),
                          child: Container(
                            color: const Color(0xFF131F24),
                          ),
                        ),
                        
                        // Карта с уровнями
                        Positioned(
                          top: safeZoneHeight.toDouble(),
                          left: 0,
                          right: 0,
                          child: SizedBox(
                            height: mapHeight,
                            child: Stack(
                              children: _buildLevelNodes(context, state, positions),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // TopHUD поверх всего
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: TopHUD(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =======================
// Painter
// =======================
class _LevelCirclePainter extends CustomPainter {
  final double progress;
  final Color circleColor;
  final Color backgroundColor;

  _LevelCirclePainter({
    required this.progress,
    required this.circleColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..color = circleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LevelCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// =======================
// Level Node
// =======================
class _LevelNode extends StatefulWidget {
  final int levelNumber;
  final bool isCompleted;
  final bool isLocked;
  final bool isCurrent;
  final double nodeSize; // Добавляем параметр для размера
  final VoidCallback onTap;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  const _LevelNode({
    required this.levelNumber,
    required this.isCompleted,
    required this.isLocked,
    required this.isCurrent,
    required this.nodeSize,
    required this.onTap,
    required this.onTapDown,
    required this.onTapUp,
  });

  @override
  State<_LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<_LevelNode> with TickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.85),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.0),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _tapController,
        curve: Curves.easeInOut,
      ),
    );

    _shadowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _tapController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    widget.onTapDown();
    _tapController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    widget.onTapUp();
    _tapController.reverse();
  }

  void _handleTapCancel() {
    widget.onTapUp();
    _tapController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final String asset = widget.isLocked
        ? 'assets/images/icon_level_closed-f.png'
        : widget.isCompleted
        ? 'assets/images/icon_level_complited-f.png'
        : 'assets/images/icon_current_level-pink.png';

    return GestureDetector(
      onTapDown: widget.isLocked ? null : _handleTapDown,
      onTapUp: widget.isLocked ? null : _handleTapUp,
      onTapCancel: widget.isLocked ? null : _handleTapCancel,
      onTap: widget.isLocked ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _tapController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              children: [
                // Основная иконка
                SizedBox(
                  width: widget.nodeSize, // Используем переданный размер
                  height: widget.nodeSize, // Используем переданный размер
                  child: Image.asset(asset, fit: BoxFit.contain),
                ),
                // Эффект вдавливания (тень сверху)
                if (_shadowAnimation.value > 0)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 1.2,
                          colors: [
                            Colors.black.withOpacity(0.3 * _shadowAnimation.value),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}