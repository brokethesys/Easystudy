import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // для currentBackground
import '../data/game_state.dart';
import '../data/api_service.dart';

class QuizScreen extends StatefulWidget {
  final int level;
  const QuizScreen({super.key, required this.level});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late Map<String, dynamic> question;
  int? selectedIndex;
  int? correctAnswerIndex;
  bool answered = false;
  Color backgroundColor = Colors.blue;
  bool isLoading = false;
  String error = '';
  bool _shouldAutoClose = false;
  int _attemptsLeft = 2; // 2 попытки (первая + 1 повторная)
  bool _showRetryButton = false;
  String _hintText = ''; // Текстовая подсказка

  @override
  void initState() {
    super.initState();

    backgroundColor = _colorForId(currentBackground.value);
    currentBackground.addListener(_backgroundListener);

    _loadQuestionFromServer();
  }

  Future<void> _loadQuestionFromServer() async {
    setState(() {
      isLoading = true;
      error = '';
      selectedIndex = null;
      answered = false;
      correctAnswerIndex = null;
      _attemptsLeft = 2;
      _showRetryButton = false;
      _hintText = '';
    });

    try {
      final subject = Provider.of<GameState>(
        context,
        listen: false,
      ).currentSubject;
      final subjectString = _subjectToString(subject);

      final isConnected = await ApiService.checkConnection();
      if (!isConnected) {
        throw Exception('Нет подключения к серверу. Запустите Python сервер.');
      }

      final questions = await ApiService.getQuestionsBySubject(
        subjectString,
        limit: 50,
        shuffle: false,
      );

      if (questions.isEmpty) {
        throw Exception('Нет вопросов по предмету $subjectString');
      }

      final questionIndex = (widget.level - 1) % questions.length;
      final serverQuestion = questions[questionIndex];

      setState(() {
        question = {
          "question": serverQuestion.question,
          "options": serverQuestion.options,
          "answer": 0,
          "id": serverQuestion.id,
          "subject": serverQuestion.subject,
          "category": serverQuestion.category,
        };
        isLoading = false;
      });
    } catch (e) {
      print('❌ Ошибка загрузки вопроса: $e');
      setState(() {
        error = e.toString();
        isLoading = false;
        question = _getFallbackQuestion();
      });
    }
  }

  String _subjectToString(Subject subject) {
    switch (subject) {
      case Subject.chemistry:
        return 'Chemistry';
      case Subject.math:
        return 'Math';
      case Subject.english:
        return 'History';
    }
  }

  Map<String, dynamic> _getFallbackQuestion() {
    final subject = Provider.of<GameState>(
      context,
      listen: false,
    ).currentSubject;

    switch (subject) {
      case Subject.chemistry:
        return {
          "question": "Сколько будет 2+2?",
          "options": ["3", "4", "5", "6"],
          "answer": 1,
          "id": 0,
          "subject": "Chemistry",
          "category": "fallback",
        };
      case Subject.math:
        return {
          "question": "Производная x² равна?",
          "options": ["2x", "x²", "2x²", "1"],
          "answer": 0,
          "id": 0,
          "subject": "Math",
          "category": "fallback",
        };
      case Subject.english:
        return {
          "question": "В каком году началась Вторая мировая война?",
          "options": ["1937", "1939", "1941", "1945"],
          "answer": 1,
          "id": 0,
          "subject": "History",
          "category": "fallback",
        };
    }
  }

  @override
  void dispose() {
    currentBackground.removeListener(_backgroundListener);
    super.dispose();
  }

  Color _colorForId(String id) {
    final colorMap = {
      'blue': Colors.blue,
      'green': Colors.green,
      'purple': Colors.purple,
      'orange': Colors.orange,
      'red': Colors.red,
      'cyan': Colors.cyan,
      'pink': Colors.pink,
      'teal': Colors.teal,
    };
    return colorMap[id] ?? Colors.blue;
  }

  void _backgroundListener() {
    setState(() {
      backgroundColor = _colorForId(currentBackground.value);
    });
  }

  void _resetSelection() {
    setState(() {
      selectedIndex = null;
      answered = false;
      _showRetryButton = false;
      _hintText = ''; // Очищаем подсказку при повторной попытке
    });
  }

  Future<void> _handleAnswerTap(int index) async {
    if (answered && !_showRetryButton) return;
    if (isLoading) return;

    setState(() {
      selectedIndex = index;
      isLoading = true;
    });

    try {
      final result = await ApiService.checkAnswer(
        questionId: question["id"] ?? 0,
        userAnswer: index,
      );

      setState(() {
        answered = true;
        isLoading = false;
        correctAnswerIndex = result.correctAnswer;
        question["answer"] = result.correctAnswer;

        // Сразу показываем подсказку при неправильном ответе
        _hintText = result.explanation.isNotEmpty
            ? result.explanation
            : 'Подумайте внимательнее!';

        if (result.isCorrect) {
          _shouldAutoClose = true;
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        } else {
          _attemptsLeft--;
          if (_attemptsLeft > 0) {
            _showRetryButton = true;
          } else {
            _showRetryButton = false;
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && !_shouldAutoClose) {
                Navigator.pop(context, false);
              }
            });
          }
        }
      });
    } catch (e) {
      print('❌ Ошибка проверки ответа: $e');
      // Fallback режим
      final isCorrect = index == question["answer"];
      setState(() {
        answered = true;
        isLoading = false;
        correctAnswerIndex = question["answer"];

        // Fallback подсказка
        _hintText = 'Проверьте свои знания по этой теме';

        if (isCorrect) {
          _shouldAutoClose = true;
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        } else {
          _attemptsLeft--;
          if (_attemptsLeft > 0) {
            _showRetryButton = true;
          } else {
            _showRetryButton = false;
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && !_shouldAutoClose) {
                Navigator.pop(context, false);
              }
            });
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (answered && !_showRetryButton) {
          Navigator.pop(context, false);
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: Container(color: backgroundColor)),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.2),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Верхняя панель
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (!isLoading) {
                              Navigator.pop(context, false);
                            }
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Уровень ${widget.level}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        ),
                        if (isLoading)
                          SizedBox(
                            width: 48,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),

                    // Ошибка
                    if (error.isNotEmpty)
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                error,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.refresh, color: Colors.white),
                              onPressed: _loadQuestionFromServer,
                            ),
                          ],
                        ),
                      ),

                    // Текстовая подсказка (показывается СРАЗУ при неправильном ответе)
                    if (_hintText.isNotEmpty && answered)
                      Container(
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.amber,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Подсказка:',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _hintText,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Кнопка повторной попытки
                    if (_showRetryButton)
                      Container(
                        margin: EdgeInsets.only(bottom: 16),
                        child: ElevatedButton(
                          onPressed: _resetSelection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh),
                              SizedBox(width: 8),
                              Text(
                                'Попробовать ещё раз',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),

                    if (isLoading && question.isEmpty)
                      Expanded(
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      )
                    else
                      Expanded(
                        child: Column(
                          children: [
                            // Прогресс
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: LinearProgressIndicator(
                                value: widget.level / 25,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blueAccent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Вопрос ${widget.level} из 25',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Вопрос (без категории)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  question["question"] ?? 'Вопрос не загружен',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Варианты ответов
                            Expanded(
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount:
                                    (question["options"] as List?)?.length ?? 4,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      childAspectRatio: 1.2,
                                    ),
                                itemBuilder: (context, index) {
                                  final options =
                                      question["options"] as List? ?? [];
                                  final isSelected = selectedIndex == index;

                                  Color borderColor = Colors.white;
                                  Color fillColor = Colors.white.withOpacity(
                                    0.1,
                                  );
                                  Color textColor = Colors.white;
                                  Color letterBgColor = Colors.white
                                      .withOpacity(0.2);

                                  if (answered) {
                                    if (isSelected) {
                                      // Выбранный вариант (правильный или неправильный)
                                      final isCorrect =
                                          correctAnswerIndex == index;
                                      if (isCorrect) {
                                        borderColor = Colors.greenAccent;
                                        fillColor = Colors.green.withOpacity(
                                          0.2,
                                        );
                                        letterBgColor = Colors.green;
                                      } else {
                                        borderColor = Colors.redAccent;
                                        fillColor = Colors.red.withOpacity(0.2);
                                        letterBgColor = Colors.red;
                                      }
                                    } else {
                                      // Невыбранные варианты
                                      borderColor = Colors.white.withOpacity(
                                        0.3,
                                      );
                                      fillColor = Colors.white.withOpacity(
                                        0.05,
                                      );
                                      letterBgColor = Colors.white.withOpacity(
                                        0.1,
                                      );
                                      textColor = Colors.white.withOpacity(0.7);
                                    }
                                  } else if (isSelected) {
                                    // Выбран до ответа
                                    borderColor = Colors.blueAccent;
                                    fillColor = Colors.blue.withOpacity(0.2);
                                    letterBgColor = Colors.blue;
                                  }

                                  return GestureDetector(
                                    onTap: () => _handleAnswerTap(index),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      decoration: BoxDecoration(
                                        color: fillColor,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: borderColor,
                                          width: 3,
                                        ),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // Буква варианта
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: letterBgColor,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  String.fromCharCode(
                                                    65 + index,
                                                  ),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 12),

                                            // Текст варианта
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              child: Text(
                                                index < options.length
                                                    ? options[index]
                                                    : 'Вариант ${index + 1}',
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  shadows:
                                                      textColor == Colors.white
                                                      ? [
                                                          Shadow(
                                                            color:
                                                                Colors.black45,
                                                            blurRadius: 4,
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),

                                            // Иконка статуса только для выбранного варианта
                                            if (answered && isSelected)
                                              Container(
                                                margin: EdgeInsets.only(top: 8),
                                                child: Icon(
                                                  correctAnswerIndex == index
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  color:
                                                      correctAnswerIndex ==
                                                          index
                                                      ? Colors.green
                                                      : Colors.red,
                                                  size: 20,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
