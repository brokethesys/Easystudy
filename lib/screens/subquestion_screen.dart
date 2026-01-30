import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SubquestionScreen extends StatefulWidget {
  final List<dynamic> subquestions;
  final int startIndex;

  const SubquestionScreen({
    super.key,
    required this.subquestions,
    this.startIndex = 0,
  });

  @override
  State<SubquestionScreen> createState() => _SubquestionScreenState();
}

class _SubquestionScreenState extends State<SubquestionScreen>
    with TickerProviderStateMixin {
  late List<dynamic> questionsQueue;
  final List<dynamic> unsolvedQuestions = [];

  int currentIndex = 0;
  bool showExplanation = false;
  bool answeredCorrectly = false;
  bool isFirstWrongAttempt = false;
  bool isSecondWrongAttempt = false;

  Set<int> selectedOptions = {};
  final Map<dynamic, int> wrongAttempts = {};

  int correctAnswers = 0;

  late AnimationController progressController;
  late Animation<double> progressAnimation;

  late AnimationController explanationController;
  late Animation<Offset> explanationSlide;

  static const double actionButtonHeight = 50;
  static const double actionButtonBottom = 54;

  @override
  void initState() {
    super.initState();

    questionsQueue = List.from(widget.subquestions);
    currentIndex = widget.startIndex.clamp(0, questionsQueue.length - 1);

    progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: progressController, curve: Curves.easeOut),
    );

    explanationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    explanationSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: explanationController, curve: Curves.easeOut),
    );

    progressController.forward();
  }

  @override
  void dispose() {
    progressController.dispose();
    explanationController.dispose();
    super.dispose();
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
    final current = questionsQueue[currentIndex];
    final correct = current['correct_answer'];
    final type = current['type'];

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

    setState(() {
      answeredCorrectly = isCorrect;

      if (isCorrect) {
        HapticFeedback.lightImpact();
        correctAnswers++;
        isFirstWrongAttempt = false;
        isSecondWrongAttempt = false;
        wrongAttempts.remove(current['subid']);
        showExplanation = true;
      } else {
        HapticFeedback.mediumImpact();
        final id = current['subid'];
        final attempts = (wrongAttempts[id] ?? 0) + 1;
        wrongAttempts[id] = attempts;

        if (attempts == 1) {
          isFirstWrongAttempt = true;
          isSecondWrongAttempt = false;
          showExplanation = true;
        } else if (attempts == 2) {
          HapticFeedback.heavyImpact();
          isFirstWrongAttempt = false;
          isSecondWrongAttempt = true;
          showExplanation = true;

          if (!unsolvedQuestions.contains(current)) {
            unsolvedQuestions.add(current);
          }
        }
      }

      // Обновляем прогресс только на правильные ответы
      progressAnimation = Tween<double>(
        begin: progressAnimation.value,
        end: correctAnswers / questionsQueue.length,
      ).animate(
        CurvedAnimation(parent: progressController, curve: Curves.easeOut),
      );

      progressController.forward(from: 0);

      if (showExplanation) {
        explanationController.forward(from: 0);
      }
    });
  }

  void _nextQuestion() {
    HapticFeedback.selectionClick();

    if (currentIndex >= questionsQueue.length - 1) {
      // Все вопросы пройдены
      Navigator.pop(context, {
        'answered': correctAnswers,
        'lastIndex': questionsQueue.length,
        'unsolvedQuestions': unsolvedQuestions,
      });
      return;
    }

    setState(() {
      selectedOptions.clear();
      showExplanation = false;
      answeredCorrectly = false;
      isFirstWrongAttempt = false;
      isSecondWrongAttempt = false;
      explanationController.reset();
      currentIndex++;
    });
  }

  void _retryQuestion() {
    HapticFeedback.selectionClick();
    setState(() {
      selectedOptions.clear();
      showExplanation = false;
      answeredCorrectly = false;
      isFirstWrongAttempt = false;
      explanationController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentIndex >= questionsQueue.length) {
      return Scaffold(
        backgroundColor: const Color(0xFF131F24),
        body: const Center(
          child: Text(
            "Все вопросы пройдены",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final current = questionsQueue[currentIndex];
    final options = List<String>.from(current['options']);
    final isMultiple = current['type'] == 'multiplyanswer';

    final maxExplanationHeight = MediaQuery.of(context).size.height * 0.6;

    final explanationColor = answeredCorrectly
        ? const Color(0xFF92D333)
        : isFirstWrongAttempt
            ? Colors.yellow.shade700
            : const Color(0xFFEE5654);

    // Кнопка действия
    String buttonText = 'ПРОВЕРИТЬ';
    Color buttonColor = const Color(0xFF92D331);
    Color textColor = const Color(0xFF101E27);

    if (showExplanation) {
      if (answeredCorrectly) {
        buttonText = 'ПРОДОЛЖИТЬ';
        buttonColor = explanationColor;
      } else if (isFirstWrongAttempt) {
        buttonText = 'ПОПРОБОВАТЬ ЕЩЕ РАЗ';
        buttonColor = explanationColor;
        textColor = Colors.black;
      } else if (isSecondWrongAttempt) {
        buttonText = 'ПРОДОЛЖИТЬ';
        buttonColor = explanationColor;
      }
    }

    String explanationTitle = 'Объяснение:';
    String explanationText = current['explanation'];

    if (isFirstWrongAttempt) {
      explanationTitle = 'Упс, кажется ты что-то упустил';
      explanationText = 'Попробуй еще раз!';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF131F24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131F24),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
              color: const Color(0xFF37464F),
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
                  style: const TextStyle(
                    fontFamily: 'ClashRoyale',
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (_, index) {
                      final isSelected = selectedOptions.contains(index);

                      Color color = Colors.white70;
                      IconData icon = isMultiple
                          ? Icons.check_box_outline_blank
                          : Icons.radio_button_unchecked;

                      if (!showExplanation && isSelected) {
                        icon = isMultiple
                            ? Icons.check_box
                            : Icons.radio_button_checked;
                        color = Colors.blueAccent;
                      }

                      if (showExplanation) {
                        final correct = current['correct_answer'];
                        final isCorrectOption = isMultiple
                            ? (correct as List).contains(index)
                            : index == correct;

                        if (isFirstWrongAttempt) {
                          if (isSelected) {
                            color = Colors.yellow.shade700;
                            icon = isMultiple
                                ? Icons.check_box
                                : Icons.radio_button_checked;
                          }
                        } else {
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
                        }
                      }

                      return GestureDetector(
                        onTap: showExplanation && !isFirstWrongAttempt
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                _toggleOption(index, isMultiple);
                              },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2C36),
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

          if (showExplanation)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: explanationSlide,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: maxExplanationHeight,
                  ),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    20,
                    16,
                    actionButtonHeight + actionButtonBottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 32, 47, 54),
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
                        Text(
                          explanationText,
                          style: TextStyle(
                            fontFamily: 'ClashRoyale',
                            fontSize: 14,
                            color: explanationColor,
                            height: 1.4,
                          ),
                        ),
                        if (isSecondWrongAttempt)
                          const SizedBox(height: 8),
                        if (isSecondWrongAttempt)
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

          Positioned(
            left: 16,
            right: 16,
            bottom: actionButtonBottom,
            child: GestureDetector(
              onTap: selectedOptions.isEmpty && !showExplanation && !isFirstWrongAttempt
                  ? null
                  : () {
                      HapticFeedback.selectionClick();

                      if (showExplanation) {
                        if (answeredCorrectly || isSecondWrongAttempt) {
                          _nextQuestion();
                        } else if (isFirstWrongAttempt) {
                          _retryQuestion();
                        }
                      } else {
                        _confirmAnswer();
                      }
                    },
              child: Container(
                height: actionButtonHeight,
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  buttonText,
                  style: TextStyle(
                    fontFamily: 'ClashRoyale',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
