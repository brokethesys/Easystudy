part of '../game_state.dart';

extension GameStateStorage on GameState {
  // === Сохранение ===
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    // Основные настройки
    await prefs.setBool('soundEnabled', _soundEnabled);
    await prefs.setBool('musicEnabled', _musicEnabled);
    await prefs.setBool('vibrationEnabled', _vibrationEnabled);
    await prefs.setDouble('musicVolume', _musicVolume);
    await prefs.setInt('themeMode', _themeMode.index);
    await prefs.setInt('playerLevel', _playerLevel);
    await prefs.setInt('currentXP', _currentXP);
    await prefs.setInt('coins', _coins);
    await prefs.setString(GameState._currentSubjectKey, _currentSubject.name);

    // Прогресс по предметам
    for (int i = 0; i < Subject.values.length; i++) {
      final subject = Subject.values[i];
      final key = GameState._subjectKeys[i];

      await prefs.setInt('${key}_level', _currentLevels[subject] ?? 1);
      await prefs.setStringList(
        '${key}_completed',
        _completedLevels[subject]?.map((e) => e.toString()).toList() ?? [],
      );
      await prefs.setStringList(
        '${key}_unlocked_tickets',
        _unlockedTickets[subject]?.map((e) => e.toString()).toList() ?? ['1'],
      );
    }

    // Магазин и настройки
    await prefs.setStringList('ownedBackgrounds', _ownedBackgrounds.toList());
    await prefs.setString('selectedBackground', _selectedBackground);
    await prefs.setStringList('ownedFrames', _ownedFrames.toList());
    await prefs.setString('selectedFrame', _selectedFrame);
    await prefs.setStringList('ownedAvatars', _ownedAvatars.toList());
    await prefs.setString('selectedAvatar', _selectedAvatar);
    await prefs.setStringList(
      'collectedAchievements',
      _collectedAchievements.map((e) => e.toString()).toList(),
    );
    await prefs.setString('nickname', _nickname);

    // Прогресс билетов
    await prefs.setStringList(
      GameState._ticketsProgressKey,
      _ticketsProgress.values.map((t) => t.serialize()).toList(),
    );
  }
}
