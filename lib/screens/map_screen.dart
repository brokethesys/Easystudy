import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/settings_panel.dart';
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
  static const double _stepY = 120;
  static const double _topPadding = 120;
  static const double _bottomPadding = 140;
  static const String _accountPromptShownKey = 'account_prompt_level1_shown';

  /* =======================
     CONTROLLERS
     ======================= */

  late final ScrollController _scrollController;
  late final AnimationController _xpController;
  late Animation<double> _xpAnimation;

  double _lastXpRatio = 0;
  final Map<int, int> _ticketQuestionCounts = {};
  bool _accountPromptScheduled = false;

  /* =======================
     LIFECYCLE
     ======================= */

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _loadTicketQuestionCounts();

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

  Future<void> _loadTicketQuestionCounts() async {
    final String response = await rootBundle.loadString(
      'assets/questions/software_engineering.json',
    );
    final data = json.decode(response);
    final tickets = (data['tickets'] as List).cast<Map<String, dynamic>>();
    for (final ticket in tickets) {
      final id = ticket['id'] as int?;
      final subquestions = ticket['subquestions'] as List?;
      if (id != null && subquestions != null) {
        _ticketQuestionCounts[id] = subquestions.length;
      }
    }
    if (mounted) {
      setState(() {});
    }
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
    final colors = AppColors.of(context);
    _updateXp(state);
    _scheduleAccountPrompt(state);

    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    const hudHeight = 64.0;
    final mapHeight =
        _topPadding + _bottomPadding + (_totalLevels - 1) * _stepY;
    final totalHeight = mapHeight + hudHeight + padding.top;

    final positions = _calculatePositions(size, mapHeight);

    return Scaffold(
      backgroundColor: colors.background,
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
      final totalQuestions = _ticketQuestionCounts[level] ?? 0;
      final progress = state.getTicketProgress(state.currentSubject, level);
      final List<bool?> questionStatuses = List.generate(totalQuestions, (i) {
        if (progress?.answeredQuestions.containsKey(i) ?? false) {
          return progress?.answeredQuestions[i] ?? false;
        }
        return null;
      });
      int? pulseIndex;
      if (isCurrent) {
        for (int i = 0; i < questionStatuses.length; i++) {
          if (questionStatuses[i] != true) {
            pulseIndex = i;
            break;
          }
        }
      }

      final nodeScale = isCurrent ? 1.3 : 1.0;
      final adjustedLeft = pos.dx - (_nodeSize * (nodeScale - 1) / 2);

      return Positioned(
        top: pos.dy,
        left: adjustedLeft,
        child: LevelNode(
          level: level,
          size: _nodeSize,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          isLocked: isLocked,
          questionStatuses: questionStatuses,
          pulseIndex: pulseIndex,
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

  void _scheduleAccountPrompt(GameState state) {
    if (_accountPromptScheduled) return;
    final completed =
        state.completedLevels[state.currentSubject]?.contains(1) ?? false;
    if (!completed) return;
    _accountPromptScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        _maybeShowAccountPrompt(context);
      }
    });
  }

  Future<void> _maybeShowAccountPrompt(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool(_accountPromptShownKey) ?? false;
    if (alreadyShown) return;
    await prefs.setBool(_accountPromptShownKey, true);
    if (!context.mounted) return;
    await _showAccountPromptDialog(context);
  }

  Future<void> _showAccountPromptDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131F24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Синхронизировать прогресс?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Создайте аккаунт, чтобы продолжать с любого устройства.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'ПОЗЖЕ',
                style: TextStyle(
                  color: Color(0xFF49C0F7),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await SettingsPanel.openAccountDialog(context);
              },
              child: const Text(
                'ВОЙТИ / РЕГИСТРАЦИЯ',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
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
  final List<bool?> questionStatuses;
  final int? pulseIndex;
  final VoidCallback onTap;

  const LevelNode({
    super.key,
    required this.level,
    required this.size,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLocked,
    required this.questionStatuses,
    required this.pulseIndex,
    required this.onTap,
  });

  @override
  State<LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<LevelNode>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.9, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.pulseIndex != null) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LevelNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulseIndex == null) {
      _pulseController.stop();
      _pulseController.value = 0;
    } else if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
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

  Color _statusColor(bool? status) {
    if (status == true) return const Color(0xFF58A700);
    if (status == false) return const Color(0xFFD32F2F);
    return const Color(0xFF6D7B85);
  }

  Widget _buildQuestionDots() {
    if (widget.questionStatuses.isEmpty) return const SizedBox.shrink();

    final dotScale = widget.isCurrent ? 1.3 : 1.0;
    final dotSize = 8 * dotScale;

    return SizedBox(
      width: widget.size * (widget.isCurrent ? 1.3 : 1.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: List.generate(widget.questionStatuses.length, (index) {
          final color = _statusColor(widget.questionStatuses[index]);
          final dot = Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          );

          if (widget.pulseIndex == index) {
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Opacity(
                opacity: _pulseOpacity.value,
                child: Transform.scale(
                  scale: _pulseScale.value,
                  child: dot,
                ),
              ),
            );
          }

          return dot;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nodeScale = widget.isCurrent ? 1.3 : 1.0;
    final nodeSize = widget.size * nodeScale;

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildQuestionDots(),
                const SizedBox(height: 6),
                SizedBox(
                  width: nodeSize,
                  height: nodeSize,
                  child: Image.asset(_asset),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
