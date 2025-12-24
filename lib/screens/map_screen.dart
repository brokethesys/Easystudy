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
      case Subject.english:
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

        case Subject.english:
          final englishTitles = [
            "XVII век",
            "XVIII век",
            "XIX век",
            "XX век",
            "XXIf век",
          ];
          return englishTitles[index];
      }
    }

    // Уникальные названия разделов для каждого предмета
    String getSectionName(Subject subject) {
      switch (subject) {
        case Subject.math:
          return "МАТЕМАТИКА";
        case Subject.chemistry:
          return "ХИМИЯ";
        case Subject.english:
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
class _TheorySheet extends StatelessWidget {
  final int blockNumber;
  final String blockTitle;
  final Subject subject;

  const _TheorySheet({
    required this.blockNumber,
    required this.blockTitle,
    required this.subject,
  });

  // Получение теории для конкретного предмета и блока
  String _getTheoryContent(Subject subject, int blockNumber) {
    switch (subject) {
      case Subject.math:
        return _getMathTheory(blockNumber);
      case Subject.chemistry:
        return _getChemistryTheory(blockNumber);
      case Subject.english:
        return _getEnglishTheory(blockNumber);
    }
  }

  String _getMathTheory(int blockNumber) {
    switch (blockNumber) {
      case 1:
        return """
Линейная алгебра изучает векторы, матрицы, линейные пространства и системы линейных уравнений. Вектор представляет собой направленный отрезок, характеризующийся величиной и направлением, и может быть представлен координатами в пространстве.

Матрица — это прямоугольная таблица чисел, которая используется для представления линейных преобразований и систем уравнений. Набор векторов называется линейно независимым, если ни один вектор нельзя выразить через остальные.

Квадратная матрица называется обратимой, если её детерминант не равен нулю, и для неё существует обратная матрица, позволяющая решать системы линейных уравнений. Линейная алгебра является основой многих областей науки и техники, включая компьютерную графику, физику и экономику.
""";
      case 2:
        return """
Функция — это правило, которое каждому значению из области определения ставит в соответствие одно значение из области значений. Область определения функции включает все допустимые значения аргумента, а область значений — все возможные значения функции.

Предел функции при x стремящемся к a показывает, к какому значению стремится функция, когда аргумент приближается к a. Последовательности также могут иметь предел: если члены последовательности стремятся к числу, она называется сходящейся.

Пределы позволяют исследовать поведение функции в окрестности точки и на бесконечности, и являются основой дифференцирования и интегрирования.
""";
      case 3:
        return """
Производная функции в точке показывает скорость изменения функции относительно аргумента. Производные используются для анализа монотонности функций, нахождения экстремумов и исследования выпуклости графиков.

Основные правила дифференцирования включают формулы для степенных функций, экспоненты и тригонометрических функций. Критическая точка функции — это точка, где производная равна нулю или не существует, и она может быть минимумом, максимумом или точкой перегиба.

Дифференцирование широко применяется в физике, экономике и инженерных задачах для анализа изменений величин.
""";
      case 4:
        return """
Интеграл — это обратная операция к дифференцированию. Неопределённый интеграл представляет собой семейство первообразных функции и включает произвольную константу интегрирования.

Определённый интеграл функции на интервале от a до b равен площади под графиком функции на этом интервале.

Интегралы применяются для вычисления площади, объёма, длины кривой, а также для решения физических задач, таких как нахождение работы, массы или энергии.
""";
      case 5:
        return """
Последовательность — это упорядоченный набор чисел. Арифметическая прогрессия — это последовательность, в которой разность между соседними членами постоянна. Геометрическая прогрессия — это последовательность, в которой отношение соседних членов постоянно.

Суммы членов прогрессий вычисляются по соответствующим формулам: для арифметической прогрессии сумма первых n членов равна n, умноженному на полусумму первого и n-го членов, а для геометрической прогрессии сумма первых n членов равна первому члену, умноженному на частное 1 минус q^n, делённое на 1 минус q, где q — знаменатель прогрессии.

Последовательности и ряды применяются для анализа функций, аппроксимации и решения практических задач в физике и экономике.
""";
      default:
        return "Теория для блока $blockNumber будет добавлена позже.";
    }
  }

  String _getChemistryTheory(int blockNumber) {
    switch (blockNumber) {
      case 1:
        return """
Атомное строение вещества и периодический закон

Все вещества состоят из атомов — наименьших частиц химического элемента, сохраняющих его свойства. Атом состоит из ядра и электронной оболочки. В ядре находятся протоны, имеющие положительный заряд, и нейтроны, не имеющие заряда. Вокруг ядра движутся электроны с отрицательным зарядом.

Число протонов в ядре атома определяет химический элемент и называется порядковым номером. В нейтральном атоме число электронов равно числу протонов. Масса атома в основном сосредоточена в ядре.

Периодический закон, открытый Д. И. Менделеевым, устанавливает, что свойства химических элементов и их соединений находятся в периодической зависимости от заряда ядра атома. Периодическая система позволяет предсказывать свойства элементов, их валентность и характер химических реакций.
""";
      case 2:
        return """
Химическая связь и строение молекул

Химическая связь — это взаимодействие между атомами, приводящее к образованию молекул, ионов или кристаллических решёток. Образование связи сопровождается понижением энергии системы, что делает молекулу устойчивой.

Существует несколько основных типов химической связи. Ковалентная связь образуется за счёт общих электронных пар и характерна для неметаллов. Она может быть полярной и неполярной.
Ионная связь возникает между атомами с большой разницей электроотрицательностей и обусловлена электростатическим притяжением ионов.
Металлическая связь характерна для металлов и объясняет их электропроводность и пластичность.

Тип химической связи определяет физические свойства вещества, такие как температура плавления, твёрдость и растворимость.
""";
      case 3:
        return """
Стехиометрия и химические формулы

Стехиометрия — раздел химии, изучающий количественные соотношения между реагирующими веществами и продуктами реакций. Она основана на законе сохранения массы и законе постоянства состава.

Химическая формула показывает, какие элементы входят в состав вещества и сколько атомов каждого элемента содержится в его молекуле или формульной единице. Индексы в формуле указывают число атомов соответствующего элемента.

Одним из ключевых понятий является моль — количество вещества, содержащее структурные частицы (атомы, молекулы или ионы).
Использование молей позволяет выполнять расчёты масс веществ, объёмов газов и выходов реакций, что имеет большое значение в лабораторной и промышленной практике.
""";
      case 4:
        return """
Химические реакции и их закономерности

Химическая реакция — это процесс, в ходе которого одни вещества (реагенты) превращаются в другие (продукты реакции). При этом происходит перераспределение электронов и изменение химических связей.

Все химические реакции подчиняются закону сохранения массы, согласно которому суммарная масса реагентов равна массе продуктов реакции. Это означает, что атомы в ходе реакции не исчезают и не возникают заново.

По тепловому эффекту реакции делятся на экзотермические, сопровождающиеся выделением энергии, и эндотермические, протекающие с её поглощением.
Признаками химических реакций могут быть выделение газа, образование осадка, изменение цвета или температуры системы.
""";
      case 5:
        return """
Растворы и кислотно-основные свойства

Растворы — это однородные системы, состоящие из растворителя и растворённого вещества. В водных растворах растворителем чаще всего является вода.

Кислотно-основные свойства растворов характеризуются величиной pH, которая показывает концентрацию ионов водорода. Значение pH позволяет определить характер среды: кислую, нейтральную или щелочную.

Кислоты в растворе диссоциируют с образованием ионов водорода, основания — с образованием гидроксид-ионов. Соли образуются при взаимодействии кислот и оснований.
Понимание свойств растворов имеет важное значение для химии, биологии, медицины и экологии.
""";
      default:
        return "Теория для блока $blockNumber будет добавлена позже.";
    }
  }

  String _getEnglishTheory(int blockNumber) {
    switch (blockNumber) {
      case 1:
        return """
История - XVII век в истории России начался с Смутного времени (1598–1613)

XVII век в истории России начался с Смутного времени (1598–1613) — периода глубокого политического, социального и экономического кризиса. Причинами Смуты стали пресечение династии Рюриковичей, борьба за власть, иностранная интервенция и массовые народные выступления. Завершилась Смута избранием на престол Михаила Фёдоровича Романова в 1613 году, что положило начало новой династии.

В XVII веке происходило укрепление самодержавной власти и централизация государства. Важнейшим законодательным актом стало Соборное уложение 1649 года, которое окончательно закрепило крепостное право, усилило зависимость крестьян от помещиков и закрепило сословную структуру общества.

Социальная напряжённость выливалась в крупные народные восстания, крупнейшим из которых стала крестьянская война под руководством Степана Разина (1670–1671). Внешняя политика России была направлена на расширение территории и укрепление позиций: в результате Переяславской рады 1654 года Левобережная Украина вошла в состав Российского государства.
""";
      case 2:
        return """
История - Блок 2: XVIII век (Петровские реформы и Российская империя)

XVIII век стал временем кардинальной модернизации России, связанной прежде всего с деятельностью Петра I. Его реформы затронули все сферы жизни: государственное управление, армию, флот, экономику, образование и культуру. Целью реформ было превращение России в сильную европейскую державу.

В ходе Северной войны (1700–1721) Россия одержала победу над Швецией и получила выход к Балтийскому морю. В 1721 году Россия была официально провозглашена империей, а Пётр I принял титул императора. Новой столицей стал Санкт-Петербург, символ «окна в Европу».

Во второй половине XVIII века политика просвещённого абсолютизма проводилась при Екатерине II. Она сочетала идеи Просвещения с сохранением самодержавной власти и крепостного строя. Усиление крепостничества привело к крупнейшему крестьянскому восстанию под предводительством Емельяна Пугачёва (1773–1775), показавшему глубину социальных противоречий в обществе.
""";
      case 3:
        return """
История - Блок 3: XIX век (Реформы и противоречия развития)

XIX век начался для России Отечественной войной 1812 года, в ходе которой была отражена агрессия наполеоновской Франции. Победа усилила международный авторитет России, но внутренние противоречия сохранились.

В 1825 году произошло восстание декабристов, ставшее первым открытым выступлением против самодержавия. Несмотря на поражение, оно оказало большое влияние на формирование общественно-политической мысли.

Ключевым событием века стала отмена крепостного права в 1861 году при императоре Александре II. Это была важнейшая социально-экономическая реформа, открывшая путь к развитию капиталистических отношений. Однако непоследовательность реформ сохранила многие проблемы.

Поражение в Крымской войне (1853–1856) показало экономическую и военную отсталость России. Во второй половине века при Александре III начался период контрреформ, направленных на усиление самодержавия и ограничение либеральных преобразований.
""";
      case 4:
        return """
История - Блок 4: XX век (Революции, СССР и распад государства)

XX век стал самым драматичным периодом в истории России. В 1917 году произошли Февральская и Октябрьская революции, приведшие к падению монархии и приходу к власти большевиков. В 1922 году было образовано Союз Советских Социалистических Республик (СССР).

В 1920-е годы проводилась Новая экономическая политика (НЭП), сочетавшая элементы плановой и рыночной экономики. В 1930-е годы начались индустриализация и коллективизация, сопровождавшиеся массовыми репрессиями.

Ключевым событием века стала Великая Отечественная война 1941–1945 гг., в которой СССР одержал победу над нацистской Германией. После войны страна стала одной из мировых сверхдержав.

Во второй половине века СССР столкнулся с системным кризисом. В период правления М. С. Горбачёва проводилась перестройка, направленная на реформирование политической и экономической системы. Итогом кризиса стал распад СССР в 1991 году, завершивший советский этап российской истории.
""";
      case 5:
        return """
История - Блок 5:

""";
      default:
        return "Теория для блока $blockNumber будет добавлена позже.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final String subjectName = subject == Subject.math
        ? "Математика"
        : subject == Subject.chemistry
        ? "Химия"
        : "Английский язык";

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
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _getTheoryContent(subject, blockNumber),
                    style: const TextStyle(
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
