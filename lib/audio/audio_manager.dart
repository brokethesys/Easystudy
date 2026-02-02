import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// Глобальный менеджер аудио:
/// - фоновая музыка (loop)
/// - короткие звуковые эффекты
///
/// Реализован как singleton, т.к. должен существовать в одном экземпляре
class AudioManager {
  /* =======================
     SINGLETON
     ======================= */

  static final AudioManager _instance = AudioManager._internal();

  factory AudioManager() => _instance;

  AudioManager._internal();

  /* =======================
     PLAYERS
     ======================= */

  AudioPlayer? _backgroundPlayer;
  AudioPlayer? _effectsPlayer;

  /* =======================
     STATE
     ======================= */

  bool _isInitialized = false;

  bool _musicEnabled = true;
  bool _soundEnabled = true;

  double _musicVolume = 0.7;
  double _soundVolume = 1.0;

  /* =======================
     AUDIO SOURCES (CACHE)
     ======================= */

  /// Фоновая музыка кэшируется один раз
  static final AssetSource _backgroundMusic = AssetSource(
    'audio/background_music.mp3',
  );

  /// Карта всех звуковых эффектов
  static final Map<String, AssetSource> _soundEffects = {
    'tap': AssetSource('audio/sounds/tap.mp3'),
    'correct': AssetSource('audio/sounds/correct.mp3'),
    'wrong': AssetSource('audio/sounds/wrong.mp3'),
    'win': AssetSource('audio/sounds/win.mp3'),
    'level_up': AssetSource('audio/sounds/level_up.mp3'),
  };

  /* =======================
     INITIALIZATION
     ======================= */

  /// Инициализация аудиосистемы.
  /// Безопасно вызывать несколько раз.
  Future<void> initialize() async {
    if (_isInitialized) return;

    _backgroundPlayer = AudioPlayer(playerId: 'background_music');
    _effectsPlayer = AudioPlayer(playerId: 'effects_player');

    // Фоновая музыка всегда зациклена
    await _backgroundPlayer!.setReleaseMode(ReleaseMode.loop);
    await _backgroundPlayer!.setVolume(_musicVolume);

    _isInitialized = true;

    // Автозапуск фоновой музыки, если разрешено
    if (_musicEnabled) {
      await _backgroundPlayer!.play(_backgroundMusic);
    }
  }

  /// Гарантирует, что AudioManager готов к работе
  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /* =======================
     BACKGROUND MUSIC
     ======================= */

  Future<void> playBackgroundMusic() async {
    await ensureInitialized();
    _musicEnabled = true;

    if (_backgroundPlayer!.state != PlayerState.playing) {
      await _backgroundPlayer!.resume();
    }
  }

  Future<void> stopBackgroundMusic() async {
    await ensureInitialized();
    await _backgroundPlayer!.pause();
  }

  /// Полное включение / выключение фоновой музыки
  Future<void> setMusicEnabled(bool enabled) async {
    await ensureInitialized();
    _musicEnabled = enabled;

    if (enabled) {
      await playBackgroundMusic();
    } else {
      await stopBackgroundMusic();
    }
  }

  Future<void> setMusicVolume(double volume) async {
    await ensureInitialized();
    _musicVolume = volume.clamp(0.0, 1.0);
    await _backgroundPlayer!.setVolume(_musicVolume);
  }

  /* =======================
     SOUND EFFECTS
     ======================= */

  Future<void> setSoundEnabled(bool enabled) async {
    await ensureInitialized();
    _soundEnabled = enabled;
  }

  Future<void> setSoundVolume(double volume) async {
    await ensureInitialized();
    _soundVolume = volume.clamp(0.0, 1.0);
    await _effectsPlayer!.setVolume(_soundVolume);
  }

  /// Проигрывает эффект по ключу из [_soundEffects]
  Future<void> playSound(String key) async {
    await ensureInitialized();
    if (!_soundEnabled) return;

    final source = _soundEffects[key];
    if (source == null) return;

    await _effectsPlayer!.play(source, volume: _soundVolume);
  }

  /* =======================
     SHORTCUTS
     ======================= */

  Future<void> playTapSound() => playSound('tap');
  Future<void> playCorrectSound() => playSound('correct');
  Future<void> playWrongSound() => playSound('wrong');
  Future<void> playWinSound() => playSound('win');
  Future<void> playLevelUpSound() => playSound('level_up');

  /* =======================
     LIFECYCLE
     ======================= */

  bool get isInitialized => _isInitialized;

  /// ⚠️ Вызывать ТОЛЬКО при полном закрытии приложения
  Future<void> dispose() async {
    if (!_isInitialized) return;

    await _backgroundPlayer?.dispose();
    await _effectsPlayer?.dispose();

    _backgroundPlayer = null;
    _effectsPlayer = null;
    _isInitialized = false;
  }
}
