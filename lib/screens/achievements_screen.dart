import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/game_state.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    // === Вспомогательные функции для прогресса ===
    int getTotalTicketsCompleted() {
      return gameState.ticketsProgress.values
          .where((t) => t.subject == Subject.chemistry && t.answeredQuestions.isNotEmpty)
          .length;
    }

    int getPerfectTickets() {
      // Например, если все вопросы билета отвечены верно
      return gameState.ticketsProgress.values
          .where((t) => t.subject == Subject.chemistry)
          .where((t) => t.answeredQuestions.values.every((v) => v))
          .length;
    }

    int getTotalPlayTime() {
      // Заглушка для примера, в минутах
      return gameState.coins; // используем временно coins как placeholder
    }

    // === Список достижений ===
    final achievements = [
      {
        "title": "Пройти 3 билета",
        "progress": getTotalTicketsCompleted(),
        "goal": 3,
        "reward": 50,
        "description": "Завершите 3 билета по Программной инженерии",
        "type": "tickets",
      },
      {
        "title": "Пройти 5 билетов",
        "progress": getTotalTicketsCompleted(),
        "goal": 5,
        "reward": 100,
        "description": "Завершите 5 билетов по Программной инженерии",
        "type": "tickets",
      },
      {
        "title": "Пройти 10 билетов",
        "progress": getTotalTicketsCompleted(),
        "goal": 10,
        "reward": 200,
        "description": "Завершите 10 билетов по Программной инженерии",
        "type": "tickets",
      },
      {
        "title": "Идеально пройти 3 билета",
        "progress": getPerfectTickets(),
        "goal": 3,
        "reward": 150,
        "description": "Завершите 3 билета, отвечая на все вопросы верно",
        "type": "perfect",
      },
      {
        "title": "Провести 30 минут в игре",
        "progress": getTotalPlayTime(),
        "goal": 30,
        "reward": 100,
        "description": "Проведите 30 минут в игре",
        "type": "time",
      },
      {
        "title": "Провести 60 минут в игре",
        "progress": getTotalPlayTime(),
        "goal": 60,
        "reward": 200,
        "description": "Проведите 60 минут в игре",
        "type": "time",
      },
      {
        "title": "Провести 120 минут в игре",
        "progress": getTotalPlayTime(),
        "goal": 120,
        "reward": 350,
        "description": "Проведите 120 минут в игре",
        "type": "time",
      },
    ];

    void collectReward(int index, int reward) {
      if (!gameState.isAchievementCollected(index)) {
        gameState.collectAchievement(index, reward);

        final overlay = Overlay.of(context);
        final entry = OverlayEntry(
          builder: (context) => Positioned(
            bottom: 150,
            left: MediaQuery.of(context).size.width / 2 - 50,
            child: _AnimatedCoinPopup(reward: reward),
          ),
        );
        overlay.insert(entry);
        Future.delayed(const Duration(seconds: 2), () => entry.remove());
      }
    }

    return Container(
      color: const Color(0xFF131F24),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Text(
                "Достижения",
                style: TextStyle(
                  fontFamily: 'ClashRoyale',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2B35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF37464F),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Пройдено билетов:",
                          style: TextStyle(
                            fontFamily: 'ClashRoyale',
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          getTotalTicketsCompleted().toString(),
                          style: const TextStyle(
                            fontFamily: 'ClashRoyale',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final ach = achievements[index];
                    final progress = ach["progress"] as int;
                    final goal = ach["goal"] as int;
                    final reward = ach["reward"] as int;
                    final description = ach["description"] as String;
                    final type = ach["type"] as String;
                    final percent = (progress / goal).clamp(0.0, 1.0);
                    final completed = percent >= 1.0;
                    final collected = gameState.isAchievementCollected(index);

                    Color progressColor = Colors.green;
                    if (type == "perfect") progressColor = Colors.amber;
                    if (type == "time") progressColor = Colors.blueAccent;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131F24),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF37464F),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  ach["title"] as String,
                                  style: const TextStyle(
                                    fontFamily: 'ClashRoyale',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (type == "perfect" || type == "time")
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    "НОВОЕ",
                                    style: TextStyle(
                                      fontFamily: 'ClashRoyale',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(
                              fontFamily: 'ClashRoyale',
                              fontSize: 12,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: completed && !collected
                                      ? () => collectReward(index, reward)
                                      : null,
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF37464F),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          return Container(
                                            width:
                                                constraints.maxWidth * percent,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: progressColor,
                                            ),
                                          );
                                        },
                                      ),
                                      Positioned.fill(
                                        child: Center(
                                          child: Text(
                                            collected
                                                ? "Награда получена"
                                                : completed
                                                    ? "Получить награду"
                                                    : "$progress/$goal",
                                            style: const TextStyle(
                                              fontFamily: 'ClashRoyale',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: Image.asset(
                                      'assets/images/coin.png',
                                      fit: BoxFit.cover,
                                      color: collected
                                          ? Colors.grey[600]
                                          : Colors.white,
                                      colorBlendMode: BlendMode.modulate,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "+$reward",
                                    style: TextStyle(
                                      fontFamily: 'ClashRoyale',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: collected
                                          ? Colors.grey[600]
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedCoinPopup extends StatefulWidget {
  final int reward;
  const _AnimatedCoinPopup({required this.reward});

  @override
  State<_AnimatedCoinPopup> createState() => _AnimatedCoinPopupState();
}

class _AnimatedCoinPopupState extends State<_AnimatedCoinPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  late final Animation<Offset> _offset = Tween(
    begin: const Offset(0, 1.5),
    end: const Offset(0, -1.5),
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  late final Animation<double> _opacity = Tween(
    begin: 1.0,
    end: 0.0,
  ).animate(_controller);

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offset,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.amberAccent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: Image.asset('assets/images/coin.png', fit: BoxFit.cover),
              ),
              const SizedBox(width: 6),
              Text(
                "+${widget.reward}",
                style: const TextStyle(
                  fontFamily: 'ClashRoyale',
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
