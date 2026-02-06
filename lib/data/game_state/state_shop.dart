part of '../game_state.dart';

extension GameStateShop on GameState {
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

  // === Достижения ===
  bool isAchievementCollected(int index) =>
      _collectedAchievements.contains(index);

  void collectAchievement(int index, int reward) {
    if (!_collectedAchievements.contains(index)) {
      _coins += reward;
      _collectedAchievements.add(index);
      _saveAndNotify();
    }
  }

  // Проверка владения предметами магазина
  bool ownsBackground(String id) => _ownedBackgrounds.contains(id);
  bool ownsFrame(String id) => _ownedFrames.contains(id);
  bool ownsAvatar(String id) => _ownedAvatars.contains(id);
}
