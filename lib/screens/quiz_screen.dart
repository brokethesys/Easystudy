import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/game_state.dart';
import 'subquestion_screen.dart';

class QuizScreen extends StatefulWidget {
  final int ticketId;
  const QuizScreen({super.key, required this.ticketId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? ticketData;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  late AnimationController _buttonController;
  late Animation<double> _buttonScale;

  int correctAnswers = 0;
  int totalSubquestions = 1;

  bool startedLearning = false;
  int lastSubquestionIndex = 0;
  bool theoryExpanded = false;

  static const double actionButtonHeight = 50;
  static const double actionButtonBottom = 54;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );

    _buttonScale = _buttonController;

    loadTicket();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> loadTicket() async {
    final String response = await rootBundle.loadString(
      'assets/questions/software_engineering.json',
    );
    final data = json.decode(response);

    final ticket = (data['tickets'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((t) => t['id'] == widget.ticketId, orElse: () => {});
    if (ticket.isEmpty) return; // нет билета

    if (ticket == null) return;

    totalSubquestions = (ticket['subquestions'] as List).length;

    final gameState = context.read<GameState>();
    final subject = gameState.currentSubject;
    final ticketProgress = gameState.getTicketProgress(
      subject,
      widget.ticketId,
    );

    // Правильно считаем правильные ответы
    if (ticketProgress != null) {
      correctAnswers = ticketProgress.answeredQuestions.values
          .where((v) => v == true) // Только правильные ответы
          .length;
      lastSubquestionIndex = ticketProgress.lastAnsweredIndex;
    } else {
      correctAnswers = 0;
      lastSubquestionIndex = 0;
    }

    // Прогресс анимации сразу на правильное значение
    _progressAnimation =
        Tween<double>(
          begin: correctAnswers / totalSubquestions,
          end: correctAnswers / totalSubquestions,
        ).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
        );

    setState(() {
      ticketData = ticket;
      startedLearning = lastSubquestionIndex > 0;
    });
  }

  Future<void> _startLearning() async {
    if (ticketData == null) return;

    HapticFeedback.selectionClick();

    setState(() {
      startedLearning = true;
    });

    final gameState = context.read<GameState>();
    final subject = gameState.currentSubject;

    // Загружаем текущий прогресс перед началом
    final ticketProgress = gameState.getTicketProgress(
      subject,
      widget.ticketId,
    );
    final currentCorrect =
        ticketProgress?.answeredQuestions.values
            .where((v) => v == true)
            .length ??
        0;
    final currentLastIndex = ticketProgress?.lastAnsweredIndex ?? 0;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubquestionScreen(
          subquestions: List<Map<String, dynamic>>.from(
            ticketData!['subquestions'],
          ),
          startIndex: currentLastIndex,
          ticketId: widget.ticketId,
          subject: subject,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final int newCorrect = (result['answered'] ?? currentCorrect) as int;
      final int lastIndex = (result['lastIndex'] ?? currentLastIndex) as int;

      setState(() {
        correctAnswers = newCorrect;
        lastSubquestionIndex = lastIndex;

        // Анимация от текущего состояния до нового прогресса
        _progressAnimation =
            Tween<double>(
              begin: _progressAnimation.value,
              end: correctAnswers / totalSubquestions,
            ).animate(
              CurvedAnimation(
                parent: _progressController,
                curve: Curves.easeOut,
              ),
            );

        _progressController.forward(from: 0);

        // === РАЗБЛОКИРОВКА СЛЕДУЮЩЕГО БИЛЕТА И УРОВНЯ ===
        // Проверяем, полностью ли завершен текущий билет
        final bool isTicketCompleted = correctAnswers == totalSubquestions;

        if (isTicketCompleted) {
          gameState.finishTicket(
            subject: subject,
            ticketNumber: widget.ticketId,
            totalQuestions: totalSubquestions,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Уровень ${widget.ticketId + 1} открыт! 🎉'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }

  Widget _buildProgressBar() {
    return Stack(
      children: [
        Container(
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF37464F),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _progressAnimation,
              builder: (_, __) => Container(
                width: constraints.maxWidth * _progressAnimation.value,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF58A700),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
        Positioned.fill(
          child: Center(
            child: Text(
              "$correctAnswers / $totalSubquestions",
              style: const TextStyle(
                fontFamily: 'ClashRoyale',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    final gameState = context.read<GameState>();
    final isUnlocked = widget.ticketId <= gameState.currentLevel;

    return GestureDetector(
      onTapDown: (_) => _buttonController.reverse(),
      onTapUp: (_) => _buttonController.forward(),
      onTapCancel: () => _buttonController.forward(),
      onTap: isUnlocked ? _startLearning : null,
      child: ScaleTransition(
        scale: _buttonScale,
        child: Container(
          height: actionButtonHeight,
          decoration: BoxDecoration(
            color: isUnlocked ? const Color(0xFF92D331) : Colors.grey,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            !isUnlocked
                ? 'ЗАБЛОКИРОВАНО'
                : (startedLearning ? 'ПРОДОЛЖИТЬ УЧИТЬ' : 'НАЧАТЬ УЧИТЬ'),
            style: TextStyle(
              fontFamily: 'ClashRoyale',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? const Color(0xFF101E27) : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theoryText = ticketData?['theory'] ?? '';
    final gameState = context.read<GameState>();
    final isUnlocked = widget.ticketId <= gameState.currentLevel;

    return Scaffold(
      backgroundColor: const Color(0xFF131F24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131F24),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          ticketData != null ? 'Билет ${ticketData!['id']}' : 'Загрузка...',
          style: const TextStyle(
            fontFamily: 'ClashRoyale',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: ticketData == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    theoryExpanded ? 24 : 140,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUnlocked) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Сначала завершите предыдущий билет',
                                  style: const TextStyle(
                                    fontFamily: 'ClashRoyale',
                                    fontSize: 14,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Text(
                        ticketData!['question'] ?? '',
                        style: const TextStyle(
                          fontFamily: 'ClashRoyale',
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildProgressBar(),
                      const SizedBox(height: 24),
                      const Text(
                        'Вопросы для подготовки:',
                        style: TextStyle(
                          fontFamily: 'ClashRoyale',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(
                        (ticketData!['subquestions'] as List).length,
                        (index) {
                          final sub = ticketData!['subquestions'][index];
                          final gameState = context.read<GameState>();
                          final subject = gameState.currentSubject;
                          final ticketProgress = gameState.getTicketProgress(
                            subject,
                            widget.ticketId,
                          );

                          // Проверяем, отвечен ли этот вопрос
                          final isAnswered =
                              ticketProgress?.answeredQuestions.containsKey(
                                index,
                              ) ??
                              false;
                          final isCorrect =
                              ticketProgress?.answeredQuestions[index] ?? false;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isAnswered
                                  ? (isCorrect
                                        ? const Color(
                                            0xFF2A3A45,
                                          ).withOpacity(0.7)
                                        : const Color(
                                            0xFF5A2A2A,
                                          ).withOpacity(0.7))
                                  : const Color(0xFF1F2C36),
                              borderRadius: BorderRadius.circular(8),
                              border: isAnswered
                                  ? Border.all(
                                      color: isCorrect
                                          ? const Color(0xFF58A700)
                                          : const Color(0xFFD32F2F),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                if (isAnswered)
                                  Icon(
                                    isCorrect
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: isCorrect
                                        ? const Color(0xFF58A700)
                                        : const Color(0xFFD32F2F),
                                    size: 16,
                                  ),
                                if (isAnswered) const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${index + 1}. ${sub['question']}',
                                    style: TextStyle(
                                      fontFamily: 'ClashRoyale',
                                      fontSize: 14,
                                      color: isAnswered
                                          ? Colors.white
                                          : Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2C36),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Теория',
                              style: TextStyle(
                                fontFamily: 'ClashRoyale',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedCrossFade(
                              firstChild: Text(
                                theoryText,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'ClashRoyale',
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              secondChild: Text(
                                theoryText,
                                style: const TextStyle(
                                  fontFamily: 'ClashRoyale',
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              crossFadeState: theoryExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 200),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  theoryExpanded = !theoryExpanded;
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    theoryExpanded ? 'Свернуть' : 'Развернуть',
                                    style: const TextStyle(
                                      fontFamily: 'ClashRoyale',
                                      fontSize: 14,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    theoryExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.blueAccent,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (theoryExpanded) ...[
                        const SizedBox(height: 24),
                        _buildActionButton(),
                      ],
                    ],
                  ),
                ),
                if (!theoryExpanded)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: actionButtonBottom,
                    child: _buildActionButton(),
                  ),
              ],
            ),
    );
  }
}
