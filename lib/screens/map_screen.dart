import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/game_state.dart';
import 'quiz_screen.dart';
import '../widgets/settings_panel.dart';
import '../data/api_service.dart';

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
  int _visibleBlockIndex = 0;

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
    _scrollController.addListener(_onScroll);

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

  void _onScroll() {
    const double stepY = 100.0;
    const double topPadding = 120.0;
    const double safeZoneHeight = 40 + 48 + 90 + 16;

    final offset = _scrollController.offset;

    // уровень, который сейчас примерно по центру экрана
    final levelIndex = ((offset + safeZoneHeight - topPadding) / stepY).floor();

    final clampedLevel = levelIndex.clamp(0, 24);
    final blockIndex = clampedLevel ~/ 6;

    if (blockIndex != _visibleBlockIndex) {
      setState(() {
        _visibleBlockIndex = blockIndex;
      });
    }
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

    double currentY = mapHeight - bottomPadding;

    return List.generate(totalLevels, (i) {
      // === шаг по Y ===
      double localStep = stepY;

      // если это ПЕРВЫЙ уровень нового блока (7, 13, 19...)
      if (i > 0 && i % 6 == 0) {
        localStep = stepY * 2; // увеличенный шаг
      }

      if (i != 0) {
        currentY -= localStep;
      }

      // === синусоида по X ===
      double x;
      if (i == 0) {
        x = centerX;
      } else {
        x = centerX + sin(i * 1.3) * 60 + (rand.nextDouble() * 10 - 5);
      }

      return Offset(x - widgetWidth / 2, currentY);
    });
  }

  List<Widget> _buildLevelNodes(
    BuildContext context,
    GameState state,
    List<Offset> centers,
    Size screenSize,
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
              _updateXpAnimation(state.currentXP / state.xpForNextLevel);
            }
          },
        ),
      );
    });
  }

  List<Widget> _buildBlockSeparators(Size screenSize, List<Offset> centers) {
    final List<Widget> separators = [];

    for (int i = 6; i < centers.length; i += 6) {
      final blockIndex = i ~/ 6 + 1;

      final double y = (centers[i - 1].dy + centers[i].dy) / 2 + 24;

      separators.add(
        Positioned(
          top: y,
          left: 0,
          right: 0,
          child: Center(
            child: _BlockSeparator(
              title: "Блок $blockIndex",
              width: screenSize.width * 0.9,
            ),
          ),
        ),
      );
    }

    return separators;
  }

  // ======= Верхняя панель HUD =======
  Widget _topHUD(BuildContext context, GameState state) {
    final double widgetHeight = 40.0;
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
                          fontSize: 22,
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
                // тонкая разделительная линия между HUD и меню
                if (_subjectAnimation.value > 0)
                  Positioned(
                    top: hudHeight,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: _subjectAnimation.value,
                      child: Container(height: 1, color: Color(0xFF37464F)),
                    ),
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
      case Subject.history:
        return 'assets/images/icon_history.png';
    }
  }

  // ===== Блок информации о разделе и теме =====
  // ===== Блок информации о разделе и теме =====
  Widget _chapterBlock(GameState state) {
    final double hudHeight = 40 + 48;
    final int blockNumber = _visibleBlockIndex + 1;
    final style = blockStyles[_visibleBlockIndex % blockStyles.length];

    final Color blockLight = style["light"];
    final Color blockDark = style["dark"];

    // Уникальные названия блоков для каждого предмета
    String getBlockTitle(Subject subject, int blockNumber) {
      final index = (blockNumber - 1) % 5; // Циклически повторяем по 5 блоков

      switch (subject) {
        case Subject.math:
          final mathTitles = [
            "Линейная алгебра",
            "Функции и пределы",
            "Производные и дифференцирование",
            "Интегралы и первообразные",
            "Последовательности и ряды",
          ];
          return mathTitles[index];

        case Subject.chemistry:
          final chemistryTitles = [
            "Атомное строение вещества",
            "Химическая связь и строение молекул",
            "Стехиометрия и химические формулы",
            "Химические реакции",
            "Растворы",
          ];
          return chemistryTitles[index];

        case Subject.history:
          final historyTitles = [
            "XVII век",
            "XVIII век",
            "XIX век",
            "XX век",
            "XXIf век",
          ];
          return historyTitles[index];
      }
    }

    // Уникальные названия разделов для каждого предмета
    String getSectionName(Subject subject) {
      switch (subject) {
        case Subject.math:
          return "МАТЕМАТИКА";
        case Subject.chemistry:
          return "ХИМИЯ";
        case Subject.history:
          return "ИСТОРИЯ";
      }
    }

    final String blockTitle = getBlockTitle(currentSubject, blockNumber);
    final String sectionName = getSectionName(currentSubject);

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
                      color: blockLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border(
                        bottom: isPressed
                            ? BorderSide.none
                            : BorderSide(color: blockDark, width: 6),
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
                          "$sectionName, БЛОК $blockNumber",
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
        return _TheorySheet(
          blockNumber: blockNumber,
          blockTitle: blockTitle,
          subject: currentSubject,
        );
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
    final nodes = _buildLevelNodes(context, state, centers, size);
    final separators = _buildBlockSeparators(size, centers);

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
                      child: Stack(children: [...separators, ...nodes]),
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

/// Цветовые блоки (светлый + тёмный)
const List<Map<String, dynamic>> blockStyles = [
  {
    "light": Color(0xFF4E95D9),
    "dark": Color(0xFF215F9A),
    "icon": "assets/images/icon_current_level-blue.png",
  },
  {
    "light": Color(0xFF8ED973),
    "dark": Color(0xFF3B7D23),
    "icon": "assets/images/icon_current_level-green.png",
  },
  {
    "light": Color(0xFFF2AA84),
    "dark": Color(0xFFC04F15),
    "icon": "assets/images/icon_current_level-peach.png",
  },
  {
    "light": Color(0xFFD86ECC),
    "dark": Color(0xFF78206E),
    "icon": "assets/images/icon_current_level-pink.png",
  },
  {
    "light": Color(0xFF46B1E1),
    "dark": Color(0xFF104862),
    "icon": "assets/images/icon_current_level-light-blue.png",
  },
];

class _BlockSeparator extends StatelessWidget {
  final String title;
  final double width;

  const _BlockSeparator({required this.title, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 24,
      child: Row(
        children: [
          Expanded(child: Container(height: 2, color: const Color(0xFF37464F))),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: "ClashRoyale",
              fontSize: 14,
              letterSpacing: 1.3,
              color: Color(0xFF37464F),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 2, color: const Color(0xFF37464F))),
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
    String asset;

    /// блок текущего уровня
    final int blockNumber = ((levelNumber - 1) ~/ 6) + 1;
    final style = blockStyles[(blockNumber - 1) % blockStyles.length];
    final String currentIcon = style["icon"];

    if (isLocked) {
      asset = 'assets/images/icon_level_closed-f.png';
    } else if (isCompleted) {
      asset = 'assets/images/icon_level_complited-f.png';
    } else if (isCurrent) {
      asset = currentIcon;
    } else {
      asset = currentIcon;
    }

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

// ===== Теория для блока с учетом предмета =====
class _TheorySheet extends StatefulWidget {
  final int blockNumber;
  final String blockTitle;
  final Subject subject;

  const _TheorySheet({
    required this.blockNumber,
    required this.blockTitle,
    required this.subject,
  });

  @override
  State<_TheorySheet> createState() => __TheorySheetState();
}

class __TheorySheetState extends State<_TheorySheet> {
  late Future<TheoryBlock?> _theoryFuture;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTheory();
  }

  void _loadTheory() {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    _theoryFuture = _fetchTheoryFromServer();
  }

  Future<TheoryBlock?> _fetchTheoryFromServer() async {
    try {
      // Преобразуем Subject в строку для сервера
      String subjectName;
      switch (widget.subject) {
        case Subject.math:
          subjectName = 'Math';
        case Subject.chemistry:
          subjectName = 'Chemistry';
        case Subject.history:
          subjectName = 'History'; // Внимание: английский -> History
      }

      final theoryBlock = await ApiService.getTheoryBySubjectAndBlock(
        subjectName,
        widget.blockNumber,
      );

      setState(() {
        _isLoading = false;
      });

      return theoryBlock;
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ошибка загрузки теории: $e';
      });
      return null;
    }
  }

  // Локальная теория как fallback
  String _getLocalTheoryContent(Subject subject, int blockNumber) {
    switch (subject) {
      case Subject.math:
        return _getLocalMathTheory(blockNumber);
      case Subject.chemistry:
        return _getLocalChemistryTheory(blockNumber);
      case Subject.history:
        return _getLocalHistoryTheory(blockNumber);
    }
  }

  String _getLocalMathTheory(int blockNumber) {
    switch (blockNumber) {
      case 1:
        return """
Линейная алгебра изучает векторы, матрицы, линейные пространства...
        """;
      // ... остальная локальная теория ...
      default:
        return "Теория для блока $blockNumber будет добавлена позже.";
    }
  }

  String _getLocalChemistryTheory(int blockNumber) {
    // ... локальная теория по химии ...
    return "Теория по химии для блока $blockNumber";
  }

  String _getLocalHistoryTheory(int blockNumber) {
    // ... локальная теория по истории ...
    return "Теория по истории для блока $blockNumber";
  }

  @override
  Widget build(BuildContext context) {
    final String subjectName = widget.subject == Subject.math
        ? "Математика"
        : widget.subject == Subject.chemistry
        ? "Химия"
        : "История";

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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subjectName,
                          style: const TextStyle(
                            fontFamily: "ClashRoyale",
                            fontSize: 16,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // ИЗМЕНЕНО: показываем только номер блока, без названия
                        Text(
                          "Блок ${widget.blockNumber}",
                          style: const TextStyle(
                            fontFamily: "ClashRoyale",
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              if (_isLoading)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF49C0F7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Загрузка теории...',
                          style: TextStyle(
                            fontFamily: "ClashRoyale",
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_errorMessage.isNotEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.orange,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: "ClashRoyale",
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTheory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF49C0F7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Повторить',
                            style: TextStyle(
                              fontFamily: "ClashRoyale",
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: FutureBuilder<TheoryBlock?>(
                    future: _theoryFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _buildFallbackContent(scrollController);
                      }

                      if (snapshot.hasData && snapshot.data != null) {
                        final theoryBlock = snapshot.data!;
                        return _buildServerTheoryContent(
                          scrollController,
                          theoryBlock,
                        );
                      }

                      return _buildFallbackContent(scrollController);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServerTheoryContent(
    ScrollController scrollController,
    TheoryBlock theoryBlock,
  ) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (theoryBlock.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                theoryBlock.title,
                style: const TextStyle(
                  fontFamily: "ClashRoyale",
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

          // Текст теории
          Text(
            theoryBlock.content,
            style: const TextStyle(
              fontFamily: "ClashRoyale",
              fontSize: 16,
              color: Colors.white70,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 20),

          // Изображение, если есть (только для первых двух блоков)
          if (theoryBlock.hasImage && theoryBlock.blockNumber <= 2)
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF37464F),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/theory/${theoryBlock.image!}',
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Иллюстрация к теме',
                  style: TextStyle(
                    fontFamily: "ClashRoyale",
                    fontSize: 14,
                    color: Colors.white60,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackContent(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ИЗМЕНЕНО: показываем название блока здесь, а не в заголовке
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.blockTitle, // Название блока показываем в контенте
              style: const TextStyle(
                fontFamily: "ClashRoyale",
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              "⚠️ Используется локальная копия",
              style: TextStyle(
                fontFamily: "ClashRoyale",
                fontSize: 14,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            _getLocalTheoryContent(widget.subject, widget.blockNumber),
            style: const TextStyle(
              fontFamily: "ClashRoyale",
              fontSize: 16,
              color: Colors.white70,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
