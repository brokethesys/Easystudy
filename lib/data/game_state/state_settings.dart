part of '../game_state.dart';

extension GameStateSettings on GameState {
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

  set setThemeMode(AppThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _saveAndNotify();
    }
  }

  void switchSubject(Subject subject) {
    if (_currentSubject != subject) {
      _currentSubject = subject;
      _saveAndNotify();
    }
  }
}
