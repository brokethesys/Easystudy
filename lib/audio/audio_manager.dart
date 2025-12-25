import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  late AudioPlayer _backgroundPlayer;
  final AudioPlayer _effectsPlayer = AudioPlayer(playerId: 'effects_player');
  
  bool _isInitialized = false;
  bool _musicEnabled = true;
  bool _soundEnabled = true;
  double _musicVolume = 0.7;
  double _soundVolume = 1.0;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _backgroundPlayer = AudioPlayer(playerId: 'background_music');
    
    // Зацикливание музыки
    _backgroundPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (state == PlayerState.completed && _musicEnabled) {
        _playBackgroundMusic();
      }
    });

    _isInitialized = true;
    
    // Если музыка включена, запускаем её
    if (_musicEnabled) {
      await _playBackgroundMusic();
    }
  }

  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  Future<void> _playBackgroundMusic() async {
    if (!_musicEnabled || !_isInitialized) return;

    try {
      if (_backgroundPlayer.state == PlayerState.playing) return;

      await _backgroundPlayer.play(
        AssetSource('audio/background_music.mp3'),
        volume: _musicVolume,
      );
    } catch (e) {
      print('Error playing background music: $e');
    }
  }

  Future<void> playBackgroundMusic() async {
    await ensureInitialized();
    _musicEnabled = true;
    await _playBackgroundMusic();
  }

  Future<void> stopBackgroundMusic() async {
    await ensureInitialized();
    try {
      await _backgroundPlayer.stop();
    } catch (e) {
      print('Error stopping background music: $e');
    }
  }

  Future<void> setMusicVolume(double volume) async {
    await ensureInitialized();
    _musicVolume = volume.clamp(0.0, 1.0);
    if (_backgroundPlayer.state == PlayerState.playing) {
      await _backgroundPlayer.setVolume(_musicVolume);
    }
  }

  Future<void> setMusicEnabled(bool enabled) async {
    await ensureInitialized();
    _musicEnabled = enabled;
    if (enabled) {
      await _playBackgroundMusic();
    } else {
      await stopBackgroundMusic();
    }
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await ensureInitialized();
    _soundEnabled = enabled;
  }

  Future<void> playSound(String assetPath) async {
    await ensureInitialized();
    if (!_soundEnabled) return;

    try {
      await _effectsPlayer.stop();
      await _effectsPlayer.play(AssetSource(assetPath));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  Future<void> playTapSound() async => await playSound('audio/sounds/tap.mp3');
  Future<void> playCorrectSound() async => await playSound('audio/sounds/correct.mp3');
  Future<void> playWrongSound() async => await playSound('audio/sounds/wrong.mp3');
  Future<void> playWinSound() async => await playSound('audio/sounds/win.mp3');
  Future<void> playLevelUpSound() async => await playSound('audio/sounds/level_up.mp3');

  bool get isInitialized => _isInitialized;

  Future<void> dispose() async {
    if (_isInitialized) {
      await _backgroundPlayer.dispose();
      await _effectsPlayer.dispose();
      _isInitialized = false;
    }
  }
}