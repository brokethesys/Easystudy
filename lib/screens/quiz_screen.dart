import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // для currentBackground
import '../data/game_state.dart';
import '../data/api_service.dart'; // Подключаем наш новый ApiService

class QuizScreen extends StatefulWidget {
  final int level;
  const QuizScreen({super.key, required this.level});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late Map<String, dynamic> question;
  int? selectedIndex;
  bool answered = false;
  Color backgroundColor = Colors.blue;
  bool isLoading = false;
  String error = '';

  @override
  void initState() {
    super.initState();

    backgroundColor = _colorForId(currentBackground.value);
    currentBackground.addListener(_backgroundListener);

    // Загружаем вопрос из сервера
    _loadQuestionFromServer();
  }

  Future<void> _loadQuestionFromServer() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final subject = Provider.of<GameState>(
        context,
        listen: false,
      ).currentSubject;
      final subjectString = _subjectToString(subject);

      // Проверяем соединение с сервером
      final isConnected = await ApiService.checkConnection();
      if (!isConnected) {
        throw Exception('Нет подключения к серверу. Запустите Python сервер.');
      }

      final questions = await ApiService.getQuestionsBySubject(
        subjectString,
        limit: 50,
        shuffle: true,
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

  List<String> _getAlternativeSubjectNames(Subject subject) {
    switch (subject) {
      case Subject.chemistry:
        return ['Chemistry', 'chemistry'];
      case Subject.math:
        return ['Math', 'math', 'Mathematics'];
      case Subject.english:
        return ['History', 'history'];
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

  Future<void> _handleAnswerTap(int index) async {
    if (answered || isLoading) return;

    setState(() {
      selectedIndex = index;
      isLoading = true;
    });

    try {
      // Проверяем ответ через сервер
      final result = await ApiService.checkAnswer(
        questionId: question["id"] ?? 0,
        userAnswer: index,
      );

      setState(() {
        answered = true;
        isLoading = false;
        // Обновляем правильный ответ из результата
        question["answer"] = result.correctAnswer;
      });

      // Показываем объяснение
      if (result.explanation.isNotEmpty) {
        _showExplanationDialog(result);
      } else {
        // Если нет объяснения, просто ждем и закрываем
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context, result.isCorrect);
        });
      }
    } catch (e) {
      print('❌ Ошибка проверки ответа: $e');
      // Fallback: проверяем локально
      final isCorrect = index == question["answer"];
      setState(() {
        answered = true;
        isLoading = false;
      });

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context, isCorrect);
      });
    }
  }

  void _showExplanationDialog(AnswerResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.isCorrect ? Icons.check_circle : Icons.cancel,
              color: result.isCorrect ? Colors.green : Colors.red,
              size: 30,
            ),
            SizedBox(width: 10),
            Text(
              result.isCorrect ? 'Правильно!' : 'Неправильно',
              style: TextStyle(
                color: result.isCorrect ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result.explanation.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Объяснение:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(result.explanation),
                    SizedBox(height: 10),
                  ],
                ),

              if (!result.isCorrect)
                Text(
                  'Правильный ответ: ${String.fromCharCode(65 + result.correctAnswer)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 300), () {
                Navigator.pop(context, result.isCorrect);
              });
            },
            child: Text(
              'Продолжить',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
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

                  const SizedBox(height: 20),

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
                          // Вопрос
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Категория
                                if (question["category"] != null &&
                                    question["category"] != "fallback")
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      question["category"].toString(),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                SizedBox(height: 8),

                                // Текст вопроса
                                Text(
                                  question["question"] ?? 'Вопрос не загружен',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

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
                                    childAspectRatio: 1,
                                  ),
                              itemBuilder: (context, index) {
                                final options =
                                    question["options"] as List? ?? [];
                                final isCorrect = index == question["answer"];
                                final isSelected = selectedIndex == index;
                                Color borderColor = Colors.white;
                                Color fillColor = Colors.white.withOpacity(0.1);

                                if (answered && isSelected) {
                                  borderColor = isCorrect
                                      ? Colors.greenAccent
                                      : Colors.redAccent;
                                  fillColor = borderColor.withOpacity(0.3);
                                } else if (answered && isCorrect) {
                                  borderColor = Colors.greenAccent;
                                }

                                return GestureDetector(
                                  onTap: () => _handleAnswerTap(index),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      color: fillColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: borderColor,
                                        width: 3,
                                      ),
                                    ),
                                    child: Center(
                                      child: AnimatedScale(
                                        scale: isSelected ? 1.05 : 1.0,
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            index < options.length
                                                ? options[index]
                                                : 'Вариант ${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black45,
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
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
    );
  }
}
