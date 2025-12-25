import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/game_state.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    // Функции для вычисления прогресса (изначально 0, но логика работает)
    int getTotalScore() {
      // В будущем можно будет считать общий счет из пройденных уровней
      return 0;
    }

    int getPerfectLevelsCount() {
      // В будущем можно будет считать идеально пройденные уровни
      return 0;
    }

    int getDaysInRow() {
      // В будущем можно будет считать дни подряд
      return 0;
    }

    int getTotalStars() {
      // В будущем можно будет считать общее количество звезд
      return 0;
    }

    int getTotalPlayTime() {
      // В будущем можно будет считать общее время игры (в минутах)
      return 0;
    }

    final achievements = [
      // Прогресс по уровням по всем предметам без учета первых уровней
      {
        "title": "Пройти 3 уровня",
        "progress": gameState.totalCompletedLevels,
        "goal": 3,
        "reward": 50,
        "description": "Завершите прохождение 3 уровней",
        "type": "levels_total",
      },
      {
        "title": "Пройти 5 уровней",
        "progress": gameState.totalCompletedLevels,
        "goal": 5,
        "reward": 75,
        "description": "Завершите прохождение 5 уровней",
        "type": "levels_total",
      },
      {
        "title": "Пройти все 75 уровней",
        "progress": gameState.totalCompletedLevels,
        "goal": 75,
        "reward": 500,
        "description": "Завершите все 75 уровней игры",
        "type": "levels_total",
      },
      
      // Прогресс по химии
      {
        "title": "Химик-новичок",
        "progress": gameState.getCompletedLevelsCountWithoutFirst(Subject.chemistry),
        "goal": 3,
        "reward": 80,
        "description": "Пройти 3 уровня по химии",
        "type": "chemistry_levels",
      },
      {
        "title": "Химик-эксперт",
        "progress": gameState.getCompletedLevelsCountWithoutFirst(Subject.chemistry),
        "goal": 10,
        "reward": 150,
        "description": "Пройти 10 уровней по химии",
        "type": "chemistry_levels",
      },
      {
        "title": "Мастер химии",
        "progress": gameState.getCurrentMaxLevel(Subject.chemistry),
        "goal": 20,
        "reward": 300,
        "description": "Достигнуть 20 уровня в химии",
        "type": "chemistry_max",
      },
      
      // Прогресс по математике
      {
        "title": "Математик-новичок",
        "progress": gameState.getCompletedLevelsCountWithoutFirst(Subject.math),
        "goal": 3,
        "reward": 80,
        "description": "Пройти 3 уровня по математике",
        "type": "math_levels",
      },
      {
        "title": "Математик-эксперт",
        "progress": gameState.getCompletedLevelsCountWithoutFirst(Subject.math),
        "goal": 10,
        "reward": 150,
        "description": "Пройти 10 уровней по математике",
        "type": "math_levels",
      },
      {
        "title": "Мастер математики",
        "progress": gameState.getCurrentMaxLevel(Subject.math),
        "goal": 20,
        "reward": 300,
        "description": "Достигнуть 20 уровня в математике",
        "type": "math_max",
      },
      
      // Прогресс по английскому
      {
        "title": "Лингвист-новичок",
        "progress": gameState.getCompletedLevelsCountWithoutFirst(Subject.history),
        "goal": 3,
        "reward": 80,
        "description": "Пройти 3 уровня по английскому (без учета 1-го уровня)",
        "type": "english_levels",
      },
      {
        "title": "Лингвист-эксперт",
        "progress": gameState.getCompletedLevelsCountWithoutFirst(Subject.history),
        "goal": 5,
        "reward": 150,
        "description": "Пройти 5 уровней по английскому (без учета 1-го уровня)",
        "type": "english_levels",
      },
      {
        "title": "Мастер английского",
        "progress": gameState.getCurrentMaxLevel(Subject.history),
        "goal": 10,
        "reward": 300,
        "description": "Достигнуть 10 уровня в английском",
        "type": "english_max",
      },
      
      // Достижения по коллекциям и монетам
      {
        "title": "Открыть 5 фонов",
        "progress": gameState.ownedBackgrounds.length,
        "goal": 5,
        "reward": 100,
        "description": "Соберите коллекцию из 5 различных фонов",
        "type": "backgrounds",
      },
      {
        "title": "Заработать 500 монет",
        "progress": gameState.coins,
        "goal": 500,
        "reward": 120,
        "description": "Накопите 500 монет",
        "type": "coins",
      },
      
      // Новые достижения с нулевым прогрессом
      {
        "title": "Набрать 1000 очков",
        "progress": getTotalScore(),
        "goal": 1000,
        "reward": 150,
        "description": "Наберите в сумме 1000 очков во всех уровнях",
        "type": "score",
      },
      {
        "title": "Идеально пройти 3 уровня",
        "progress": getPerfectLevelsCount(),
        "goal": 3,
        "reward": 175,
        "description": "Завершите 3 уровня с максимальным рейтингом",
        "type": "perfect",
      },
      {
        "title": "Играть 7 дней подряд",
        "progress": getDaysInRow(),
        "goal": 7,
        "reward": 200,
        "description": "Заходите в игру 7 дней подряд",
        "type": "streak",
      },
      {
        "title": "Собрать 50 звезд",
        "progress": getTotalStars(),
        "goal": 50,
        "reward": 250,
        "description": "Соберите в общей сложности 50 звезд",
        "type": "stars",
      },
      {
        "title": "Провести 60 минут в игре",
        "progress": getTotalPlayTime(),
        "goal": 60,
        "reward": 300,
        "description": "Проведите в игре более 60 минут",
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

              // === Заголовок ===
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

              // === Статистика ===
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
                          "Всего пройдено уровней:",
                          style: TextStyle(
                            fontFamily: 'ClashRoyale',
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          gameState.totalCompletedLevels.toString(),
                          style: const TextStyle(
                            fontFamily: 'ClashRoyale',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Уровней по химии:",
                          style: TextStyle(
                            fontFamily: 'ClashRoyale',
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          gameState.getCompletedLevelsCountWithoutFirst(Subject.chemistry).toString(),
                          style: const TextStyle(
                            fontFamily: 'ClashRoyale',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Уровней по математике:",
                          style: TextStyle(
                            fontFamily: 'ClashRoyale',
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          gameState.getCompletedLevelsCountWithoutFirst(Subject.math).toString(),
                          style: const TextStyle(
                            fontFamily: 'ClashRoyale',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Уровней по английскому:",
                          style: TextStyle(
                            fontFamily: 'ClashRoyale',
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          gameState.getCompletedLevelsCountWithoutFirst(Subject.history).toString(),
                          style: const TextStyle(
                            fontFamily: 'ClashRoyale',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
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

                    // Определяем цвет полосы прогресса в зависимости от типа достижения
                    Color progressColor = const Color(0xFF58A700);
                    if (type.contains("chemistry")) {
                      progressColor = Colors.green;
                    } else if (type.contains("math")) {
                      progressColor = Colors.blue;
                    } else if (type.contains("english")) {
                      progressColor = Colors.orange;
                    } else if (type == "levels_total") {
                      progressColor = Colors.purple;
                    }

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
                              // Помечаем как "НОВОЕ" только те достижения, которые не являются основными
                              if (type == "score" || 
                                  type == "perfect" || 
                                  type == "streak" || 
                                  type == "stars" || 
                                  type == "time")
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
                                            style: TextStyle(
                                              fontFamily: 'ClashRoyale',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              shadows: progress == 0
                                                  ? [
                                                      Shadow(
                                                        color: Colors.black
                                                            .withOpacity(0.8),
                                                        blurRadius: 2,
                                                      )
                                                    ]
                                                  : null,
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