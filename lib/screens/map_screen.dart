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

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late AnimationController _xpController;
  late Animation<double> _xpAnimation;

  late AnimationController _subjectController;
  late Animation<double> _subjectAnimation;

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

    _subjectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _subjectAnimation = CurvedAnimation(
      parent: _subjectController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _xpController.dispose();
    _scrollController.dispose();
    _subjectController.dispose();
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

  // ======= Верхняя панель HUD =======
  Widget _topHUD(BuildContext context, GameState state) {
    final double widgetHeight = 34.0;
    final Color switchColor = const Color(0xFF49C0F7);
    final Color backgroundColor = const Color(0xFF131F24);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 48 + 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Круг опыта
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: CustomPaint(
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
                ),

                // Кнопка предмета
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: _subjectButton(widgetHeight),
                ),

                // Монеты
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Row(
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
                ),

                // Настройки
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: SizedBox(
                    width: widgetHeight,
                    height: widgetHeight,
                    child: GestureDetector(
                      onTap: () => SettingsPanel.open(context),
                      child: Icon(
                        Icons.settings,
                        color: Colors.orangeAccent,
                        size: widgetHeight * 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== Кнопка предмета =====
  Widget _subjectButton(double widgetHeight) {
    return GestureDetector(
      onTap: () {
        setState(() {
          showSubjectPicker = !showSubjectPicker;
          if (showSubjectPicker) {
            _subjectController.forward();
          } else {
            _subjectController.reverse();
          }
        });
      },
      child: SizedBox(
        width: widgetHeight,
        height: widgetHeight,
        child: Image.asset(_subjectIcon(currentSubject)),
      ),
    );
  }

  // ===== Выпадающее меню предметов =====
  // ===== Выпадающее меню предметов =====
  Widget _subjectMenu(GameState state, double widgetHeight) {
    final double hudHeight = 48 + 40; // высота HUD
    final double menuHeight =
        120.0; // увеличенная высота, чтобы покрывало chapter block

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !showSubjectPicker,
        child: AnimatedBuilder(
          animation: _subjectController,
          builder: (context, _) {
            // Slide из-под HUD
            final offset = Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(_subjectAnimation).value;

            return Stack(
              children: [
                // затемнённый фон с плавным исчезновением
                Opacity(
                  opacity: _subjectAnimation.value * 0.5,
                  child: GestureDetector(
                    onTap: () {
                      _subjectController.reverse().then((_) {
                        setState(() => showSubjectPicker = false);
                      });
                    },
                    child: Container(color: Colors.black),
                  ),
                ),
                // само меню
                Positioned(
                  top: hudHeight + offset.dy * menuHeight,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {}, // нажатия по меню не закрывают его
                    child: Container(
                      height: menuHeight,
                      color: const Color(0xFF131F24),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: Subject.values.map((subj) {
                          final bool isCurrent = subj == currentSubject;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                currentSubject = subj;
                              });
                              state.switchSubject(subj);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: isCurrent
                                  ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Color(0xFF49C0F7),
                                        width: 2,
                                      ),
                                    )
                                  : null,
                              child: Image.asset(
                                _subjectIcon(subj),
                                width: widgetHeight * 1,
                                height: widgetHeight * 1,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                // линия между HUD и меню
                Positioned(
                  top: hudHeight - 1,
                  left: 0,
                  right: 0,
                  child: Container(height: 1, color: Colors.white24),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _subjectIcon(Subject subj) {
    switch (subj) {
      case Subject.chemistry:
        return 'assets/images/icon_chemistry.png';
      case Subject.math:
        return 'assets/images/icon_math.png';
      case Subject.english:
        return 'assets/images/icon_english.png';
    }
  }

  // ===== Блок информации о разделе и теме =====
  Widget _chapterBlock(GameState state) {
    final double hudHeight = 40 + 48;
    final int currentLevel = state.currentLevel;
    final int blockNumber = ((currentLevel - 1) ~/ 5) + 1;

    const List<String> blockTitles = [
      "Основы темы",
      "Продвинутые задания",
      "Сложные примеры",
      "Практика применения",
      "Контрольный блок",
    ];

    final String blockTitle =
        blockTitles[(blockNumber - 1) % blockTitles.length];

    bool isPressed = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Stack(
          children: [
            // Фон под блоком от HUD до самой кнопки
            Positioned(
              top: hudHeight,
              left: 0,
              right: 0,
              height: hudHeight, // 90 — высота блока
              child: Container(color: const Color(0xFF131F24)),
            ),

            // Сам блок
            Positioned(
              top: hudHeight,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTapDown: (_) => setState(() => isPressed = true),
                onTapUp: (_) {
                  setState(() => isPressed = false);
                  _openTheorySheet(context, blockNumber, blockTitle);
                },
                onTapCancel: () => setState(() => isPressed = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  transform: Matrix4.translationValues(0, isPressed ? 4 : 0, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFCA74C7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border(
                        bottom: isPressed
                            ? BorderSide.none
                            : const BorderSide(
                                color: Color(0xFF6E276B),
                                width: 6,
                              ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "РАЗДЕЛ 1, БЛОК $blockNumber",
                          style: const TextStyle(
                            fontFamily: "ClashRoyale",
                            fontSize: 13,
                            letterSpacing: 1.2,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          blockTitle,
                          style: const TextStyle(
                            fontFamily: "ClashRoyale",
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openTheorySheet(
    BuildContext context,
    int blockNumber,
    String blockTitle,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _TheorySheet(blockNumber: blockNumber, blockTitle: blockTitle);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final size = MediaQuery.of(context).size;

    const int totalLevels = 25;
    const double stepY = 100.0;
    const double topPadding = 120.0;
    const double bottomPadding = 100.0;
    final double safeZoneHeight = 40 + 48 + 90 + 16;
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
              height: mapHeight + safeZoneHeight,
              child: Stack(
                children: [
                  Positioned(
                    top: safeZoneHeight,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: mapHeight,
                      child: Stack(children: nodes),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _chapterBlock(state),
          _subjectMenu(state, 48),
          _topHUD(context, state),
        ],
      ),
    );
  }
}

// ===== Painter для круга опыта =====
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

// ===== Node уровня =====
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

// ===== Теория для блока =====
class _TheorySheet extends StatelessWidget {
  final int blockNumber;
  final String blockTitle;

  const _TheorySheet({required this.blockNumber, required this.blockTitle});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 0.4,
      maxChildSize: 1.0,
      expand: true,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF131F24),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 40,
                  bottom: 12,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Блок $blockNumber — $blockTitle",
                      style: const TextStyle(
                        fontFamily: "ClashRoyale",
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    """
ЗДЕСЬ БУДЕТ ТЕОРИЯ ПО БЛОКУ.

Ты можешь вставить сюда большой текст или даже сверстанный материал:
— Формулы
— Определения
— Примеры
— Иллюстрации
и всё, что нужно ученику.

Текст автоматически скроллится отдельно от панели.
""",
                    style: TextStyle(
                      fontFamily: "ClashRoyale",
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
