import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../audio/audio_manager.dart';

enum Subject { chemistry, math, history }

class TicketProgress {
  final int ticketNumber;
  final Subject subject;
  Map<int, bool> answeredQuestions; // ключ: номер вопроса, значение: true/false
  int lastAnsweredIndex; // индекс последнего отвеченного вопроса
  bool isCompleted; // полностью ли завершен билет

  TicketProgress({
    required this.ticketNumber,
    required this.subject,
    Map<int, bool>? answeredQuestions,
    this.lastAnsweredIndex = 0,
    this.isCompleted = false,
  }) : answeredQuestions = answeredQuestions ?? {};

  // Сериализация для SharedPreferences
  String serialize() {
    final answers = answeredQuestions.entries
        .map((e) => "${e.key}:${e.value}")
        .join(",");
    return "${subject.name}|$ticketNumber|$lastAnsweredIndex|$isCompleted|$answers";
  }

  static TicketProgress deserialize(String data) {
    final parts = data.split("|");
    final subject = Subject.values.firstWhere((s) => s.name == parts[0]);
    final ticketNumber = int.parse(parts[1]);
    final lastIndex = parts.length > 2 ? int.parse(parts[2]) : 0;
    final isCompleted = parts.length > 3 ? parts[3] == "true" : false;
    final answers = <int, bool>{};
    if (parts.length > 4 && parts[4].isNotEmpty) {
      for (var q in parts[4].split(",")) {
        final kv = q.split(":");
        answers[int.parse(kv[0])] = kv[1] == "true";
      }
    }
    return TicketProgress(
      ticketNumber: ticketNumber,
      subject: subject,
      lastAnsweredIndex: lastIndex,
      isCompleted: isCompleted,
      answeredQuestions: answers,
    );
  }
}

class GameState extends ChangeNotifier {
  // === Общие настройки ===
  bool soundEnabled;
  bool musicEnabled;
  bool vibrationEnabled;
  double musicVolume;

  int playerLevel;
  int currentXP;
  int coins;

  // === Прогресс по предметам ===
  Subject currentSubject;
  Map<Subject, int> currentLevels;
  Map<Subject, Set<int>> completedLevels;
  Map<Subject, Set<int>>
  unlockedTickets; // Разблокированные билеты для каждого предмета

  // === Прогресс по билетам ===
  Map<String, TicketProgress> ticketsProgress =
      {}; // ключ: "${subject.name}_$ticketNumber"

  // === Магазин ===
  List<String> ownedBackgrounds;
  String selectedBackground;

  List<String> ownedFrames;
  String selectedFrame;

  List<String> ownedAvatars;
  String selectedAvatar;

  // === Достижения ===
  Set<int> collectedAchievements;

  // === Ник игрока ===
  String nickname;

  GameState({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.vibrationEnabled = true,
    this.musicVolume = 0.7,
    this.playerLevel = 1,
    this.currentXP = 0,
    this.coins = 0,
    this.currentSubject = Subject.chemistry,
    Map<Subject, int>? currentLevels,
    Map<Subject, Set<int>>? completedLevels,
    Map<Subject, Set<int>>? unlockedTickets,
    List<String>? ownedBackgrounds,
    this.selectedBackground = 'blue',
    List<String>? ownedFrames,
    this.selectedFrame = 'default',
    List<String>? ownedAvatars,
    this.selectedAvatar = 'default',
    Set<int>? collectedAchievements,
    this.nickname = 'Player',
    Map<String, TicketProgress>? ticketsProgress,
  }) : currentLevels =
           currentLevels ??
           {Subject.chemistry: 1, Subject.math: 1, Subject.history: 1},
       completedLevels =
           completedLevels ??
           {Subject.chemistry: {}, Subject.math: {}, Subject.history: {}},
       unlockedTickets =
           unlockedTickets ??
           {
             Subject.chemistry: {1},
             Subject.math: {1},
             Subject.history: {1},
           },
       ownedBackgrounds =
           ownedBackgrounds ?? ['blue', 'green', 'purple', 'orange'],
       ownedFrames = ownedFrames ?? ['default'],
       ownedAvatars = ownedAvatars ?? ['default'],
       collectedAchievements = collectedAchievements ?? {},
       ticketsProgress = ticketsProgress ?? {} {
    _initializeAudio();
  }

  // === Первый запуск приложения ===
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final firstLaunch = prefs.getBool('first_launch') ?? true;
    if (firstLaunch) await prefs.setBool('first_launch', false);
    return firstLaunch;
  }

  // === Инициализация аудио ===
  void _initializeAudio() async {
    await AudioManager().initialize();
    AudioManager().setSoundEnabled(soundEnabled);
    AudioManager().setMusicEnabled(musicEnabled);
    AudioManager().setMusicVolume(musicVolume);
  }

  // === Константы и прогресс ===
  int get xpForNextLevel => 150;
  double get xpRatio => (currentXP / xpForNextLevel).clamp(0.0, 1.0);
  int get currentLevel => currentLevels[currentSubject] ?? 1;
  Set<int> get subjectCompletedLevels => completedLevels[currentSubject] ?? {};
  Set<int> get subjectUnlockedTickets => unlockedTickets[currentSubject] ?? {};
  int getCoinsRewardForLevel(int level) => (((level - 1) ~/ 5) + 1) * 100;

  // === Проверка блокировки билетов ===
  bool isTicketUnlocked(int ticketNumber) {
    return subjectUnlockedTickets.contains(ticketNumber);
  }

  bool isLevelUnlocked(int levelNumber) {
    return (currentLevels[currentSubject] ?? 1) >= levelNumber;
  }

  // === Прогресс по билетам ===
  void saveAnswer({
    required Subject subject,
    required int ticketNumber,
    required int questionNumber,
    required bool isCorrect,
  }) {
    final key = "${subject.name}_$ticketNumber";
    ticketsProgress[key] ??= TicketProgress(
      ticketNumber: ticketNumber,
      subject: subject,
    );
    ticketsProgress[key]!.answeredQuestions[questionNumber] = isCorrect;

    // обновляем lastAnsweredIndex
    if (questionNumber > ticketsProgress[key]!.lastAnsweredIndex) {
      ticketsProgress[key]!.lastAnsweredIndex = questionNumber;
    }

    save();
    notifyListeners();
  }

  void completeTicket(Subject subject, int ticketNumber) {
    final key = "${subject.name}_$ticketNumber";
    if (ticketsProgress.containsKey(key)) {
      ticketsProgress[key]!.isCompleted = true;
      save();
      notifyListeners();
    }
  }

  TicketProgress? getTicketProgress(Subject subject, int ticketNumber) =>
      ticketsProgress["${subject.name}_$ticketNumber"];

  int getTicketLastIndex(Subject subject, int ticketNumber) =>
      ticketsProgress["${subject.name}_$ticketNumber"]?.lastAnsweredIndex ?? 0;

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

  // === Разблокировка билетов и уровней ===
  void unlockTicket(int ticketNumber) {
    unlockedTickets[currentSubject]!.add(ticketNumber);
    save();
    notifyListeners();
  }

  void unlockLevel(int levelNumber) {
    final current = currentLevels[currentSubject] ?? 1;
    if (levelNumber > current) {
      currentLevels[currentSubject] = levelNumber;
      // При разблокировке нового уровня открываем первый билет этого уровня
      unlockedTickets[currentSubject]!.add(getFirstTicketOfLevel(levelNumber));
      save();
      notifyListeners();
    }
  }

  // === Вспомогательные методы для работы с уровнями ===
  int getFirstTicketOfLevel(int level) {
    // Логика получения первого билета уровня
    // Предположим, что в каждом уровне по 5 билетов
    return (level - 1) * 5 + 1;
  }

  List<int> getTicketsForLevel(int level) {
    // Возвращает список ID билетов для указанного уровня
    // Предположим, что в каждом уровне по 5 билетов
    final List<int> tickets = [];
    final startTicket = (level - 1) * 5 + 1;
    for (int i = 0; i < 5; i++) {
      tickets.add(startTicket + i);
    }
    return tickets;
  }

  // Проверяет, все ли билеты уровня завершены
  bool areAllTicketsCompletedInLevel(int level) {
    final tickets = getTicketsForLevel(level);
    for (var ticketId in tickets) {
      final ticket = getTicketProgress(currentSubject, ticketId);
      if (ticket == null || !ticket.isCompleted) {
        return false;
      }
    }
    return true;
  }

  // === Загрузка GameState ===
  static Future<GameState> load() async {
    final prefs = await SharedPreferences.getInstance();

    Map<Subject, int> loadLevels() => {
      Subject.chemistry: prefs.getInt('chemistry_level') ?? 1,
      Subject.math: prefs.getInt('math_level') ?? 1,
      Subject.history: prefs.getInt('history_level') ?? 1,
    };

    Map<Subject, Set<int>> loadCompleted() => {
      Subject.chemistry: (prefs.getStringList('chemistry_completed') ?? [])
          .map(int.parse)
          .toSet(),
      Subject.math: (prefs.getStringList('math_completed') ?? [])
          .map(int.parse)
          .toSet(),
      Subject.history: (prefs.getStringList('history_completed') ?? [])
          .map(int.parse)
          .toSet(),
    };

    Map<Subject, Set<int>> loadUnlockedTickets() => {
      Subject.chemistry:
          (prefs.getStringList('chemistry_unlocked_tickets') ?? ['1'])
              .map(int.parse)
              .toSet(),
      Subject.math: (prefs.getStringList('math_unlocked_tickets') ?? ['1'])
          .map(int.parse)
          .toSet(),
      Subject.history:
          (prefs.getStringList('history_unlocked_tickets') ?? ['1'])
              .map(int.parse)
              .toSet(),
    };

    final ticketList = prefs.getStringList('ticketsProgress') ?? [];
    Map<String, TicketProgress> tickets = {};
    for (var str in ticketList) {
      final ticket = TicketProgress.deserialize(str);
      tickets["${ticket.subject.name}_${ticket.ticketNumber}"] = ticket;
    }

    final subjectName = prefs.getString('currentSubject') ?? 'chemistry';
    final subject = Subject.values.firstWhere(
      (s) => s.name == subjectName,
      orElse: () => Subject.chemistry,
    );

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
      ownedBackgrounds:
          prefs.getStringList('ownedBackgrounds') ??
          ['blue', 'green', 'purple', 'orange'],
      selectedBackground: prefs.getString('selectedBackground') ?? 'blue',
      ownedFrames: prefs.getStringList('ownedFrames') ?? ['default'],
      selectedFrame: prefs.getString('selectedFrame') ?? 'default',
      ownedAvatars: prefs.getStringList('ownedAvatars') ?? ['default'],
      selectedAvatar: prefs.getString('selectedAvatar') ?? 'default',
      collectedAchievements:
          (prefs.getStringList('collectedAchievements') ?? [])
              .map(int.parse)
              .toSet(),
      nickname: prefs.getString('nickname') ?? 'Player',
      ticketsProgress: tickets,
    );
  }

  // === Сохранение GameState ===
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('soundEnabled', soundEnabled);
    await prefs.setBool('musicEnabled', musicEnabled);
    await prefs.setBool('vibrationEnabled', vibrationEnabled);
    await prefs.setDouble('musicVolume', musicVolume);
    await prefs.setInt('playerLevel', playerLevel);
    await prefs.setInt('currentXP', currentXP);
    await prefs.setInt('coins', coins);
    await prefs.setString('currentSubject', currentSubject.name);
    await prefs.setInt('chemistry_level', currentLevels[Subject.chemistry]!);
    await prefs.setInt('math_level', currentLevels[Subject.math]!);
    await prefs.setInt('history_level', currentLevels[Subject.history]!);
    await prefs.setStringList(
      'chemistry_completed',
      completedLevels[Subject.chemistry]!.map((e) => e.toString()).toList(),
    );
    await prefs.setStringList(
      'math_completed',
      completedLevels[Subject.math]!.map((e) => e.toString()).toList(),
    );
    await prefs.setStringList(
      'history_completed',
      completedLevels[Subject.history]!.map((e) => e.toString()).toList(),
    );
    await prefs.setStringList(
      'chemistry_unlocked_tickets',
      unlockedTickets[Subject.chemistry]!.map((e) => e.toString()).toList(),
    );
    await prefs.setStringList(
      'math_unlocked_tickets',
      unlockedTickets[Subject.math]!.map((e) => e.toString()).toList(),
    );
    await prefs.setStringList(
      'history_unlocked_tickets',
      unlockedTickets[Subject.history]!.map((e) => e.toString()).toList(),
    );
    await prefs.setStringList('ownedBackgrounds', ownedBackgrounds);
    await prefs.setString('selectedBackground', selectedBackground);
    await prefs.setStringList('ownedFrames', ownedFrames);
    await prefs.setString('selectedFrame', selectedFrame);
    await prefs.setStringList('ownedAvatars', ownedAvatars);
    await prefs.setString('selectedAvatar', selectedAvatar);
    await prefs.setStringList(
      'collectedAchievements',
      collectedAchievements.map((e) => e.toString()).toList(),
    );
    await prefs.setString('nickname', nickname);

    // Сохраняем прогресс билетов
    await prefs.setStringList(
      'ticketsProgress',
      ticketsProgress.values.map((t) => t.serialize()).toList(),
    );
  }

  bool finishTicket({
    required Subject subject,
    required int ticketNumber,
    required int totalQuestions,
  }) {
    final key = "${subject.name}_$ticketNumber";
    final ticket = ticketsProgress[key];

    if (ticket == null) return false;
    if (ticket.answeredQuestions.length < totalQuestions) return false;

    ticket.isCompleted = true;

    // ⬇️ ВАЖНО
    completeLevel(ticketNumber);
    unlockLevel(ticketNumber + 1);

    save();
    notifyListeners();
    return true;
  }

  // === Сеттеры и функционал магазина, уровней, XP ===
  set setSoundEnabled(bool value) {
    soundEnabled = value;
    AudioManager().setSoundEnabled(value);
    notifyListeners();
    save();
  }

  set setMusicEnabled(bool value) {
    musicEnabled = value;
    AudioManager().setMusicEnabled(value);
    notifyListeners();
    save();
  }

  set setVibrationEnabled(bool value) {
    vibrationEnabled = value;
    notifyListeners();
    save();
  }

  set setMusicVolume(double value) {
    musicVolume = value.clamp(0.0, 1.0);
    AudioManager().setMusicVolume(value);
    notifyListeners();
    save();
  }

  void switchSubject(Subject subject) {
    currentSubject = subject;
    notifyListeners();
    save();
  }

  void addXP(int xp) {
    currentXP += xp;
    while (currentXP >= xpForNextLevel) {
      currentXP -= xpForNextLevel;
      playerLevel++;
      coins += getCoinsRewardForLevel(playerLevel);
    }
    notifyListeners();
    save();
  }

  void completeLevel(int levelNumber) {
    final subject = currentSubject;
    completedLevels[subject]!.add(levelNumber);
    notifyListeners();
    save();
  }

  // === Магазин и достижения ===
  void selectBackground(String id) {
    if (ownedBackgrounds.contains(id)) {
      selectedBackground = id;
      notifyListeners();
      save();
    }
  }

  bool buyBackground(String id, int price) {
    if (coins >= price && !ownedBackgrounds.contains(id)) {
      coins -= price;
      ownedBackgrounds.add(id);
      selectedBackground = id;
      notifyListeners();
      save();
      return true;
    }
    return false;
  }

  void selectFrame(String id) {
    if (ownedFrames.contains(id)) {
      selectedFrame = id;
      notifyListeners();
      save();
    }
  }

  bool buyFrame(String id, int price) {
    if (coins >= price && !ownedFrames.contains(id)) {
      coins -= price;
      ownedFrames.add(id);
      selectedFrame = id;
      notifyListeners();
      save();
      return true;
    }
    return false;
  }

  void selectAvatar(String id) {
    if (ownedAvatars.contains(id)) {
      selectedAvatar = id;
      notifyListeners();
      save();
    }
  }

  bool buyAvatar(String id, int price) {
    if (coins >= price && !ownedAvatars.contains(id)) {
      coins -= price;
      ownedAvatars.add(id);
      selectedAvatar = id;
      notifyListeners();
      save();
      return true;
    }
    return false;
  }

  bool isAchievementCollected(int index) =>
      collectedAchievements.contains(index);

  void collectAchievement(int index, int reward) {
    if (!collectedAchievements.contains(index)) {
      coins += reward;
      collectedAchievements.add(index);
      notifyListeners();
      save();
    }
  }

  Future<void> resetProgress({Subject? subject}) async {
    if (subject != null) {
      completedLevels[subject]!.clear();
      currentLevels[subject] = 1;
      unlockedTickets[subject] = {1};
      // Удаляем прогресс по билетам этого предмета
      ticketsProgress.removeWhere((key, value) => value.subject == subject);
    } else {
      for (var s in Subject.values) {
        completedLevels[s]!.clear();
        currentLevels[s] = 1;
        unlockedTickets[s] = {1};
      }
      playerLevel = 1;
      currentXP = 0;
      coins = 0;
      ownedBackgrounds = ['blue', 'green', 'purple', 'orange'];
      selectedBackground = 'blue';
      ownedFrames = ['default'];
      selectedFrame = 'default';
      ownedAvatars = ['default'];
      selectedAvatar = 'default';
      collectedAchievements.clear();
      ticketsProgress.clear();
      soundEnabled = true;
      musicEnabled = true;
      vibrationEnabled = true;
      musicVolume = 0.7;
      AudioManager().setSoundEnabled(true);
      AudioManager().setMusicEnabled(true);
      AudioManager().setMusicVolume(0.7);
    }
    notifyListeners();
    await save();
  }

  @override
  void dispose() {
    AudioManager().dispose();
    super.dispose();
  }
}
