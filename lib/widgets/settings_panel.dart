import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../data/game_state.dart';
import '../audio/audio_manager.dart';

class SettingsPanel {
  static void open(BuildContext context) {
    final state = context.read<GameState>();
    bool localSound = state.soundEnabled;
    bool localMusic = state.musicEnabled;
    bool localVibration = state.vibrationEnabled;
    double localVolume = state.musicVolume;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.only(right: 16),
          alignment: Alignment.topRight,
          child: StatefulBuilder(
            builder: (context, setLocalState) {
              return Container(
                width: 300,
                margin: const EdgeInsets.only(top: 80),
                decoration: BoxDecoration(
                  color: const Color(0xFF131F24),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF49C0F7).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Заголовок "Настройки"
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.settings,
                            color: Color(0xFF131F24),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "НАСТРОЙКИ",
                            style: TextStyle(
                              fontFamily: 'ClashRoyale',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF131F24),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Прокручиваемое содержимое
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.7,
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Раздел Аудио
                              _sectionHeader(text: "АУДИО"),
                              const SizedBox(height: 12),

                              // Звук
                              _customSwitchRow(
                                label: 'ЗВУКИ',
                                value: localSound,
                                onChanged: (v) async {
                                  HapticFeedback.lightImpact();
                                  setLocalState(() => localSound = v);
                                  state.setSoundEnabled = v;
                                },
                                icon: Icons.volume_up,
                              ),

                              const SizedBox(height: 16),

                              // Музыка
                              _customSwitchRow(
                                label: 'ФОНОВАЯ МУЗЫКА',
                                value: localMusic,
                                onChanged: (v) async {
                                  HapticFeedback.lightImpact();
                                  setLocalState(() => localMusic = v);
                                  state.setMusicEnabled = v;
                                },
                                icon: Icons.music_note,
                              ),

                              // Регулятор громкости музыки
                              if (localMusic) ...[
                                const SizedBox(height: 16),
                                _volumeSlider(
                                  value: localVolume,
                                  onChanged: (v) {
                                    setLocalState(() => localVolume = v);
                                    state.setMusicVolume = v;
                                  },
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Раздел Обратная связь
                              _sectionHeader(text: "ОБРАТНАЯ СВЯЗЬ"),
                              const SizedBox(height: 12),

                              // Вибрация
                              _customSwitchRow(
                                label: 'ВИБРАЦИЯ',
                                value: localVibration,
                                onChanged: (v) {
                                  HapticFeedback.lightImpact();
                                  setLocalState(() => localVibration = v);
                                  state.setVibrationEnabled = v;
                                },
                                icon: Icons.vibration,
                              ),

                              const SizedBox(height: 24),

                              // Раздел Управление
                              _sectionHeader(text: "УПРАВЛЕНИЕ"),
                              const SizedBox(height: 12),

                              // Кнопка сброса прогресса
                              _actionButton(
                                label: 'СБРОСИТЬ ПРОГРЕСС',
                                icon: Icons.restart_alt,
                                color: Colors.redAccent,
                                onTap: () => _confirmResetProgress(context, state),
                              ),

                              const SizedBox(height: 12),

                              // Кнопка поддержки
                              _actionButton(
                                label: 'ПОДДЕРЖКА',
                                icon: Icons.support_agent,
                                color: const Color(0xFF29B6F6),
                                onTap: () => _showSupportMessage(context),
                              ),

                              const SizedBox(height: 20),

                              // УПРОЩЕННАЯ ИНФОРМАЦИЯ О ВЕРСИИ (без аудио системы)
                              _buildVersionInfo(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ==================

  static Widget _sectionHeader({required String text}) {
    return Container(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF49C0F7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  static Widget _customSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A34),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: const Color(0xFF49C0F7),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: const Color(0xFF49C0F7),
                  activeTrackColor: const Color(0xFF49C0F7).withOpacity(0.5),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _volumeSlider({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A34),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Icon(
                      value == 0 ? Icons.volume_off : Icons.volume_up,
                      color: const Color(0xFF49C0F7),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'ГРОМКОСТЬ МУЗЫКИ',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3A42),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(value * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF49C0F7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: onChanged,
            activeColor: const Color(0xFF49C0F7),
            inactiveColor: const Color(0xFF2A3A42),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Тихо',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                Text(
                  'Громко',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1519),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF2A3A42),
        ),
      ),
      child: Column(
        children: [
          Text(
            'EduQuiz v1.0.0',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _confirmResetProgress(
      BuildContext context, GameState state) async {
    HapticFeedback.lightImpact();
    
    try {
      await AudioManager().ensureInitialized();
      await AudioManager().playTapSound();
    } catch (e) {
      print('Audio error: $e');
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131F24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Сбросить прогресс?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Все ваши достижения будут удалены.\nЭто действие нельзя отменить.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'ОТМЕНА',
              style: TextStyle(
                color: Color(0xFF49C0F7),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'СБРОСИТЬ',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AudioManager().ensureInitialized();
        await AudioManager().playTapSound();
      } catch (e) {
        print('Audio error: $e');
      }
      
      await state.resetProgress();
      if (context.mounted) {
        Navigator.pop(context);
        _showSnackBar(
          context,
          'Прогресс сброшен 🧹',
          Icons.check_circle,
        );
      }
    }
  }

  static void _showSupportMessage(BuildContext context) {
    HapticFeedback.lightImpact();
    
    try {
      AudioManager().ensureInitialized().then((_) {
        AudioManager().playTapSound();
      });
    } catch (e) {
      print('Audio error: $e');
    }
    
    Navigator.pop(context);
    _showSnackBar(
      context,
      'support@eduquiz.app 💬',
      Icons.email,
    );
  }

  static void _showSnackBar(BuildContext context, String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1899D5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}