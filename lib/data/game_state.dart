import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Subject { chemistry, math, english }

class GameState extends ChangeNotifier {
  // === Общие настройки ===
  bool soundEnabled;
  bool musicEnabled;
  bool vibrationEnabled;

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

  // === Достижения ===
  Set<int> collectedAchievements;

  GameState({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.vibrationEnabled = true,
    this.playerLevel = 1,
    this.currentXP = 0,
    this.coins = 0,
    this.currentSubject = Subject.chemistry,
    Map<Subject, int>? currentLevels,
    Map<Subject, Set<int>>? completedLevels,
    List<String>? ownedBackgrounds,
    this.selectedBackground = 'blue',
    Set<int>? collectedAchievements,
  })  : currentLevels = currentLevels ??
            {
              Subject.chemistry: 1,
              Subject.math: 1,
              Subject.english: 1,
            },
        completedLevels = completedLevels ??
            {
              Subject.chemistry: {},
              Subject.math: {},
              Subject.english: {},
            },
        ownedBackgrounds = ownedBackgrounds ??
            ['blue', 'green', 'purple', 'orange'],
        collectedAchievements = collectedAchievements ?? {};

  // === Константы ===
  int get xpForNextLevel => 150;

  int get currentLevel => currentLevels[currentSubject] ?? 1;
  Set<int> get subjectCompletedLevels =>
      completedLevels[currentSubject] ?? {};

  int getCoinsRewardForLevel(int level) {
    int rewardStage = ((level - 1) ~/ 5) + 1;
    return rewardStage * 100;
  }

  // === Загрузка и сохранение ===
  static Future<GameState> load() async {
    final prefs = await SharedPreferences.getInstance();

    Map<Subject, int> loadLevels() => {
          Subject.chemistry: prefs.getInt('chemistry_level') ?? 1,
          Subject.math: prefs.getInt('math_level') ?? 1,
          Subject.english: prefs.getInt('english_level') ?? 1,
        };

    Map<Subject, Set<int>> loadCompleted() => {
          Subject.chemistry: (prefs.getStringList('chemistry_completed') ?? [])
              .map(int.parse)
              .toSet(),
          Subject.math: (prefs.getStringList('math_completed') ?? [])
              .map(int.parse)
              .toSet(),
          Subject.english: (prefs.getStringList('english_completed') ?? [])
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
      playerLevel: prefs.getInt('playerLevel') ?? 1,
      currentXP: prefs.getInt('currentXP') ?? 0,
      coins: prefs.getInt('coins') ?? 0,
      currentSubject: subject,
      currentLevels: loadLevels(),
      completedLevels: loadCompleted(),
      ownedBackgrounds: prefs.getStringList('ownedBackgrounds') ??
          ['blue', 'green', 'purple', 'orange'],
      selectedBackground: prefs.getString('selectedBackground') ?? 'blue',
      collectedAchievements:
          (prefs.getStringList('collectedAchievements') ?? [])
              .map(int.parse)
              .toSet(),
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('soundEnabled', soundEnabled);
    await prefs.setBool('musicEnabled', musicEnabled);
    await prefs.setBool('vibrationEnabled', vibrationEnabled);
    await prefs.setInt('playerLevel', playerLevel);
    await prefs.setInt('currentXP', currentXP);
    await prefs.setInt('coins', coins);

    await prefs.setString('currentSubject', currentSubject.name);
    await prefs.setInt('chemistry_level', currentLevels[Subject.chemistry]!);
    await prefs.setInt('math_level', currentLevels[Subject.math]!);
    await prefs.setInt('english_level', currentLevels[Subject.english]!);

    await prefs.setStringList(
        'chemistry_completed',
        completedLevels[Subject.chemistry]!
            .map((e) => e.toString())
            .toList());
    await prefs.setStringList('math_completed',
        completedLevels[Subject.math]!.map((e) => e.toString()).toList());
    await prefs.setStringList('english_completed',
        completedLevels[Subject.english]!.map((e) => e.toString()).toList());

    await prefs.setStringList('ownedBackgrounds', ownedBackgrounds);
    await prefs.setString('selectedBackground', selectedBackground);
    await prefs.setStringList(
      'collectedAchievements',
      collectedAchievements.map((e) => e.toString()).toList(),
    );
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
    currentLevels[subject] =
        currentLevels[subject]! > levelNumber ? currentLevels[subject]! : levelNumber + 1;
    notifyListeners();
    save();
  }

  // === Сброс прогресса ===
  Future<void> resetProgress({Subject? subject}) async {
    if (subject != null) {
      completedLevels[subject]!.clear();
      currentLevels[subject] = 1;
    } else {
      // сброс всех предметов
      for (var s in Subject.values) {
        completedLevels[s]!.clear();
        currentLevels[s] = 1;
      }
      playerLevel = 1;
      currentXP = 0;
      coins = 0;
      ownedBackgrounds = ['blue', 'green', 'purple', 'orange'];
      selectedBackground = 'blue';
      collectedAchievements.clear();
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
}
