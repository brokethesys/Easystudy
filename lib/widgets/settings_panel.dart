import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../data/game_state.dart';

class SettingsPanel {
  static void open(BuildContext context) {
    final state = context.read<GameState>();
    bool localSound = state.soundEnabled;
    bool localMusic = state.musicEnabled;
    bool localVibration = state.vibrationEnabled;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Меню',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final maxHeight = MediaQuery.of(context).size.height - 60;
            return Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 80, right: 16),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 280,
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131F24),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Кнопка "Настройки"
                          _twoLayerButton(
                            label: "НАСТРОЙКИ",
                            icon: Icons.settings,
                            color: Colors.orangeAccent,
                          ),

                          const SizedBox(height: 12),

                          // Настройки всегда раскрыты
                          _customSwitchRow(
                            label: 'ЗВУК',
                            value: localSound,
                            onChanged: (v) {
                              HapticFeedback.lightImpact();
                              setLocalState(() => localSound = v);
                              state.soundEnabled = v;
                              state.save();
                            },
                          ),
                          _customSwitchRow(
                            label: 'МУЗЫКА',
                            value: localMusic,
                            onChanged: (v) {
                              HapticFeedback.lightImpact();
                              setLocalState(() => localMusic = v);
                              state.musicEnabled = v;
                              state.save();
                            },
                          ),
                          _customSwitchRow(
                            label: 'ВИБРАЦИЯ',
                            value: localVibration,
                            onChanged: (v) {
                              HapticFeedback.lightImpact();
                              setLocalState(() => localVibration = v);
                              state.vibrationEnabled = v;
                              state.save();
                            },
                          ),

                          const SizedBox(height: 16),

                          // Кнопка сброса прогресса
                          _actionButton(
                            label: 'СБРОСИТЬ ПРОГРЕСС',
                            icon: Icons.refresh,
                            color: Colors.redAccent,
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              await state.resetProgress();
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Прогресс успешно сброшен 🧹',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),

                          const SizedBox(height: 8),

                          // Кнопка поддержки
                          _actionButton(
                            label: 'ОБРАТИТЬСЯ В ПОДДЕРЖКУ',
                            icon: Icons.support_agent,
                            color: Colors.lightBlueAccent,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Свяжитесь с нами: support@eduquiz.app 💬',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _twoLayerButton({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Stack(
      children: [
        Positioned(
          top: 4,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1899D5),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF131F24)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'ClashRoyale',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF131F24),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _customSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'ClashRoyale',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 50,
              height: 20,
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: const Color(0xFF49C0F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    left: value ? 28 : -2,
                    top: -2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF131F24),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF49C0F7),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1899D5),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFF131F24)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'ClashRoyale',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF131F24),
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
