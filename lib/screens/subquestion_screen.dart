import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/game_state.dart';
import '../theme/app_theme.dart';

class SubquestionScreen extends StatefulWidget {
  final List<dynamic> subquestions;
  final int startIndex;
  final int ticketId;
  final Subject subject;

  const SubquestionScreen({
    super.key,
    required this.subquestions,
    this.startIndex = 0,
    required this.ticketId,
    required this.subject,
  });

  @override
  State<SubquestionScreen> createState() => _SubquestionScreenState();
}

class _SubquestionScreenState extends State<SubquestionScreen>
    with TickerProviderStateMixin {
  late List<dynamic> questionsQueue;
  final List<dynamic> unsolvedQuestions = [];

  int currentIndex = 0;
  Set<int> selectedOptions = {};
  final Map<dynamic, int> wrongAttempts = {};
  int correctAnswers = 0;

  bool showExplanation = false;

  late AnimationController progressController;
  late Animation<double> progressAnimation;

  late AnimationController explanationController;
  late Animation<Offset> explanationSlide;

  static const double actionButtonHeight = 50;
  static const double actionButtonBottom = 54;

  int _firstPendingIndex(TicketProgress? progress) {
    if (questionsQueue.isEmpty) return 0;
    for (int i = 0; i < questionsQueue.length; i++) {
      if (progress?.answeredQuestions[i] != true) {
        return i;
      }
    }
    return questionsQueue.length - 1;
  }

  @override
  void initState() {
    super.initState();

    questionsQueue = List.from(widget.subquestions);
    currentIndex = widget.startIndex.clamp(
        0, questionsQueue.isEmpty ? 0 : questionsQueue.length - 1);

    _loadCurrentProgress();

    progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    progressAnimation = Tween<double>(
      begin: 0,
      end: questionsQueue.isEmpty ? 0 : correctAnswers / questionsQueue.length,
    ).animate(
      CurvedAnimation(parent: progressController, curve: Curves.easeOut),
    );

    explanationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    explanationSlide =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: explanationController, curve: Curves.easeOut),
    );

    progressController.forward();
  }

  void _loadCurrentProgress() {
    if (questionsQueue.isEmpty) return;
    final gameState = context.read<GameState>();
    final ticketProgress = gameState.getTicketProgress(
      widget.subject,
      widget.ticketId,
    );

    if (ticketProgress != null) {
      correctAnswers = ticketProgress.answeredQuestions.values
          .where((v) => v == true)
          .length;
      currentIndex = _firstPendingIndex(ticketProgress);
    }
  }

  @override
  void dispose() {
    progressController.dispose();
    explanationController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    progressAnimation = Tween<double>(
      begin: progressAnimation.value,
      end: questionsQueue.isEmpty ? 0 : correctAnswers / questionsQueue.length,
    ).animate(
      CurvedAnimation(parent: progressController, curve: Curves.easeOut),
    );
    progressController.forward(from: 0);
  }

  void _toggleOption(int index, bool isMultiple) {
    setState(() {
      if (isMultiple) {
        selectedOptions.contains(index)
            ? selectedOptions.remove(index)
            : selectedOptions.add(index);
      } else {
        selectedOptions = {index};
      }
    });
  }

  void _confirmAnswer() {
    if (questionsQueue.isEmpty) return;

    final current = questionsQueue[currentIndex];
    final correct = current['correct_answer'];
    final type = current['type'];
    final questionNumber = currentIndex;

    bool isCorrect = false;
    if (type == 'singleanswer') {
      isCorrect =
          selectedOptions.length == 1 && selectedOptions.first == correct;
    } else {
      final correctSet = Set<int>.from(correct);
      isCorrect =
          selectedOptions.length == correctSet.length &&
          selectedOptions.containsAll(correctSet);
    }

    final gameState = context.read<GameState>();
    gameState.saveAnswer(
      subject: widget.subject,
      ticketNumber: widget.ticketId,
      questionNumber: questionNumber,
      isCorrect: isCorrect,
    );

    // Обновляем количество правильных ответов и попытки
    final id = current['subid'];
    int attempt = wrongAttempts[id] ?? 0;
    if (isCorrect) {
      correctAnswers++;
      attempt = 3; // успешный ответ
      if (unsolvedQuestions.contains(current)) unsolvedQuestions.remove(current);
    } else {
      attempt += 1;
      if (attempt == 2 && !unsolvedQuestions.contains(current)) {
        unsolvedQuestions.add(current);
      }
    }
    wrongAttempts[id] = attempt;

    setState(() {
      showExplanation = attempt > 0 && attempt < 3 ? true : isCorrect;
      selectedOptions.clear();
      _updateProgress();
      if (showExplanation) explanationController.forward(from: 0);
      HapticFeedback.selectionClick();
    });
  }

  void _nextQuestion() {
    if (currentIndex >= questionsQueue.length - 1) {
      Navigator.pop(context, {
        'answered': correctAnswers,
        'lastIndex': currentIndex,
        'unsolvedQuestions': unsolvedQuestions,
      });
      return;
    }

    setState(() {
      currentIndex++;
      selectedOptions.clear();
      showExplanation = false;
      explanationController.reset();
    });
  }

  void _retryQuestion() {
    setState(() {
      selectedOptions.clear();
      showExplanation = false;
      explanationController.reset();
    });
  }

  Map<String, dynamic> _getActionButtonConfig(bool isAlreadyAnswered,
      bool wasPreviousCorrect, int attempt) {
    final greenColor = _greenButtonColor();
    final greenLineColor = _greenButtonLineColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color explanationColor = attempt == 1
        ? Colors.yellow.shade700
        : attempt == 2
            ? const Color(0xFFEE5654)
            : greenColor;

    String text = 'ПРОВЕРИТЬ';
    Color color = greenColor;
    Color textColor = const Color(0xFF101E27);
    Color? lineColor = greenLineColor;

    if (isAlreadyAnswered && wasPreviousCorrect && !showExplanation) {
      text = 'ПРОДОЛЖИТЬ';
      color = greenColor;
    } else if (showExplanation) {
      if (attempt == 3 || attempt == 2) {
        text = 'ПРОДОЛЖИТЬ';
        color = explanationColor;
      } else if (attempt == 1) {
        text = 'ПОПРОБОВАТЬ ЕЩЕ РАЗ';
        color = explanationColor;
      }
    }

    if (attempt == 1) textColor = Colors.black;
    if (!isDark && color == greenColor) {
      textColor = Colors.white;
    }
    if (color != greenColor) {
      lineColor = null;
    }

    return {
      'text': text,
      'color': color,
      'textColor': textColor,
      'lineColor': lineColor,
    };
  }

  Color _greenButtonColor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF92D333) : const Color(0xFF59CB0B);
  }

  Color _greenButtonLineColor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF729462) : const Color(0xFF6F9A4A);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    if (questionsQueue.isEmpty) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: Text(
            'Нет вопросов для этого билета',
            style: TextStyle(color: colors.textPrimary),
          ),
        ),
      );
    }

    final current = questionsQueue[currentIndex];
    final options = List<String>.from(current['options']);
    final isMultiple = current['type'] == 'multiplyanswer';
    final maxExplanationHeight = MediaQuery.of(context).size.height * 0.6;

    final gameState = context.read<GameState>();
    final ticketProgress = gameState.getTicketProgress(
      widget.subject,
      widget.ticketId,
    );
    final isAlreadyAnswered =
        ticketProgress?.answeredQuestions.containsKey(currentIndex) ?? false;
    final wasPreviousCorrect =
        ticketProgress?.answeredQuestions[currentIndex] ?? false;
    final attempt = wrongAttempts[current['subid']] ??
        (isAlreadyAnswered && wasPreviousCorrect ? 3 : 0);

    final explanationColor = attempt == 1
        ? Colors.yellow.shade700
        : attempt == 2
            ? const Color(0xFFEE5654)
            : _greenButtonColor();

    final showExplanationText = attempt == 2 || attempt == 3;
    String explanationTitle = '';
    if (attempt == 1) {
      explanationTitle = 'Упс, кажется ты что-то упустил';
    } else if (attempt == 2 || attempt == 3) {
      explanationTitle = 'Объяснение:';
    }

    final btnConfig =
        _getActionButtonConfig(isAlreadyAnswered, wasPreviousCorrect, attempt);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context, {
              'answered': correctAnswers,
              'lastIndex': currentIndex,
              'unsolvedQuestions': unsolvedQuestions,
            });
          },
        ),
        title: AnimatedBuilder(
          animation: progressController,
          builder: (_, __) => Container(
            height: 14,
            decoration: BoxDecoration(
              color: colors.track,
              borderRadius: BorderRadius.circular(7),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              children: [
                Text(
                  current['question'],
                  style: TextStyle(
                    fontFamily: 'ClashRoyale',
                    fontSize: 18,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (_, index) {
                      final isSelected = selectedOptions.contains(index);
                      final correct = current['correct_answer'];
                      final isCorrectOption = isMultiple
                          ? (correct as List).contains(index)
                          : index == correct;

                      Color color = colors.textSecondary;
                      IconData icon = isMultiple
                          ? Icons.check_box_outline_blank
                          : Icons.radio_button_unchecked;

                      if (isAlreadyAnswered && wasPreviousCorrect) {
                        if (isCorrectOption) {
                          color = const Color(0xFF92D333);
                          icon = isMultiple
                              ? Icons.check_box
                              : Icons.radio_button_checked;
                        }
                      } else if (!showExplanation && isSelected) {
                        color = colors.accent;
                        icon = isMultiple
                            ? Icons.check_box
                            : Icons.radio_button_checked;
                      } else if (showExplanation) {
                        if (attempt == 2 || attempt == 3) {
                          if (isCorrectOption) {
                            color = const Color(0xFF92D333);
                            icon = isMultiple
                                ? Icons.check_box
                                : Icons.radio_button_checked;
                          }
                          if (isSelected && !isCorrectOption) {
                            color = const Color(0xFFEE5654);
                            icon = isMultiple
                                ? Icons.check_box
                                : Icons.radio_button_checked;
                          }
                        } else if (attempt == 1) {
                          if (isSelected) {
                            color = Colors.yellow.shade700;
                            icon = isMultiple
                                ? Icons.check_box
                                : Icons.radio_button_checked;
                          }
                        }
                      }

                      final isDisabled =
                          isAlreadyAnswered && wasPreviousCorrect;

                      return GestureDetector(
                        onTap: isDisabled
                            ? null
                            : (showExplanation && attempt != 1)
                                ? null
                                : () => _toggleOption(index, isMultiple),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.surfaceAlt,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color),
                          ),
                          child: Row(
                            children: [
                              Icon(icon, color: color),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  options[index],
                                  style: TextStyle(
                                    fontFamily: 'ClashRoyale',
                                    fontSize: 16,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Объяснение
          if (showExplanation || (isAlreadyAnswered && wasPreviousCorrect))
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: explanationSlide,
                child: Container(
                  constraints: BoxConstraints(maxHeight: maxExplanationHeight),
                  padding: EdgeInsets.fromLTRB(
                      16, 20, 16, actionButtonHeight + actionButtonBottom + 16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: explanationColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          explanationTitle,
                          style: TextStyle(
                            fontFamily: 'ClashRoyale',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: explanationColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (showExplanationText)
                          Text(
                            current['explanation'],
                            style: TextStyle(
                              fontFamily: 'ClashRoyale',
                              fontSize: 14,
                              color: explanationColor,
                              height: 1.4,
                            ),
                          ),
                        if (attempt == 2) const SizedBox(height: 8),
                        if (attempt == 2)
                          Text(
                            'Этот вопрос сохранен в список нерешенных.',
                            style: TextStyle(
                              fontFamily: 'ClashRoyale',
                              fontSize: 12,
                              color: explanationColor.withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Кнопка действия
          Positioned(
            left: 16,
            right: 16,
            bottom: actionButtonBottom,
            child: _ActionButton(
              text: btnConfig['text'],
              color: btnConfig['color'],
              textColor: btnConfig['textColor'],
              lineColor: btnConfig['lineColor'],
              height: actionButtonHeight,
              onTap: () {
                HapticFeedback.selectionClick();
                if (isAlreadyAnswered && wasPreviousCorrect) {
                  _nextQuestion();
                } else if (showExplanation) {
                  if (attempt == 2 || attempt == 3) {
                    _nextQuestion();
                  } else if (attempt == 1) {
                    _retryQuestion();
                  }
                } else {
                  if (selectedOptions.isEmpty) return;
                  _confirmAnswer();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String text;
  final Color color;
  final Color textColor;
  final double height;
  final Color? lineColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.text,
    required this.color,
    required this.textColor,
    required this.height,
    this.lineColor,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) =>
      setState(() => _isPressed = true);
  void _onTapUp(TapUpDetails details) =>
      setState(() => _isPressed = false);
  void _onTapCancel() => setState(() => _isPressed = false);

  @override
  Widget build(BuildContext context) {
    final hasLine = widget.lineColor != null;
    final pressOffset = hasLine && _isPressed ? 4.0 : 0.0;
    final lineColor = _isPressed ? null : widget.lineColor;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, pressOffset, 0),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(14),
            border: lineColor == null
                ? null
                : Border(
                    bottom: BorderSide(
                      color: lineColor,
                      width: 4,
                    ),
                  ),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.text,
            style: TextStyle(
              fontFamily: 'ClashRoyale',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.textColor,
            ),
          ),
        ),
      ),
    );
  }
}
