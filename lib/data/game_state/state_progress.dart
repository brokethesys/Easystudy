part of '../game_state.dart';

extension GameStateProgress on GameState {
  // === Разблокировка ===
  void unlockTicket(int ticketNumber) {
    final subjectTickets = _unlockedTickets[_currentSubject];
    if (subjectTickets != null && !subjectTickets.contains(ticketNumber)) {
      subjectTickets.add(ticketNumber);
      _saveAndNotify();
    }
  }

  void unlockLevel(int levelNumber) {
    final current = _currentLevels[_currentSubject] ?? 1;
    if (levelNumber > current) {
      _currentLevels[_currentSubject] = levelNumber;
      final firstTicket = _getFirstTicketOfLevel(levelNumber);
      _unlockedTickets[_currentSubject]?.add(firstTicket);
      _saveAndNotify();
    }
  }

  List<int> getTicketsForLevel(int level) {
    final List<int> tickets = [];
    final startTicket = _getFirstTicketOfLevel(level);
    for (int i = 0; i < 5; i++) {
      tickets.add(startTicket + i);
    }
    return tickets;
  }

  bool areAllTicketsCompletedInLevel(int level) {
    final tickets = getTicketsForLevel(level);
    for (final ticketId in tickets) {
      final ticket = getTicketProgress(_currentSubject, ticketId);
      if (ticket == null || !ticket.isCompleted) {
        return false;
      }
    }
    return true;
  }

  int getCoinsRewardForLevel(int level) => (((level - 1) ~/ 5) + 1) * 100;

  bool finishTicket({
    required Subject subject,
    required int ticketNumber,
    required int totalQuestions,
  }) {
    final key = _getTicketKey(subject, ticketNumber);
    final ticket = _ticketsProgress[key];

    if (ticket == null || ticket.answeredQuestions.length < totalQuestions) {
      return false;
    }

    _ticketsProgress[key] = TicketProgress(
      ticketNumber: ticketNumber,
      subject: subject,
      answeredQuestions: ticket.answeredQuestions,
      lastAnsweredIndex: ticket.lastAnsweredIndex,
      isCompleted: true,
    );

    completeLevel(ticketNumber);
    unlockLevel(ticketNumber + 1);

    _saveAndNotify();
    return true;
  }

  void addXP(int xp) {
    if (xp <= 0) return;

    _currentXP += xp;
    while (_currentXP >= xpForNextLevel) {
      _currentXP -= xpForNextLevel;
      _playerLevel++;
      _coins += getCoinsRewardForLevel(_playerLevel);
    }

    _saveAndNotify();
  }

  void completeLevel(int levelNumber) {
    final subject = _currentSubject;
    if (!_completedLevels[subject]!.contains(levelNumber)) {
      _completedLevels[subject]!.add(levelNumber);
      _saveAndNotify();
    }
  }
}
