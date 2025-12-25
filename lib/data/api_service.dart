import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Важно: для Android эмулятора используйте 10.0.2.2
  // Для iOS симулятора или реального устройства используйте IP вашего компьютера
  static const String baseUrl = 'http://localhost:8080';
  
  // Для тестирования на реальном устройстве:
  // static const String baseUrl = 'http://192.168.1.XXX:8080'; // замените на ваш IP
  
  // Проверка соединения с сервером
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/ping'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Ошибка подключения к серверу: $e');
      return false;
    }
  }
  
  // Получить все предметы
  static Future<List<String>> getSubjects() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/subjects'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['subjects'] ?? []);
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка получения предметов: $e');
      return [];
    }
  }
  
  // Получить вопросы по предмету
  static Future<List<Question>> getQuestionsBySubject(
    String subject, {
    int? limit,
    bool shuffle = false,
  }) async {
    try {
      final params = {
        if (limit != null && limit > 0) 'limit': limit.toString(),
        if (shuffle) 'shuffle': 'true',
      };
      
      final uri = Uri.parse('$baseUrl/questions/subject/$subject').replace(
        queryParameters: params,
      );
      
      final response = await http.get(uri)
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final questionsData = data['questions'] as List? ?? [];
        
        return questionsData.map((q) => Question.fromJson(q)).toList();
      } else {
        throw Exception('Ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка получения вопросов по предмету $subject: $e');
      return [];
    }
  }
  
  // Получить готовый тест
  static Future<Quiz?> getQuiz(String subject, int count) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/quiz/$subject/$count'))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Quiz.fromJson(data['quiz']);
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Ошибка получения теста: $e');
      return null;
    }
  }
  
  // Получить случайный вопрос
  static Future<Question?> getRandomQuestion({String? subject}) async {
    try {
      final params = {
        if (subject != null && subject.isNotEmpty) 'subject': subject,
      };
      
      final uri = Uri.parse('$baseUrl/question/random').replace(
        queryParameters: params,
      );
      
      final response = await http.get(uri)
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Question.fromJson(data['question']);
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Ошибка получения случайного вопроса: $e');
      return null;
    }
  }
  
  // Проверить ответ
  static Future<AnswerResult> checkAnswer({
    required int questionId,
    required int userAnswer,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'question_id': questionId,
          'user_answer': userAnswer,
        }),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AnswerResult.fromJson(data);
      } else {
        throw Exception('Ошибка проверки ответа: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка проверки ответа: $e');
      return AnswerResult(
        isCorrect: false,
        correctAnswer: -1,
        explanation: 'Ошибка соединения с сервером',
        questionId: questionId,
      );
    }
  }
  
  // Получить статистику
  static Future<Map<String, dynamic>?> getStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stats'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Ошибка получения статистики: $e');
      return null;
    }
  }
}

// Модель вопроса
class Question {
  final int id;
  final String subject;
  final String category;
  final String question;
  final List<String> options;
  final int? difficulty;
  
  Question({
    required this.id,
    required this.subject,
    required this.category,
    required this.question,
    required this.options,
    this.difficulty,
  });
  
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? 0,
      subject: json['subject'] ?? '',
      category: json['category'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      difficulty: json['difficulty'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'category': category,
      'question': question,
      'options': options,
      'difficulty': difficulty,
    };
  }
}

// Модель теста
class Quiz {
  final String subject;
  final List<Question> questions;
  final int count;
  final String timestamp;
  
  Quiz({
    required this.subject,
    required this.questions,
    required this.count,
    required this.timestamp,
  });
  
  factory Quiz.fromJson(Map<String, dynamic> json) {
    final questionsData = json['questions'] as List? ?? [];
    
    return Quiz(
      subject: json['subject'] ?? '',
      questions: questionsData.map((q) => Question.fromJson(q)).toList(),
      count: json['count'] ?? 0,
      timestamp: json['timestamp'] ?? '',
    );
  }
}

// Результат проверки ответа
class AnswerResult {
  final bool isCorrect;
  final int correctAnswer;
  final String explanation;
  final int questionId;
  final String? subject;
  final String? category;
  
  AnswerResult({
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
    required this.questionId,
    this.subject,
    this.category,
  });
  
  factory AnswerResult.fromJson(Map<String, dynamic> json) {
    return AnswerResult(
      isCorrect: json['is_correct'] ?? false,
      correctAnswer: json['correct_answer'] ?? -1,
      explanation: json['explanation'] ?? '',
      questionId: json['question_id'] ?? 0,
      subject: json['subject'],
      category: json['category'],
    );
  }
}