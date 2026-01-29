import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/game_state.dart';
import '../widgets/settings_panel.dart';

class TopHUD extends StatelessWidget {
  const TopHUD({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final double widgetHeight = 40.0;
    final Color switchColor = const Color(0xFF49C0F7);
    final Color backgroundColor = const Color(0xFF131F24);

    final double topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding,
      left: 0,
      right: 0,
      child: Container(
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 48 + widgetHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Круг опыта с уровнем
                CustomPaint(
                  painter: _LevelCirclePainter(
                    progress: state.xpRatio,
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

                // Статичный предмет (например, математика)
                SizedBox(
                  width: widgetHeight,
                  height: widgetHeight,
                  child: Image.asset('assets/images/icon_math.png'),
                ),

                // Монеты
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
                        fontSize: 22,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),

                // Настройки
                SizedBox(
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
              ],
            ),
          ),
        ),
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
