import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/game_state.dart';
import '../widgets/top_hud.dart';
import 'quiz_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  /* =======================
     CONSTANTS
     ======================= */

  static const int _totalLevels = 25;
  static const double _nodeSize = 75;
  static const double _stepY = 100;
  static const double _topPadding = 120;
  static const double _bottomPadding = 100;

  /* =======================
     CONTROLLERS
     ======================= */

  late final ScrollController _scrollController;
  late final AnimationController _xpController;
  late Animation<double> _xpAnimation;

  double _lastXpRatio = 0;

  /* =======================
     LIFECYCLE
     ======================= */

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _xpAnimation = const AlwaysStoppedAnimation(0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  /* =======================
     XP ANIMATION
     ======================= */

  void _updateXp(GameState state) {
    final ratio = state.currentXP / state.xpForNextLevel;
    if (ratio == _lastXpRatio) return;

    _xpAnimation = Tween<double>(begin: _lastXpRatio, end: ratio).animate(
      CurvedAnimation(parent: _xpController, curve: Curves.easeOutCubic),
    )..addListener(() => setState(() {}));

    _xpController.forward(from: 0);
    _lastXpRatio = ratio;
  }

  /* =======================
     MAP GEOMETRY
     ======================= */

  List<Offset> _calculatePositions(Size size, double mapHeight) {
    final centerX = size.width / 2;
    final rand = Random(42);

    double y = mapHeight - _bottomPadding;

    return List.generate(_totalLevels, (index) {
      if (index != 0) y -= _stepY;

      final xOffset = index == 0
          ? 0
          : sin(index * 1.3) * 60 + rand.nextDouble() * 10 - 5;

      return Offset(centerX + xOffset - _nodeSize / 2, y);
    });
  }

  /* =======================
     BUILD
     ======================= */

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    _updateXp(state);

    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    const hudHeight = 64.0;
    final mapHeight =
        _topPadding + _bottomPadding + (_totalLevels - 1) * _stepY;
    final totalHeight = mapHeight + hudHeight + padding.top;

    final positions = _calculatePositions(size, mapHeight);

    return Scaffold(
      backgroundColor: const Color(0xFF131F24),
      body: SafeArea(
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
                    Positioned(
                      top: hudHeight,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: mapHeight,
                        child: Stack(
                          children: _buildNodes(context, state, positions),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(top: 0, left: 0, right: 0, child: TopHUD()),
          ],
        ),
      ),
    );
  }

  /* =======================
     LEVEL NODES
     ======================= */

  List<Widget> _buildNodes(
    BuildContext context,
    GameState state,
    List<Offset> positions,
  ) {
    return List.generate(positions.length, (index) {
      final level = index + 1;
      final pos = positions[index];

      final isCompleted =
          state.completedLevels[state.currentSubject]?.contains(level) ?? false;
      final isCurrent = level == state.currentLevel;
      final isLocked = level > state.currentLevel;

      return Positioned(
        top: pos.dy,
        left: pos.dx,
        child: LevelNode(
          level: level,
          size: _nodeSize,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          isLocked: isLocked,
          onTap: () async {
            if (isLocked) return;

            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QuizScreen(ticketId: level)),
            );

            if (result == true) {
              state.completeLevel(level);
              state.addXP(50);
            }
          },
        ),
      );
    });
  }
}

/* =======================
   LEVEL NODE
   ======================= */

class LevelNode extends StatefulWidget {
  final int level;
  final double size;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLocked;
  final VoidCallback onTap;

  const LevelNode({
    super.key,
    required this.level,
    required this.size,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLocked,
    required this.onTap,
  });

  @override
  State<LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<LevelNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scale = Tween<double>(
      begin: 1,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _asset {
    if (widget.isLocked) {
      return 'assets/images/icon_level_closed-f.png';
    }
    if (widget.isCompleted) {
      return 'assets/images/icon_level_complited-f.png';
    }
    return 'assets/images/icon_current_level-pink.png';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLocked ? null : (_) => _controller.forward(),
      onTapUp: widget.isLocked ? null : (_) => _controller.reverse(),
      onTapCancel: widget.isLocked ? null : _controller.reverse,
      onTap: widget.isLocked ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Transform.scale(
            scale: _scale.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Image.asset(_asset),
            ),
          );
        },
      ),
    );
  }
}
