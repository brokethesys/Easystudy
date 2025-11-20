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
    final double widgetHeight = 48.0;
    final Color switchColor = const Color(0xFF49C0F7);
    final Color backgroundColor = const Color(0xFF131F24);

    return Positioned(
      top: 0, // фон идёт от самого верха
      left: 0,
      right: 0,
      child: Container(
        color: backgroundColor, // фон до верха экрана
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 48 + 40, // высота HUD + верхний отступ
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Круг уровня
                Padding(
                  padding: const EdgeInsets.only(
                    top: 40,
                  ), // сохраняем позицию HUD
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

                // Кнопка предмета (иконка)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: _subjectButton(widgetHeight),
                ),

                // Монеты и баланс
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
                          fontSize: 20,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),

                // Кнопка настроек
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
                        size: widgetHeight * 0.6,
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

  void _openTheorySheet(
    BuildContext context,
    int blockNumber,
    String blockTitle,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _TheorySheet(blockNumber: blockNumber, blockTitle: blockTitle);
      },
    );
  }

  // Виджет выбора предмета заменён на иконку с выезжающим меню
  // Метод для верхней кнопки предмета (только иконка)
  Widget _subjectButton(double widgetHeight) {
    return GestureDetector(
      onTap: () {
        setState(() {
          showSubjectPicker = !showSubjectPicker;
        });
      },
      child: SizedBox(
        width: widgetHeight,
        height: widgetHeight,
        child: Image.asset(_subjectIcon(currentSubject)),
      ),
    );
  }

  // Выпадающее горизонтальное меню предметов
  Widget _subjectMenu(GameState state, double widgetHeight) {
    if (!showSubjectPicker) return const SizedBox.shrink();

    return Positioned(
      top: widgetHeight + 48, // чуть ниже верхнего меню
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: const Color(0xFF131F24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: Subject.values.map((subj) {
            final bool isCurrent = subj == currentSubject;
            return GestureDetector(
              onTap: () {
                setState(() {
                  currentSubject = subj;
                  showSubjectPicker = false;
                });
                state.switchSubject(subj);
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: isCurrent
                    ? BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF49C0F7),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Image.asset(
                  _subjectIcon(subj),
                  width: widgetHeight * 0.7,
                  height: widgetHeight * 0.7,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Метод возвращает путь к иконке предмета
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

  // === Блок информации о разделе и теме ===
  Widget _chapterBlock(GameState state) {
    final double hudHeight = 40 + 48; // top padding + HUD + небольшой отступ
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

    return Positioned(
      top: hudHeight,
      left: 0,
      right: 0,
      child: Container(
        color: const Color(0xFF131F24), // фон карты под блоком
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: GestureDetector(
          onTap: () => _openTheorySheet(context, blockNumber, blockTitle),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFCA74C7),
              borderRadius: BorderRadius.circular(16),
              border: const Border(
                bottom: BorderSide(color: Color(0xFF6E276B), width: 6),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
    final double safeZoneHeight =
        40 + 48 + 90 + 16; // top padding + HUD + chapter block + отступ
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
              height:
                  mapHeight +
                  safeZoneHeight, // добавляем сверху безопасную зону
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
          _topHUD(context, state),
          _chapterBlock(state),
          _subjectMenu(state, 48),
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
              // Верхний бар со стрелкой
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
