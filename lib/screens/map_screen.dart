import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/game_state.dart';
import '../widgets/level_node.dart';
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

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _xpController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // === Построение уровней ===
  List<Offset> _calculateLevelCenters(Size screenSize) {
    const int totalLevels = 25;
    const double amplitude = 120;
    const double period = 250;
    const double centerX = 200;

    final rand = Random(42);

    // Высота карты = 200 пикселей на уровень + отступы сверху/снизу
    final double topPadding = 200;
    final double bottomPadding = 120;
    final double stepY = 100.0;
    final double mapHeight =
        bottomPadding + stepY * (totalLevels - 1) + topPadding;

    return List.generate(totalLevels, (i) {
      final double y = mapHeight - bottomPadding - i * stepY;
      final double x =
          centerX + sin(y / period) * amplitude + rand.nextDouble() * 12 - 6;
      return Offset(x, y);
    });
  }

  List<Widget> _buildLevelNodes(
    BuildContext context,
    GameState state,
    List<Offset> centers,
  ) {
    return List.generate(centers.length, (i) {
      final c = centers[i];
      final levelNumber = i + 1;

      // ✅ Проверяем выполнение уровня через Set<int> для текущего предмета
      final isCompleted =
          state.completedLevels[state.currentSubject]?.contains(levelNumber) ??
          false;
      final isCurrent = levelNumber == state.currentLevel;
      final isLocked = levelNumber > state.currentLevel;

      return Positioned(
        top: c.dy - 30,
        left: c.dx - 30,
        child: LevelNode(
          levelNumber: levelNumber,
          isCurrent: isCurrent,
          isLocked: isLocked,
          isCompleted: isCompleted,
          onTap: () async {
            if (isLocked) return;
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QuizScreen(level: levelNumber)),
            );

            if (result == true) {
              state.completeLevel(levelNumber);
              state.addXP(50);
            }
          },
        ),
      );
    });
  }

  // === HUD ===
  Widget _topHUD(BuildContext context, GameState state) {
    const double barHeight = 46;
    final xpRatio = state.currentXP / state.xpForNextLevel;

    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 0, 33, 38),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.black.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    offset: const Offset(0, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // === Заполненная часть ===
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final progressWidth =
                          constraints.maxWidth * xpRatio.clamp(0.0, 1.0);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        width: progressWidth,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF49C0F7,
                          ), // 🔵 голубой как в задании
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    },
                  ),

                  // === Текст XP ===
                  Center(
                    child: Text(
                      '${state.currentXP} / ${state.xpForNextLevel}',
                      style: const TextStyle(
                        fontFamily: 'ClashRoyale',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color.fromARGB(
                          255,
                          248,
                          248,
                          248,
                        ), // 🔥 Новый цвет текста
                      ),
                    ),
                  ),

                  // === Блок уровня (слева) ===
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 52,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 7, 102, 131),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${state.playerLevel}',
                          style: const TextStyle(
                            fontFamily: 'ClashRoyale',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color.fromARGB(
                              255,
                              248,
                              248,
                              248,
                            ), // 🔥 Новый цвет текста
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          _squareButton(
            imageAsset: 'assets/images/coin.png',
            label: state.coins.toString(),
            color: Colors.amber.shade700,
            onTap: () {},
          ),
          const SizedBox(width: 10),
          _squareButton(
            icon: Icons.menu,
            color: const Color(0xFF333333),
            onTap: () => SettingsPanel.open(context),
          ),
        ],
      ),
    );
  }

  Widget _squareButton({
    IconData? icon,
    Color? color,
    String? label,
    String? imageAsset,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (icon != null)
              Icon(icon, color: color ?? Colors.grey.shade800, size: 28),
            if (imageAsset != null)
              SizedBox(
                width: 28,
                height: 28,
                child: Image.asset(imageAsset, fit: BoxFit.cover),
              ),
            if (label != null)
              Positioned(
                bottom: 3,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final screenSize = MediaQuery.of(context).size;
    final levelCenters = _calculateLevelCenters(screenSize);
    final levelNodes = _buildLevelNodes(context, state, levelCenters);
    final mapHeight = (120 + 100 * 24 + 200)
        .toDouble(); // bottomPadding + stepY*(totalLevels-1) + topPadding

    return Scaffold(
      backgroundColor: const Color(0xFF001B33),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            reverse: true,
            physics: const ClampingScrollPhysics(),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/new_bg_map.jpg',
                    fit: BoxFit.fitWidth,
                    repeat: ImageRepeat.repeatY,
                    alignment: Alignment.bottomCenter,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                SizedBox(
                  height: mapHeight,
                  child: CustomPaint(
                    painter: MapPathPainter(levelCenters),
                    child: Stack(children: levelNodes),
                  ),
                ),
              ],
            ),
          ),
          _topHUD(context, state),
        ],
      ),
    );
  }
}

class MapPathPainter extends CustomPainter {
  final List<Offset> centers;

  MapPathPainter(this.centers);

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.isEmpty) return;

    final path = Path()..moveTo(centers.first.dx, centers.first.dy);
    for (int i = 1; i < centers.length; i++) {
      final p1 = centers[i - 1];
      final p2 = centers[i];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      path.quadraticBezierTo(mid.dx, mid.dy, p2.dx, p2.dy);
    }

    final shadow = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final paint = Paint()
      ..color = Colors.orangeAccent.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, shadow);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MapPathPainter oldDelegate) =>
      oldDelegate.centers != centers;
}
