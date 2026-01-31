import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../audio/audio_manager.dart';

enum Subject { chemistry, math, history }

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

class GameState extends ChangeNotifier {
  // === Константы для работы с памятью ===
  static const String _firstLaunchKey = 'first_launch';
  static const String _ticketsProgressKey = 'ticketsProgress';
  static const String _currentSubjectKey = 'currentSubject';
  static const List<String> _subjectKeys = ['chemistry', 'math', 'history'];
  
  // === Общие настройки ===
  bool _soundEnabled;
  bool _musicEnabled;
  bool _vibrationEnabled;
  double _musicVolume;
  
  int _playerLevel;
  int _currentXP;
  int _coins;
  
  // === Прогресс по предметам ===
  Subject _currentSubject;
  final Map<Subject, int> _currentLevels;
  final Map<Subject, Set<int>> _completedLevels;
  final Map<Subject, Set<int>> _unlockedTickets;
  
  // === Прогресс по билетам ===
  final Map<String, TicketProgress> _ticketsProgress;
  
  // === Магазин ===
  final Set<String> _ownedBackgrounds;
  String _selectedBackground;
  
  final Set<String> _ownedFrames;
  String _selectedFrame;
  
  final Set<String> _ownedAvatars;
  String _selectedAvatar;
  
  // === Достижения ===
  final Set<int> _collectedAchievements;
  
  // === Ник игрока ===
  String _nickname;
  
  // ============ ПУБЛИЧНЫЕ ГЕТТЕРЫ ============
  
  // Основные настройки
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  double get musicVolume => _musicVolume;
  int get playerLevel => _playerLevel;
  int get currentXP => _currentXP;
  int get coins => _coins;
  Subject get currentSubject => _currentSubject;
  String get nickname => _nickname;
  
  // Магазин
  String get selectedBackground => _selectedBackground;
  String get selectedFrame => _selectedFrame;
  String get selectedAvatar => _selectedAvatar;
  
  // Коллекции магазина
  List<String> get ownedBackgrounds => _ownedBackgrounds.toList();
  List<String> get ownedFrames => _ownedFrames.toList();
  List<String> get ownedAvatars => _ownedAvatars.toList();
  
  // Достижения
  Set<int> get collectedAchievements => Set<int>.from(_collectedAchievements);
  
  // Прогресс по предметам
  Map<Subject, int> get currentLevels => Map<Subject, int>.from(_currentLevels);
  Map<Subject, Set<int>> get completedLevels => Map<Subject, Set<int>>.from(_completedLevels);
  Map<Subject, Set<int>> get unlockedTickets => Map<Subject, Set<int>>.from(_unlockedTickets);
  
  // Прогресс по билетам
  Map<String, TicketProgress> get ticketsProgress => Map<String, TicketProgress>.from(_ticketsProgress);
  
  // Геттеры для текущего предмета с кешированием
  int get currentLevel => _currentLevels[_currentSubject] ?? 1;
  Set<int> get subjectCompletedLevels => _completedLevels[_currentSubject] ?? <int>{};
  Set<int> get subjectUnlockedTickets => _unlockedTickets[_currentSubject] ?? <int>{};
  
  // Прогресс уровня
  int get xpForNextLevel => 150;
  double get xpRatio => (currentXP / xpForNextLevel).clamp(0.0, 1.0);
  
  GameState({
    bool soundEnabled = true,
    bool musicEnabled = true,
    bool vibrationEnabled = true,
    double musicVolume = 0.7,
    int playerLevel = 1,
    int currentXP = 0,
    int coins = 0,
    Subject currentSubject = Subject.chemistry,
    Map<Subject, int>? currentLevels,
    Map<Subject, Set<int>>? completedLevels,
    Map<Subject, Set<int>>? unlockedTickets,
    Set<String>? ownedBackgrounds,
    String selectedBackground = 'blue',
    Set<String>? ownedFrames,
    String selectedFrame = 'default',
    Set<String>? ownedAvatars,
    String selectedAvatar = 'default',
    Set<int>? collectedAchievements,
    String nickname = 'Player',
    Map<String, TicketProgress>? ticketsProgress,
  })  : _soundEnabled = soundEnabled,
        _musicEnabled = musicEnabled,
        _vibrationEnabled = vibrationEnabled,
        _musicVolume = musicVolume,
        _playerLevel = playerLevel,
        _currentXP = currentXP,
        _coins = coins,
        _currentSubject = currentSubject,
        _currentLevels = currentLevels ?? {
          Subject.chemistry: 1,
          Subject.math: 1,
          Subject.history: 1,
        },
        _completedLevels = completedLevels ?? {
          Subject.chemistry: <int>{},
          Subject.math: <int>{},
          Subject.history: <int>{},
        },
        _unlockedTickets = unlockedTickets ?? {
          Subject.chemistry: <int>{1},
          Subject.math: <int>{1},
          Subject.history: <int>{1},
        },
        _ownedBackgrounds = ownedBackgrounds ?? {'blue', 'green', 'purple', 'orange'},
        _selectedBackground = selectedBackground,
        _ownedFrames = ownedFrames ?? {'default'},
        _selectedFrame = selectedFrame,
        _ownedAvatars = ownedAvatars ?? {'default'},
        _selectedAvatar = selectedAvatar,
        _collectedAchievements = collectedAchievements ?? <int>{},
        _nickname = nickname,
        _ticketsProgress = ticketsProgress ?? {} {
    _initializeAudio();
  }

  // === Статические методы для проверки первого запуска ===
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final firstLaunch = prefs.getBool(_firstLaunchKey) ?? true;
    if (firstLaunch) {
      await prefs.setBool(_firstLaunchKey, false);
    }
    return firstLaunch;
  }

  // === Инициализация аудио ===
  void _initializeAudio() async {
    await AudioManager().initialize();
    AudioManager().setSoundEnabled(_soundEnabled);
    AudioManager().setMusicEnabled(_musicEnabled);
    AudioManager().setMusicVolume(_musicVolume);
  }

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
      _ticketsProgress[key] = TicketProgress(
        ticketNumber: ticketNumber,
        subject: subject,
        answeredQuestions: Map<int, bool>.from(existingProgress.answeredQuestions)
          ..[questionNumber] = isCorrect,
        lastAnsweredIndex: questionNumber > existingProgress.lastAnsweredIndex
            ? questionNumber
            : existingProgress.lastAnsweredIndex,
        isCompleted: existingProgress.isCompleted,
      );
    } else {
      _ticketsProgress[key] = TicketProgress(
        ticketNumber: ticketNumber,
        subject: subject,
        answeredQuestions: {questionNumber: isCorrect},
        lastAnsweredIndex: questionNumber,
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

  // === Вспомогательные методы ===
  String _getTicketKey(Subject subject, int ticketNumber) {
    return '${subject.index}_$ticketNumber';
  }

  int _getFirstTicketOfLevel(int level) {
    return (level - 1) * 5 + 1;
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

  // === Загрузка ===
  static Future<GameState> load() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Вспомогательные функции для загрузки данных
    Map<Subject, int> loadLevels() {
      final levels = <Subject, int>{};
      for (int i = 0; i < Subject.values.length; i++) {
        levels[Subject.values[i]] = prefs.getInt('${_subjectKeys[i]}_level') ?? 1;
      }
      return levels;
    }
    
    Map<Subject, Set<int>> loadCompleted() {
      final completed = <Subject, Set<int>>{};
      for (int i = 0; i < Subject.values.length; i++) {
        final key = '${_subjectKeys[i]}_completed';
        completed[Subject.values[i]] = (prefs.getStringList(key) ?? [])
            .map(int.parse)
            .toSet();
      }
      return completed;
    }
    
    Map<Subject, Set<int>> loadUnlockedTickets() {
      final unlocked = <Subject, Set<int>>{};
      for (int i = 0; i < Subject.values.length; i++) {
        final key = '${_subjectKeys[i]}_unlocked_tickets';
        unlocked[Subject.values[i]] = (prefs.getStringList(key) ?? ['1'])
            .map(int.parse)
            .toSet();
      }
      return unlocked;
    }
    
    // Загрузка прогресса билетов
    final ticketList = prefs.getStringList(_ticketsProgressKey) ?? [];
    final tickets = <String, TicketProgress>{};
    for (final str in ticketList) {
      try {
        final ticket = TicketProgress.deserialize(str);
        tickets[_getTicketKeyStatic(ticket.subject, ticket.ticketNumber)] = ticket;
      } catch (e) {
        if (kDebugMode) {
          print('Error deserializing ticket: $e');
        }
      }
    }
    
    final subjectName = prefs.getString(_currentSubjectKey) ?? 'chemistry';
    final subjectIndex = _subjectKeys.indexOf(subjectName);
    final subject = subjectIndex != -1 
        ? Subject.values[subjectIndex]
        : Subject.chemistry;

    return GameState(
      soundEnabled: prefs.getBool('soundEnabled') ?? true,
      musicEnabled: prefs.getBool('musicEnabled') ?? true,
      vibrationEnabled: prefs.getBool('vibrationEnabled') ?? true,
      musicVolume: prefs.getDouble('musicVolume') ?? 0.7,
      playerLevel: prefs.getInt('playerLevel') ?? 1,
      currentXP: prefs.getInt('currentXP') ?? 0,
      coins: prefs.getInt('coins') ?? 0,
      currentSubject: subject,
      currentLevels: loadLevels(),
      completedLevels: loadCompleted(),
      unlockedTickets: loadUnlockedTickets(),
      ownedBackgrounds: (prefs.getStringList('ownedBackgrounds') ?? 
          ['blue', 'green', 'purple', 'orange']).toSet(),
      selectedBackground: prefs.getString('selectedBackground') ?? 'blue',
      ownedFrames: (prefs.getStringList('ownedFrames') ?? ['default']).toSet(),
      selectedFrame: prefs.getString('selectedFrame') ?? 'default',
      ownedAvatars: (prefs.getStringList('ownedAvatars') ?? ['default']).toSet(),
      selectedAvatar: prefs.getString('selectedAvatar') ?? 'default',
      collectedAchievements: (prefs.getStringList('collectedAchievements') ?? [])
          .map(int.parse)
          .toSet(),
      nickname: prefs.getString('nickname') ?? 'Player',
      ticketsProgress: tickets,
    );
  }

  static String _getTicketKeyStatic(Subject subject, int ticketNumber) {
    return '${subject.index}_$ticketNumber';
  }

  // === Сохранение ===
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Основные настройки
    await prefs.setBool('soundEnabled', _soundEnabled);
    await prefs.setBool('musicEnabled', _musicEnabled);
    await prefs.setBool('vibrationEnabled', _vibrationEnabled);
    await prefs.setDouble('musicVolume', _musicVolume);
    await prefs.setInt('playerLevel', _playerLevel);
    await prefs.setInt('currentXP', _currentXP);
    await prefs.setInt('coins', _coins);
    await prefs.setString(_currentSubjectKey, _currentSubject.name);
    
    // Прогресс по предметам
    for (int i = 0; i < Subject.values.length; i++) {
      final subject = Subject.values[i];
      final key = _subjectKeys[i];
      
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
      _ticketsProgressKey,
      _ticketsProgress.values.map((t) => t.serialize()).toList(),
    );
  }

  // === Основные операции ===
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

  // === Сеттеры ===
  set setSoundEnabled(bool value) {
    if (_soundEnabled != value) {
      _soundEnabled = value;
      AudioManager().setSoundEnabled(value);
      _saveAndNotify();
    }
  }

  set setMusicEnabled(bool value) {
    if (_musicEnabled != value) {
      _musicEnabled = value;
      AudioManager().setMusicEnabled(value);
      _saveAndNotify();
    }
  }

  set setVibrationEnabled(bool value) {
    if (_vibrationEnabled != value) {
      _vibrationEnabled = value;
      _saveAndNotify();
    }
  }

  set setMusicVolume(double value) {
    final clampedValue = value.clamp(0.0, 1.0);
    if (_musicVolume != clampedValue) {
      _musicVolume = clampedValue;
      AudioManager().setMusicVolume(clampedValue);
      _saveAndNotify();
    }
  }

  void switchSubject(Subject subject) {
    if (_currentSubject != subject) {
      _currentSubject = subject;
      _saveAndNotify();
    }
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

  // === Магазин ===
  void selectBackground(String id) {
    if (_ownedBackgrounds.contains(id) && _selectedBackground != id) {
      _selectedBackground = id;
      _saveAndNotify();
    }
  }

  bool buyBackground(String id, int price) {
    if (_coins >= price && !_ownedBackgrounds.contains(id)) {
      _coins -= price;
      _ownedBackgrounds.add(id);
      _selectedBackground = id;
      _saveAndNotify();
      return true;
    }
    return false;
  }

  void selectFrame(String id) {
    if (_ownedFrames.contains(id) && _selectedFrame != id) {
      _selectedFrame = id;
      _saveAndNotify();
    }
  }

  bool buyFrame(String id, int price) {
    if (_coins >= price && !_ownedFrames.contains(id)) {
      _coins -= price;
      _ownedFrames.add(id);
      _selectedFrame = id;
      _saveAndNotify();
      return true;
    }
    return false;
  }

  void selectAvatar(String id) {
    if (_ownedAvatars.contains(id) && _selectedAvatar != id) {
      _selectedAvatar = id;
      _saveAndNotify();
    }
  }

  bool buyAvatar(String id, int price) {
    if (_coins >= price && !_ownedAvatars.contains(id)) {
      _coins -= price;
      _ownedAvatars.add(id);
      _selectedAvatar = id;
      _saveAndNotify();
      return true;
    }
    return false;
  }

  bool isAchievementCollected(int index) => _collectedAchievements.contains(index);

  void collectAchievement(int index, int reward) {
    if (!_collectedAchievements.contains(index)) {
      _coins += reward;
      _collectedAchievements.add(index);
      _saveAndNotify();
    }
  }

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

  // === Вспомогательные методы ===
  void _saveAndNotify() {
    save();
    notifyListeners();
  }

  // Проверка владения предметами магазина
  bool ownsBackground(String id) => _ownedBackgrounds.contains(id);
  bool ownsFrame(String id) => _ownedFrames.contains(id);
  bool ownsAvatar(String id) => _ownedAvatars.contains(id);

  @override
  void dispose() {
    AudioManager().dispose();
    super.dispose();
  }
}