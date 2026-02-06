part of '../game_state.dart';

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
  AppThemeMode _themeMode;

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
  AppThemeMode get themeMode => _themeMode;
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
  Map<Subject, Set<int>> get completedLevels =>
      Map<Subject, Set<int>>.from(_completedLevels);
  Map<Subject, Set<int>> get unlockedTickets =>
      Map<Subject, Set<int>>.from(_unlockedTickets);

  // Прогресс по билетам
  Map<String, TicketProgress> get ticketsProgress =>
      Map<String, TicketProgress>.from(_ticketsProgress);

  // Геттеры для текущего предмета с кешированием
  int get currentLevel => _currentLevels[_currentSubject] ?? 1;
  Set<int> get subjectCompletedLevels =>
      _completedLevels[_currentSubject] ?? <int>{};
  Set<int> get subjectUnlockedTickets =>
      _unlockedTickets[_currentSubject] ?? <int>{};

  // Прогресс уровня
  int get xpForNextLevel => 150;
  double get xpRatio => (currentXP / xpForNextLevel).clamp(0.0, 1.0);

  GameState({
    bool soundEnabled = true,
    bool musicEnabled = true,
    bool vibrationEnabled = true,
    double musicVolume = 0.7,
    AppThemeMode themeMode = AppThemeMode.system,
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
        _themeMode = themeMode,
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
        _ownedBackgrounds =
            ownedBackgrounds ?? {'blue', 'green', 'purple', 'orange'},
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

  // === Загрузка ===
  static Future<GameState> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Вспомогательные функции для загрузки данных
    Map<Subject, int> loadLevels() {
      final levels = <Subject, int>{};
      for (int i = 0; i < Subject.values.length; i++) {
        levels[Subject.values[i]] =
            prefs.getInt('${_subjectKeys[i]}_level') ?? 1;
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
        tickets[_getTicketKeyStatic(ticket.subject, ticket.ticketNumber)] =
            ticket;
      } catch (e) {
        if (kDebugMode) {
          print('Error deserializing ticket: $e');
        }
      }
    }

    final subjectName = prefs.getString(_currentSubjectKey) ?? 'chemistry';
    final subjectIndex = _subjectKeys.indexOf(subjectName);
    final subject =
        subjectIndex != -1 ? Subject.values[subjectIndex] : Subject.chemistry;

    return GameState(
      soundEnabled: prefs.getBool('soundEnabled') ?? true,
      musicEnabled: prefs.getBool('musicEnabled') ?? true,
      vibrationEnabled: prefs.getBool('vibrationEnabled') ?? true,
      musicVolume: prefs.getDouble('musicVolume') ?? 0.7,
      themeMode: () {
        final saved = prefs.getInt('themeMode');
        if (saved == null ||
            saved < 0 ||
            saved >= AppThemeMode.values.length) {
          return AppThemeMode.system;
        }
        return AppThemeMode.values[saved];
      }(),
      playerLevel: prefs.getInt('playerLevel') ?? 1,
      currentXP: prefs.getInt('currentXP') ?? 0,
      coins: prefs.getInt('coins') ?? 0,
      currentSubject: subject,
      currentLevels: loadLevels(),
      completedLevels: loadCompleted(),
      unlockedTickets: loadUnlockedTickets(),
      ownedBackgrounds:
          (prefs.getStringList('ownedBackgrounds') ??
                  ['blue', 'green', 'purple', 'orange'])
              .toSet(),
      selectedBackground: prefs.getString('selectedBackground') ?? 'blue',
      ownedFrames: (prefs.getStringList('ownedFrames') ?? ['default']).toSet(),
      selectedFrame: prefs.getString('selectedFrame') ?? 'default',
      ownedAvatars: (prefs.getStringList('ownedAvatars') ?? ['default']).toSet(),
      selectedAvatar: prefs.getString('selectedAvatar') ?? 'default',
      collectedAchievements:
          (prefs.getStringList('collectedAchievements') ?? [])
              .map(int.parse)
              .toSet(),
      nickname: prefs.getString('nickname') ?? 'Player',
      ticketsProgress: tickets,
    );
  }

  static String _getTicketKeyStatic(Subject subject, int ticketNumber) {
    return '${subject.index}_$ticketNumber';
  }

  // === Инициализация аудио ===
  void _initializeAudio() async {
    await AudioManager().initialize();
    AudioManager().setSoundEnabled(_soundEnabled);
    AudioManager().setMusicEnabled(_musicEnabled);
    AudioManager().setMusicVolume(_musicVolume);
  }

  // === Вспомогательные методы ===
  String _getTicketKey(Subject subject, int ticketNumber) {
    return '${subject.index}_$ticketNumber';
  }

  int _getFirstTicketOfLevel(int level) {
    return (level - 1) * 5 + 1;
  }

  void _saveAndNotify() {
    save();
    notifyListeners();
  }

  @override
  void dispose() {
    AudioManager().dispose();
    super.dispose();
  }
}
