part of '../game_state.dart';

extension GameStateTickets on GameState {
  // === Проверка блокировки ===
  bool isTicketUnlocked(int ticketNumber) {
    return _unlockedTickets[_currentSubject]?.contains(ticketNumber) ?? false;
  }

  bool isLevelUnlocked(int levelNumber) {
    return currentLevel >= levelNumber;
  }

  // === Прогресс по билетам ===
  void saveAnswer({
    required Subject subject,
    required int ticketNumber,
    required int questionNumber,
    required bool isCorrect,
  }) {
    final key = _getTicketKey(subject, ticketNumber);

    final existingProgress = _ticketsProgress[key];
    if (existingProgress != null) {
      // Создаем новую копию с обновленными данными
      final updatedAnswers =
          Map<int, bool>.from(existingProgress.answeredQuestions)
            ..[questionNumber] = isCorrect;
      final nextLastAnsweredIndex = isCorrect &&
              questionNumber > existingProgress.lastAnsweredIndex
          ? questionNumber
          : existingProgress.lastAnsweredIndex;
      _ticketsProgress[key] = TicketProgress(
        ticketNumber: ticketNumber,
        subject: subject,
        answeredQuestions: updatedAnswers,
        lastAnsweredIndex: nextLastAnsweredIndex,
        isCompleted: existingProgress.isCompleted,
      );
    } else {
      _ticketsProgress[key] = TicketProgress(
        ticketNumber: ticketNumber,
        subject: subject,
        answeredQuestions: {questionNumber: isCorrect},
        lastAnsweredIndex: isCorrect ? questionNumber : 0,
        isCompleted: false,
      );
    }

    _saveAndNotify();
  }

  void completeTicket(Subject subject, int ticketNumber) {
    final key = _getTicketKey(subject, ticketNumber);
    final progress = _ticketsProgress[key];
    if (progress != null && !progress.isCompleted) {
      _ticketsProgress[key] = TicketProgress(
        ticketNumber: ticketNumber,
        subject: subject,
        answeredQuestions: progress.answeredQuestions,
        lastAnsweredIndex: progress.lastAnsweredIndex,
        isCompleted: true,
      );
      _saveAndNotify();
    }
  }

  TicketProgress? getTicketProgress(Subject subject, int ticketNumber) {
    return _ticketsProgress[_getTicketKey(subject, ticketNumber)];
  }

  int getTicketLastIndex(Subject subject, int ticketNumber) {
    return getTicketProgress(subject, ticketNumber)?.lastAnsweredIndex ?? 0;
  }

  bool isTicketCompleted(
    Subject subject,
    int ticketNumber,
    int totalQuestions,
  ) {
    final ticket = getTicketProgress(subject, ticketNumber);
    if (ticket == null) return false;
    return ticket.isCompleted ||
        ticket.answeredQuestions.length == totalQuestions;
  }
}
