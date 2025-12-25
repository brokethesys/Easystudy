import 'dart:math';
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
  Map<String, dynamic> question = {};
  List<String> _shuffledOptions = []; // Перемешанные варианты ответов
  List<int> _optionMapping = []; // Маппинг перемешанных индексов к оригинальным
  int? selectedIndex;
  int? correctAnswerIndex;
  int? _originalCorrectIndex; // Исходный индекс правильного ответа
  bool answered = false;
  Color backgroundColor = Colors.blue;
  bool isLoading = false;
  String error = '';
  bool _shouldAutoClose = false;
  int _attemptsLeft = 2;
  bool _showRetryButton = false;
  String _hintText = '';
  Random _random = Random();

  @override
  void initState() {
    super.initState();

    backgroundColor = _colorForId(currentBackground.value);
    currentBackground.addListener(_backgroundListener);

    _loadQuestionFromServer();
  }

  // Метод для перемешивания вариантов ответов
  void _shuffleOptions(List<String> options, int correctAnswerIndex) {
    // Создаем массив индексов: [0, 1, 2, 3]
    List<int> indices = List.generate(options.length, (index) => index);

    // Перемешиваем индексы
    indices.shuffle(_random);

    // Создаем перемешанные варианты ответов
    _shuffledOptions = indices.map((index) => options[index]).toList();

    // Находим, где теперь находится правильный ответ
    for (int i = 0; i < indices.length; i++) {
      if (indices[i] == correctAnswerIndex) {
        this.correctAnswerIndex = i;
        break;
      }
    }

    // Сохраняем маппинг перемешанных индексов к оригинальным
    _optionMapping = indices;

    print('📊 Варианты ответов перемешаны:');
    print('   Исходные варианты: $options');
    print('   Перемешанные варианты: $_shuffledOptions');
    print('   Маппинг индексов: $_optionMapping');
    print(
      '   Правильный ответ был на позиции $correctAnswerIndex, теперь на ${this.correctAnswerIndex}',
    );
  }

  Future<void> _loadQuestionFromServer() async {
    setState(() {
      isLoading = true;
      error = '';
      selectedIndex = null;
      answered = false;
      correctAnswerIndex = null;
      _originalCorrectIndex = null;
      _shuffledOptions = [];
      _optionMapping = [];
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

      // ВАЖНО: запрашиваем упорядоченные вопросы (без перемешивания)
      final questions = await ApiService.getOrderedQuestionsBySubject(
        subjectString,
        limit: 50, // Достаточно для всех уровней
      );

      if (questions.isEmpty) {
        throw Exception('Нет вопросов по предмету $subjectString');
      }

      // Определяем, к какому блоку относится уровень
      // Уровни 1-6: блок 1, уровни 7-12: блок 2, и т.д.
      final blockNumber = ((widget.level - 1) ~/ 6) + 1;
      print('🎯 Уровень ${widget.level} относится к блоку $blockNumber');

      // Получаем вопросы только для нужного блока
      // Для этого нужно знать категорию каждого вопроса
      // Пока что берем все вопросы и распределяем по порядку

      // Простой подход: берем вопрос по порядку
      // Если в будущем добавите категории в вопросы, можно будет фильтровать по блоку
      final questionIndex = (widget.level - 1) % questions.length;
      final serverQuestion = questions[questionIndex];

      print('📋 Вопрос из сервера:');
      print('   ID: ${serverQuestion.id}');
      print('   Категория: ${serverQuestion.category}');
      print('   Вопрос: ${serverQuestion.question}');

      // Получаем правильный ответ с сервера
      final answerResult = await _getCorrectAnswerFromServer(serverQuestion.id);
      final correctAnswerIndex = answerResult['correctAnswerIndex'];
      final explanation = answerResult['explanation'];

      // Перемешиваем варианты ответов
      _shuffleOptions(serverQuestion.options, correctAnswerIndex);

      // Создаем объект вопроса
      final Map<String, dynamic> newQuestion = {
        "question": serverQuestion.question,
        "options": serverQuestion.options, // Оригинальные варианты
        "answer": correctAnswerIndex, // Оригинальный индекс правильного ответа
        "id": serverQuestion.id,
        "subject": serverQuestion.subject,
        "category": serverQuestion.category,
        "explanation": explanation,
      };

      setState(() {
        question = newQuestion;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Ошибка загрузки вопроса: $e');
      setState(() {
        error = e.toString();
        isLoading = false;
        question = _getFallbackQuestion();
        // Перемешиваем и fallback варианты
        _shuffleOptions(
          question["options"] as List<String>,
          question["answer"] as int,
        );
      });
    }
  }

  // Метод для получения правильного ответа с сервера
  Future<Map<String, dynamic>> _getCorrectAnswerFromServer(
    int questionId,
  ) async {
    try {
      // Отправляем запрос на проверку с любым ответом, чтобы получить правильный
      final result = await ApiService.checkAnswer(
        questionId: questionId,
        userAnswer: 0,
      );

      return {
        'correctAnswerIndex': result.correctAnswer,
        'explanation': result.explanation,
      };
    } catch (e) {
      print('⚠️ Не удалось получить ответ с сервера: $e');
      // Fallback
      return {
        'correctAnswerIndex': 0,
        'explanation': 'Проверьте свои знания по этой теме',
      };
    }
  }

  String _subjectToString(Subject subject) {
    switch (subject) {
      case Subject.chemistry:
        return 'Chemistry';
      case Subject.math:
        return 'Math';
      case Subject.history:
        return 'History';
    }
  }

  Map<String, dynamic> _getFallbackQuestion() {
    final subject = Provider.of<GameState>(
      context,
      listen: false,
    ).currentSubject;

    // Fallback вопросы сгруппированы по блокам
    final blockNumber = ((widget.level - 1) ~/ 6) + 1;

    final fallbackQuestionsByBlock = {
      Subject.chemistry: [
        // Блок 1 (уровни 1-6)
        [
          {
            "question": "Кто открыл периодический закон химических элементов?",
            "options": ["Менделеев", "Бор", "Резерфорд", "Лавуазье"],
            "answer": 0,
            "explanation":
                "Д.И. Менделеев открыл периодический закон в 1869 году",
            "id": 1,
            "subject": "Chemistry",
            "category": "atomic_structure",
          },
          {
            "question":
                "Сколько электронов на внешнем уровне у атома натрия (Na)?",
            "options": ["1", "2", "3", "4"],
            "answer": 0,
            "explanation": "Натрий имеет 1 электрон на внешнем уровне",
            "id": 2,
            "subject": "Chemistry",
            "category": "atomic_structure",
          },
        ],
        // Блок 2 (уровни 7-12)
        [
          {
            "question":
                "Какая связь образуется между атомами водорода в молекуле H₂?",
            "options": ["Ковалентная", "Ионная", "Металлическая", "Водородная"],
            "answer": 0,
            "explanation": "В молекуле H₂ образуется ковалентная связь",
            "id": 3,
            "subject": "Chemistry",
            "category": "chemical_bond",
          },
        ],
      ],
      Subject.math: [
        // Блок 1
        [
          {
            "question": "Что такое матрица?",
            "options": [
              "Прямоугольная таблица чисел",
              "Функция двух переменных",
              "Скалярное произведение",
              "Дифференциальное уравнение",
            ],
            "answer": 0,
            "explanation":
                "Матрица — это прямоугольная таблица чисел, символов или выражений",
            "id": 26,
            "subject": "Math",
            "category": "linear_algebra",
          },
        ],
        // Блок 2
        [
          {
            "question": "Что такое предел функции?",
            "options": [
              "Значение, к которому стремится функция",
              "Производная функции",
              "Интеграл функции",
              "Область определения",
            ],
            "answer": 0,
            "explanation":
                "Предел функции — это значение, к которому стремится функция при приближении аргумента к определенной точке",
            "id": 27,
            "subject": "Math",
            "category": "functions_limits",
          },
        ],
      ],
      Subject.history: [
        // Блок 1
        [
          {
            "question":
                "Какой период истории России называют Смутным временем?",
            "options": ["1605–1613", "1598–1613", "1613–1649", "1584–1598"],
            "answer": 1,
            "explanation": "Смутное время — период с 1598 по 1613 год",
            "id": 51,
            "subject": "History",
            "category": "17_century",
          },
        ],
        // Блок 2
        [
          {
            "question": "Кто был первым императором России?",
            "options": [
              "Петр I",
              "Иван Грозный",
              "Екатерина II",
              "Александр I",
            ],
            "answer": 0,
            "explanation": "Петр I был провозглашен императором в 1721 году",
            "id": 52,
            "subject": "History",
            "category": "18_century",
          },
        ],
      ],
    };

    final subjectQuestions = fallbackQuestionsByBlock[subject] ?? [];

    // Берем вопросы из нужного блока
    final blockIndex = blockNumber - 1;
    if (blockIndex < subjectQuestions.length) {
      final blockQuestions = subjectQuestions[blockIndex];

      // Берем конкретный вопрос внутри блока по порядку уровней
      final levelInBlock = (widget.level - 1) % 6;
      final questionIndex = levelInBlock % blockQuestions.length;

      return blockQuestions[questionIndex];
    }

    // Fallback если блок не найден
    return {
      "question": "Вопрос для уровня ${widget.level}",
      "options": ["Вариант A", "Вариант B", "Вариант C", "Вариант D"],
      "answer": 0,
      "explanation": "Это тестовый вопрос",
      "id": 0,
      "subject": subject.toString(),
      "category": "general",
    };
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
      _hintText = '';
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
      // Проверяем правильность ответа (с учетом перемешивания)
      final isCorrect = index == correctAnswerIndex;

      // Получаем объяснение
      final explanation = question["explanation"] ?? 'Подумайте внимательнее!';

      setState(() {
        answered = true;
        isLoading = false;
        _hintText = explanation;

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
    } catch (e) {
      print('❌ Ошибка проверки ответа: $e');
      setState(() {
        answered = true;
        isLoading = false;
        _hintText =
            question["explanation"] ?? 'Проверьте свои знания по этой теме';

        if (selectedIndex == correctAnswerIndex) {
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

  // Метод для отображения перемешанных вариантов
  String _getOptionText(int index) {
    if (_shuffledOptions.isNotEmpty && index < _shuffledOptions.length) {
      return _shuffledOptions[index];
    }

    // Fallback
    final options = question["options"] as List? ?? [];
    if (index < options.length) {
      return options[index];
    }

    return 'Вариант ${index + 1}';
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
                    // Верхняя панель с информацией о блоке
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
                        Column(
                          children: [
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
                            Text(
                              'Блок ${((widget.level - 1) ~/ 6) + 1}',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
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

                    // Подсказка
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
                                    'Объяснение:',
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

                    // Загрузка или контент
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
                            // Прогресс внутри блока
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: LinearProgressIndicator(
                                value: (widget.level % 6) / 6,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blueAccent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Вопрос ${(widget.level - 1) % 6 + 1} из 6 в блоке',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 20),

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

                            // Варианты ответов (перемешанные)
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

                                            // Текст варианта (перемешанный)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              child: Text(
                                                _getOptionText(index),
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

                                            // Иконка статуса
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
