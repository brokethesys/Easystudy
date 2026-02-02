import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/game_state.dart';

/// Тип достижения — влияет на цвет прогресса и визуальные метки
enum AchievementType { tickets, perfect, time }

/// Модель достижения (type-safe)
class Achievement {
  final String title;
  final String description;
  final AchievementType type;
  final int goal;
  final int reward;
  final int progress;

  const Achievement({
    required this.title,
    required this.description,
    required this.type,
    required this.goal,
    required this.reward,
    required this.progress,
  });

  double get percent => (progress / goal).clamp(0.0, 1.0);
  bool get isCompleted => percent >= 1.0;
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  /* =======================
     PROGRESS CALCULATIONS
     ======================= */

  int _completedTickets(GameState gameState) {
    return gameState.ticketsProgress.values
        .where(
          (t) =>
              t.subject == Subject.chemistry && t.answeredQuestions.isNotEmpty,
        )
        .length;
  }

  int _perfectTickets(GameState gameState) {
    return gameState.ticketsProgress.values
        .where((t) => t.subject == Subject.chemistry)
        .where((t) => t.answeredQuestions.values.every((v) => v))
        .length;
  }

  int _totalPlayTime(GameState gameState) {
    // TODO: заменить на реальное игровое время
    return gameState.coins;
  }

  /* =======================
     ACHIEVEMENTS LIST
     ======================= */

  List<Achievement> _buildAchievements(GameState gameState) {
    final completed = _completedTickets(gameState);
    final perfect = _perfectTickets(gameState);
    final playTime = _totalPlayTime(gameState);

    return [
      Achievement(
        title: 'Пройти 3 билета',
        description: 'Завершите 3 билета по Программной инженерии',
        type: AchievementType.tickets,
        goal: 3,
        reward: 50,
        progress: completed,
      ),
      Achievement(
        title: 'Пройти 5 билетов',
        description: 'Завершите 5 билетов по Программной инженерии',
        type: AchievementType.tickets,
        goal: 5,
        reward: 100,
        progress: completed,
      ),
      Achievement(
        title: 'Пройти 10 билетов',
        description: 'Завершите 10 билетов по Программной инженерии',
        type: AchievementType.tickets,
        goal: 10,
        reward: 200,
        progress: completed,
      ),
      Achievement(
        title: 'Идеально пройти 3 билета',
        description: 'Ответьте правильно на все вопросы в 3 билетах',
        type: AchievementType.perfect,
        goal: 3,
        reward: 150,
        progress: perfect,
      ),
      Achievement(
        title: 'Провести 30 минут в игре',
        description: 'Проведите 30 минут в игре',
        type: AchievementType.time,
        goal: 30,
        reward: 100,
        progress: playTime,
      ),
      Achievement(
        title: 'Провести 60 минут в игре',
        description: 'Проведите 60 минут в игре',
        type: AchievementType.time,
        goal: 60,
        reward: 200,
        progress: playTime,
      ),
      Achievement(
        title: 'Провести 120 минут в игре',
        description: 'Проведите 120 минут в игре',
        type: AchievementType.time,
        goal: 120,
        reward: 350,
        progress: playTime,
      ),
    ];
  }

  /* =======================
     REWARD COLLECTION
     ======================= */

  void _collectReward({
    required BuildContext context,
    required GameState gameState,
    required int index,
    required int reward,
  }) {
    if (gameState.isAchievementCollected(index)) return;

    gameState.collectAchievement(index, reward);

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 150,
        left: MediaQuery.of(context).size.width / 2 - 50,
        child: _AnimatedCoinPopup(reward: reward),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), entry.remove);
  }

  /* =======================
     UI
     ======================= */

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final achievements = _buildAchievements(gameState);

    return Scaffold(
      backgroundColor: const Color(0xFF131F24),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Достижения',
                style: TextStyle(
                  fontFamily: 'ClashRoyale',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    final collected = gameState.isAchievementCollected(index);

                    return AchievementCard(
                      achievement: achievement,
                      collected: collected,
                      onCollect: achievement.isCompleted && !collected
                          ? () => _collectReward(
                              context: context,
                              gameState: gameState,
                              index: index,
                              reward: achievement.reward,
                            )
                          : null,
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

/* =======================
   ACHIEVEMENT CARD
   ======================= */

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool collected;
  final VoidCallback? onCollect;

  const AchievementCard({
    super.key,
    required this.achievement,
    required this.collected,
    this.onCollect,
  });

  Color get _progressColor {
    switch (achievement.type) {
      case AchievementType.perfect:
        return Colors.amber;
      case AchievementType.time:
        return Colors.blueAccent;
      case AchievementType.tickets:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131F24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF37464F), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            achievement.title,
            style: const TextStyle(
              fontFamily: 'ClashRoyale',
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            style: const TextStyle(
              fontFamily: 'ClashRoyale',
              fontSize: 12,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onCollect,
            child: Stack(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF37464F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: achievement.percent,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: _progressColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Text(
                      collected
                          ? 'Награда получена'
                          : achievement.isCompleted
                          ? 'Получить награду'
                          : '${achievement.progress}/${achievement.goal}',
                      style: const TextStyle(
                        fontFamily: 'ClashRoyale',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* =======================
   COIN POPUP
   ======================= */

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

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 1.5),
          end: const Offset(0, -1.5),
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
        child: _CoinPopupContent(reward: widget.reward),
      ),
    );
  }
}

class _CoinPopupContent extends StatelessWidget {
  final int reward;

  const _CoinPopupContent({required this.reward});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amberAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '+$reward',
        style: const TextStyle(
          fontFamily: 'ClashRoyale',
          fontSize: 20,
          color: Colors.white,
        ),
      ),
    );
  }
}
