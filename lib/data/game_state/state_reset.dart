part of '../game_state.dart';

extension GameStateReset on GameState {
  // === Сброс прогресса ===
  Future<void> resetProgress({Subject? subject}) async {
    if (subject != null) {
      _completedLevels[subject]!.clear();
      _currentLevels[subject] = 1;
      _unlockedTickets[subject] = {1};

      // Удаляем прогресс по билетам этого предмета
      _ticketsProgress.removeWhere((key, value) => value.subject == subject);
    } else {
      for (final s in Subject.values) {
        _completedLevels[s]!.clear();
        _currentLevels[s] = 1;
        _unlockedTickets[s] = {1};
      }

      _playerLevel = 1;
      _currentXP = 0;
      _coins = 0;
      _ownedBackgrounds.clear();
      _ownedBackgrounds.addAll({'blue', 'green', 'purple', 'orange'});
      _selectedBackground = 'blue';
      _ownedFrames.clear();
      _ownedFrames.add('default');
      _selectedFrame = 'default';
      _ownedAvatars.clear();
      _ownedAvatars.add('default');
      _selectedAvatar = 'default';
      _collectedAchievements.clear();
      _ticketsProgress.clear();

      _soundEnabled = true;
      _musicEnabled = true;
      _vibrationEnabled = true;
      _musicVolume = 0.7;

      AudioManager().setSoundEnabled(true);
      AudioManager().setMusicEnabled(true);
      AudioManager().setMusicVolume(0.7);
    }

    notifyListeners();
    await save();
  }
}
