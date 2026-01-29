import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../audio/audio_manager.dart'; // Добавьте этот импорт

enum Subject { chemistry, math, history }

class GameState extends ChangeNotifier {
  // === Общие настройки ===
  bool soundEnabled;
  bool musicEnabled;
  bool vibrationEnabled;
  double musicVolume; // Добавили регулировку громкости

  int playerLevel;
  int currentXP;
  int coins;

  // === Прогресс по предметам ===
  Subject currentSubject;
  Map<Subject, int> currentLevels;
  Map<Subject, Set<int>> completedLevels;

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
    List<String>? ownedBackgrounds,
    this.selectedBackground = 'blue',
    List<String>? ownedFrames,
    this.selectedFrame = 'default',
    List<String>? ownedAvatars,
    this.selectedAvatar = 'default',
    Set<int>? collectedAchievements,
    this.nickname = 'Player',
  }) : currentLevels =
           currentLevels ??
           {Subject.chemistry: 1, Subject.math: 1, Subject.history: 1},
       completedLevels =
           completedLevels ??
           {Subject.chemistry: {}, Subject.math: {}, Subject.history: {}},
       ownedBackgrounds =
           ownedBackgrounds ?? ['blue', 'green', 'purple', 'orange'],
       ownedFrames = ownedFrames ?? ['default'],
       ownedAvatars = ownedAvatars ?? ['default'],
       collectedAchievements = collectedAchievements ?? {} {
    // Инициализируем AudioManager с текущими настройками
    _initializeAudio();
  }

  // === Первый запуск приложения ===
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();

    final isFirst = prefs.getBool('first_launch') ?? true;

    if (isFirst) {
      await prefs.setBool('first_launch', false);
    }

    return isFirst;
  }

  // Инициализация аудио системы
  void _initializeAudio() async {
    await AudioManager().initialize();
    // Синхронизируем настройки с AudioManager
    AudioManager().setSoundEnabled(soundEnabled);
    AudioManager().setMusicEnabled(musicEnabled);
    AudioManager().setMusicVolume(musicVolume);
  }

  // === Константы ===
  int get xpForNextLevel => 150;

  // Для TopHUD: прогресс опыта от 0.0 до 1.0
  double get xpRatio {
    return (currentXP / xpForNextLevel).clamp(0.0, 1.0);
  }

  int get currentLevel => currentLevels[currentSubject] ?? 1;
  Set<int> get subjectCompletedLevels => completedLevels[currentSubject] ?? {};

  int getCoinsRewardForLevel(int level) {
    int rewardStage = ((level - 1) ~/ 5) + 1;
    return rewardStage * 100;
  }

  // === Вспомогательные методы для достижений ===

  int getCompletedLevelsCountWithoutFirst(Subject subject) {
    final completed = completedLevels[subject] ?? {};
    return completed.where((level) => level > 0).length;
  }

  int get totalCompletedLevels {
    int total = 0;
    for (var subject in Subject.values) {
      total += getCompletedLevelsCountWithoutFirst(subject);
    }
    return total;
  }

  int getCurrentMaxLevel(Subject subject) {
    final completed = completedLevels[subject] ?? {};
    return completed.isNotEmpty ? completed.reduce((a, b) => a > b ? a : b) : 0;
  }

  // === Загрузка ===
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
    );
  }

  // === Сохранение ===
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
  }

  // === Сеттеры для настроек звука ===
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

  // === Переключение предмета ===
  void switchSubject(Subject subject) {
    currentSubject = subject;
    notifyListeners();
    save();
  }

  // === Обновления прогресса ===
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

    if (currentLevels[subject]! <= levelNumber) {
      currentLevels[subject] = levelNumber + 1;
    }

    notifyListeners();
    save();
  }

  // === Сброс прогресса ===
  Future<void> resetProgress({Subject? subject}) async {
    if (subject != null) {
      completedLevels[subject]!.clear();
      currentLevels[subject] = 1;
    } else {
      for (var s in Subject.values) {
        completedLevels[s]!.clear();
        currentLevels[s] = 1;
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
      // Сброс настроек аудио к значениям по умолчанию
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

  // === Магазин ===
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

  // === Достижения ===
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

  // === Жизненный цикл ===
  @override
  void dispose() {
    AudioManager().dispose();
    super.dispose();
  }
}
