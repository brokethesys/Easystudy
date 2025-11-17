import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/game_state.dart';
import 'quiz_screen.dart';
import '../widgets/settings_panel.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _xpController;
  late Animation<double> _xpAnimation;
  late final ScrollController _scrollController;

  double _previousXpRatio = 0.0;
  bool showSubjectPicker = false;
  Subject currentSubject = Subject.math;

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
    currentSubject = state.currentSubject;
    _updateXpAnimation(state.currentXP / state.xpForNextLevel);
  }

  void _updateXpAnimation(double newRatio) {
    _xpAnimation =
        Tween<double>(begin: _previousXpRatio, end: newRatio).animate(
          CurvedAnimation(parent: _xpController, curve: Curves.easeOutCubic),
        )..addListener(() {
          setState(() {});
        });
    _xpController.forward(from: 0);
    _previousXpRatio = newRatio;
  }

  List<Offset> _calculateLevelCenters(Size screenSize, double mapHeight) {
    const int totalLevels = 25;
    const double stepY = 100.0;
    const double widgetWidth = 75.0;

    final double centerX = screenSize.width / 2;
    const double bottomPadding = 100.0;
    final rand = Random(42);

    return List.generate(totalLevels, (i) {
      final double y = mapHeight - bottomPadding - i * stepY;
      double x;
      if (i == 0) {
        x = centerX;
      } else {
        x = centerX + sin(i * 1.3) * 60 + (rand.nextDouble() * 10 - 5);
      }
      return Offset(x - widgetWidth / 2, y);
    });
  }

  List<Widget> _buildLevelNodes(
    BuildContext context,
    GameState state,
    List<Offset> centers,
  ) {
    const double nodeSize = 75.0;

    return List.generate(centers.length, (i) {
      final c = centers[i];
      final levelNumber = i + 1;

      final isCompleted =
          state.completedLevels[state.currentSubject]?.contains(levelNumber) ??
          false;
      final isCurrent = levelNumber == state.currentLevel;
      final isLocked = levelNumber > state.currentLevel;

      return Positioned(
        top: c.dy,
        left: c.dx,
        child: _LevelNode(
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
              _updateXpAnimation(state.currentXP / state.xpForNextLevel);
            }
          },
        ),
      );
    });
  }

  // === Верхняя панель с круговым индикатором уровня + выбор предмета ===
  Widget _topHUD(BuildContext context, GameState state) {
    final double widgetHeight = 48.0; // высота круга и виджета предметов
    final Color switchColor = const Color(0xFF49C0F7);
    final Color backgroundColor = const Color(0xFF131F24);

    return Positioned(
      top: 40,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Круг с уровнем
          CustomPaint(
            painter: _LevelCirclePainter(
              progress: _xpAnimation.value,
              circleColor: switchColor,
              backgroundColor: const Color(0xFF073E57),
            ),
            child: SizedBox(
              width: widgetHeight,
              height: widgetHeight,
              child: Center(
                child: Text(
                  '${state.playerLevel}',
                  style: const TextStyle(
                    fontFamily: 'ClashRoyale',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Виджет выбора предмета
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showSubjectPicker = !showSubjectPicker;
                    });
                  },
                  child: Container(
                    height: widgetHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: switchColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _subjectName(currentSubject),
                      style: TextStyle(
                        fontFamily: 'ClashRoyale',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: backgroundColor,
                      ),
                    ),
                  ),
                ),
                if (showSubjectPicker)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: switchColor, width: 2),
                    ),
                    child: Column(
                      children: [
                        for (var subj in Subject.values)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                currentSubject = subj;
                                showSubjectPicker = false;
                              });
                              state.switchSubject(subj);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 8,
                              ),
                              child: Text(
                                _subjectName(subj),
                                style: TextStyle(
                                  fontFamily: 'ClashRoyale',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: switchColor,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Монеты и баланс
          Row(
            children: [
              SizedBox(
                width: widgetHeight,
                height: widgetHeight,
                child: Image.asset('assets/images/coin.png'),
              ),
              const SizedBox(width: 6),
              Text(
                state.coins.toString(),
                style: const TextStyle(
                  fontFamily: 'ClashRoyale',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.amber,
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Кнопка настроек
          SizedBox(
            width: widgetHeight,
            height: widgetHeight,
            child: GestureDetector(
              onTap: () => SettingsPanel.open(context),
              child: Icon(
                Icons.settings,
                color: Colors.orangeAccent,
                size: widgetHeight * 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _subjectName(Subject subj) {
    switch (subj) {
      case Subject.chemistry:
        return "ХИМИЯ";
      case Subject.math:
        return "МАТЕМАТИКА";
      case Subject.english:
        return "АНГЛИЙСКИЙ ЯЗЫК";
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final size = MediaQuery.of(context).size;

    const int totalLevels = 25;
    const double stepY = 100.0;
    const double topPadding = 120.0;
    const double bottomPadding = 100.0;

    final double mapHeight =
        topPadding + bottomPadding + (totalLevels - 1) * stepY;

    final centers = _calculateLevelCenters(size, mapHeight);
    final nodes = _buildLevelNodes(context, state, centers);

    return Scaffold(
      backgroundColor: const Color(0xFF131F24),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            reverse: true,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              height: mapHeight,
              child: Stack(children: nodes),
            ),
          ),
          _topHUD(context, state),
        ],
      ),
    );
  }
}

// Painter для кругового индикатора
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

    double startAngle = -pi / 2;
    double sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LevelCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// LevelNode
class _LevelNode extends StatelessWidget {
  final bool isCompleted;
  final bool isLocked;
  final bool isCurrent;
  final VoidCallback onTap;

  const _LevelNode({
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
        : isCurrent
        ? 'assets/images/icon_current_level-pink.png'
        : 'assets/images/icon_current_level-pink.png';

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: SizedBox(
        width: 75,
        height: 75,
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );
  }
}
