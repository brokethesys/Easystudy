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
          onTap: () async {
            if (isLocked) return;

            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QuizScreen(level: levelNumber)),
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

    final safeZoneHeight = MediaQuery.of(context).padding.top + 48 + 16;

    final mapHeight = topPadding + bottomPadding + (totalLevels - 1) * stepY;

    final positions = _calculateLevelPositions(size, mapHeight);

    return Scaffold(
      backgroundColor: const Color(0xFF131F24),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            reverse: true,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              height: mapHeight + safeZoneHeight,
              child: Stack(
                children: [
                  Positioned(
                    top: safeZoneHeight,
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
          const TopHUD(),
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
class _LevelNode extends StatelessWidget {
  final int levelNumber;
  final bool isCompleted;
  final bool isLocked;
  final bool isCurrent;
  final VoidCallback onTap;

  const _LevelNode({
    required this.levelNumber,
    required this.isCompleted,
    required this.isLocked,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String asset = isLocked
        ? 'assets/images/icon_level_closed-f.png'
        : isCompleted
        ? 'assets/images/icon_level_complited-f.png'
        : 'assets/images/icon_current_level-pink.png';

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: SizedBox(
        width: _MapScreenState.nodeSize,
        height: _MapScreenState.nodeSize,
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );
  }
}
