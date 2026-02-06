part of '../game_state.dart';

extension GameStateConfig on GameState {
  // === Экспорт/импорт конфигурации (для облачной синхронизации) ===
  Map<String, dynamic> toConfigMap() {
    return {
      'version': 1,
      'soundEnabled': _soundEnabled,
      'musicEnabled': _musicEnabled,
      'vibrationEnabled': _vibrationEnabled,
      'musicVolume': _musicVolume,
      'themeMode': _themeMode.index,
      'playerLevel': _playerLevel,
      'currentXP': _currentXP,
      'coins': _coins,
      'currentSubject': _currentSubject.name,
      'currentLevels': _mapSubjectInt(_currentLevels),
      'completedLevels': _mapSubjectSet(_completedLevels),
      'unlockedTickets': _mapSubjectSet(_unlockedTickets),
      'ticketsProgress':
          _ticketsProgress.values.map((t) => t.serialize()).toList(),
      'ownedBackgrounds': _ownedBackgrounds.toList(),
      'selectedBackground': _selectedBackground,
      'ownedFrames': _ownedFrames.toList(),
      'selectedFrame': _selectedFrame,
      'ownedAvatars': _ownedAvatars.toList(),
      'selectedAvatar': _selectedAvatar,
      'collectedAchievements': _collectedAchievements.toList(),
      'nickname': _nickname,
    };
  }

  Future<void> applyConfigMap(Map<String, dynamic> config) async {
    bool changed = false;

    T? read<T>(String key) {
      final value = config[key];
      return value is T ? value : null;
    }

    final soundEnabled = read<bool>('soundEnabled');
    if (soundEnabled != null) {
      _soundEnabled = soundEnabled;
      AudioManager().setSoundEnabled(soundEnabled);
      changed = true;
    }

    final musicEnabled = read<bool>('musicEnabled');
    if (musicEnabled != null) {
      _musicEnabled = musicEnabled;
      AudioManager().setMusicEnabled(musicEnabled);
      changed = true;
    }

    final vibrationEnabled = read<bool>('vibrationEnabled');
    if (vibrationEnabled != null) {
      _vibrationEnabled = vibrationEnabled;
      changed = true;
    }

    final musicVolume = read<num>('musicVolume');
    if (musicVolume != null) {
      _musicVolume = musicVolume.toDouble().clamp(0.0, 1.0);
      AudioManager().setMusicVolume(_musicVolume);
      changed = true;
    }

    final themeModeIndex = read<int>('themeMode');
    if (themeModeIndex != null &&
        themeModeIndex >= 0 &&
        themeModeIndex < AppThemeMode.values.length) {
      _themeMode = AppThemeMode.values[themeModeIndex];
      changed = true;
    }

    final playerLevel = read<int>('playerLevel');
    if (playerLevel != null) {
      _playerLevel = playerLevel;
      changed = true;
    }

    final currentXP = read<int>('currentXP');
    if (currentXP != null) {
      _currentXP = currentXP;
      changed = true;
    }

    final coins = read<int>('coins');
    if (coins != null) {
      _coins = coins;
      changed = true;
    }

    final subjectName = read<String>('currentSubject');
    if (subjectName != null) {
      final next = Subject.values.firstWhere(
        (s) => s.name == subjectName,
        orElse: () => _currentSubject,
      );
      _currentSubject = next;
      changed = true;
    }

    final levels = _readSubjectIntMap(config['currentLevels']);
    if (levels != null) {
      _currentLevels
        ..clear()
        ..addAll(levels);
      changed = true;
    }

    final completed = _readSubjectSetMap(config['completedLevels']);
    if (completed != null) {
      _completedLevels
        ..clear()
        ..addAll(completed);
      changed = true;
    }

    final unlocked = _readSubjectSetMap(config['unlockedTickets']);
    if (unlocked != null) {
      _unlockedTickets
        ..clear()
        ..addAll(unlocked);
      changed = true;
    }

    final tickets = config['ticketsProgress'];
    if (tickets is List) {
      final parsed = <String, TicketProgress>{};
      for (final item in tickets) {
        if (item is String) {
          try {
            final ticket = TicketProgress.deserialize(item);
            parsed[GameState._getTicketKeyStatic(
              ticket.subject,
              ticket.ticketNumber,
            )] =
                ticket;
          } catch (_) {}
        }
      }
      _ticketsProgress
        ..clear()
        ..addAll(parsed);
      changed = true;
    }

    final ownedBackgrounds = _readStringSet(config['ownedBackgrounds']);
    if (ownedBackgrounds != null) {
      _ownedBackgrounds
        ..clear()
        ..addAll(ownedBackgrounds);
      changed = true;
    }

    final selectedBackground = read<String>('selectedBackground');
    if (selectedBackground != null) {
      _selectedBackground = selectedBackground;
      changed = true;
    }

    final ownedFrames = _readStringSet(config['ownedFrames']);
    if (ownedFrames != null) {
      _ownedFrames
        ..clear()
        ..addAll(ownedFrames);
      changed = true;
    }

    final selectedFrame = read<String>('selectedFrame');
    if (selectedFrame != null) {
      _selectedFrame = selectedFrame;
      changed = true;
    }

    final ownedAvatars = _readStringSet(config['ownedAvatars']);
    if (ownedAvatars != null) {
      _ownedAvatars
        ..clear()
        ..addAll(ownedAvatars);
      changed = true;
    }

    final selectedAvatar = read<String>('selectedAvatar');
    if (selectedAvatar != null) {
      _selectedAvatar = selectedAvatar;
      changed = true;
    }

    final achievements = config['collectedAchievements'];
    if (achievements is List) {
      final parsed = <int>{};
      for (final item in achievements) {
        if (item is int) {
          parsed.add(item);
        } else if (item is String) {
          final parsedInt = int.tryParse(item);
          if (parsedInt != null) parsed.add(parsedInt);
        }
      }
      _collectedAchievements
        ..clear()
        ..addAll(parsed);
      changed = true;
    }

    final nickname = read<String>('nickname');
    if (nickname != null) {
      _nickname = nickname;
      changed = true;
    }

    if (changed) {
      notifyListeners();
      await save();
    }
  }

  static Map<String, dynamic> _mapSubjectInt(
    Map<Subject, int> source,
  ) {
    return {
      for (final entry in source.entries) entry.key.name: entry.value,
    };
  }

  static Map<String, List<int>> _mapSubjectSet(
    Map<Subject, Set<int>> source,
  ) {
    return {
      for (final entry in source.entries) entry.key.name: entry.value.toList(),
    };
  }

  Map<Subject, int>? _readSubjectIntMap(dynamic raw) {
    if (raw is! Map) return null;
    final result = <Subject, int>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! int) continue;
      final subject = Subject.values.firstWhere(
        (s) => s.name == key,
        orElse: () => Subject.chemistry,
      );
      result[subject] = value;
    }
    return result.isEmpty ? null : result;
  }

  Map<Subject, Set<int>>? _readSubjectSetMap(dynamic raw) {
    if (raw is! Map) return null;
    final result = <Subject, Set<int>>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! List) continue;
      final subject = Subject.values.firstWhere(
        (s) => s.name == key,
        orElse: () => Subject.chemistry,
      );
      final items = <int>{};
      for (final item in value) {
        if (item is int) {
          items.add(item);
        } else if (item is String) {
          final parsed = int.tryParse(item);
          if (parsed != null) items.add(parsed);
        }
      }
      result[subject] = items;
    }
    return result.isEmpty ? null : result;
  }

  Set<String>? _readStringSet(dynamic raw) {
    if (raw is! List) return null;
    final result = <String>{};
    for (final item in raw) {
      if (item is String) result.add(item);
    }
    return result.isEmpty ? null : result;
  }
}
