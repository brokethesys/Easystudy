part of '../game_state.dart';

class TicketProgress {
  final int ticketNumber;
  final Subject subject;
  final Map<int, bool> answeredQuestions;
  final int lastAnsweredIndex;
  final bool isCompleted;

  TicketProgress({
    required this.ticketNumber,
    required this.subject,
    Map<int, bool>? answeredQuestions,
    this.lastAnsweredIndex = 0,
    this.isCompleted = false,
  }) : answeredQuestions = answeredQuestions ?? {};

  // Эффективная сериализация с использованием бинарного формата
  String serialize() {
    final buffer = StringBuffer()
      ..write('${subject.index}|$ticketNumber|$lastAnsweredIndex|$isCompleted|');

    // Сериализуем ответы в компактном формате
    if (answeredQuestions.isNotEmpty) {
      final entries = answeredQuestions.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      for (int i = 0; i < entries.length; i++) {
        if (i > 0) buffer.write(',');
        buffer.write('${entries[i].key}:${entries[i].value ? '1' : '0'}');
      }
    }

    return buffer.toString();
  }

  static TicketProgress deserialize(String data) {
    final parts = data.split('|');
    if (parts.length < 5) {
      throw FormatException('Invalid ticket progress data');
    }

    final subject = Subject.values[int.parse(parts[0])];
    final ticketNumber = int.parse(parts[1]);
    final lastAnsweredIndex = int.parse(parts[2]);
    final isCompleted = parts[3] == 'true';
    final answers = <int, bool>{};

    if (parts[4].isNotEmpty) {
      final answerParts = parts[4].split(',');
      for (final answer in answerParts) {
        final kv = answer.split(':');
        if (kv.length == 2) {
          answers[int.parse(kv[0])] = kv[1] == '1';
        }
      }
    }

    return TicketProgress(
      ticketNumber: ticketNumber,
      subject: subject,
      answeredQuestions: answers,
      lastAnsweredIndex: lastAnsweredIndex,
      isCompleted: isCompleted,
    );
  }
}
