import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/game_state.dart';

class SettingsPanel {
  static void open(BuildContext context) {
    final state = context.read<GameState>();
    bool localSound = state.soundEnabled;
    bool localMusic = state.musicEnabled;
    bool localVibration = state.vibrationEnabled;

    bool showSettings = false;
    bool showSubjects = false;
    Subject currentSubject = state.currentSubject;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Меню',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 80, right: 16),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade900.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // === Кнопка выбора предмета ===
                        GestureDetector(
                          onTap: () => setLocalState(() {
                            showSubjects = !showSubjects;
                          }),
                          child: _gradientButton(
                            label: _subjectName(currentSubject),
                            icon: Icons.school,
                            expanded: showSubjects,
                            colors: const [Colors.cyan, Colors.blue],
                          ),
                        ),

                        // === Список предметов ===
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          height: showSubjects ? 170 : 0,
                          margin: const EdgeInsets.only(top: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: Column(
                                children: [
                                  for (var subj in [
                                    Subject.chemistry,
                                    Subject.english,
                                    Subject.math,
                                  ])
                                    GestureDetector(
                                      onTap: () {
                                        setLocalState(() {
                                          currentSubject = subj;
                                        });
                                        state.switchSubject(subj);
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 6),
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Color(0xFF4FC3F7),
                                              Color(0xFF0288D1),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.4),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: _outlinedText(
                                              _subjectName(subj), 16),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // === Кнопка "Настройки" ===
                        GestureDetector(
                          onTap: () => setLocalState(() {
                            showSettings = !showSettings;
                          }),
                          child: _gradientButton(
                            label: "Настройки",
                            icon: Icons.settings,
                            expanded: showSettings,
                            colors: const [
                              Colors.orangeAccent,
                              Colors.deepOrange,
                            ],
                          ),
                        ),

                        // === Содержимое настроек ===
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          height: showSettings ? 380 : 0,
                          margin: const EdgeInsets.only(top: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: Column(
                                children: [
                                  _buildRoyaleSwitch(
                                    icon: Icons.volume_up,
                                    label: 'Звук',
                                    value: localSound,
                                    onChanged: (v) {
                                      setLocalState(() => localSound = v);
                                      state.soundEnabled = v;
                                      state.save();
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _buildRoyaleSwitch(
                                    icon: Icons.music_note,
                                    label: 'Музыка',
                                    value: localMusic,
                                    onChanged: (v) {
                                      setLocalState(() => localMusic = v);
                                      state.musicEnabled = v;
                                      state.save();
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _buildRoyaleSwitch(
                                    icon: Icons.vibration,
                                    label: 'Вибрация при ответах',
                                    value: localVibration,
                                    onChanged: (v) {
                                      setLocalState(() => localVibration = v);
                                      state.vibrationEnabled = v;
                                      state.save();
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _actionButton(
                                    context,
                                    label: 'Сбросить прогресс',
                                    icon: Icons.refresh,
                                    colors: const [
                                      Colors.redAccent,
                                      Colors.red,
                                    ],
                                    onTap: () async {
                                      await state.resetProgress();
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content:
                                              Text('Прогресс успешно сброшен 🧹'),
                                          behavior: SnackBarBehavior.floating,
                                        ));
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _actionButton(
                                    context,
                                    label: 'Обратиться в поддержку',
                                    icon: Icons.support_agent,
                                    colors: const [
                                      Colors.lightBlueAccent,
                                      Colors.blue,
                                    ],
                                    onTap: () {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Свяжитесь с нами: support@eduquiz.app 💬'),
                                        behavior: SnackBarBehavior.floating,
                                      ));
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curved = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  // === Вспомогательные функции ===
  static String _subjectName(Subject subj) {
    switch (subj) {
      case Subject.chemistry:
        return "Химия";
      case Subject.math:
        return "Математика";
      case Subject.english:
        return "Английский язык";
    }
  }

  // === Элементы интерфейса ===

  static Widget _gradientButton({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required bool expanded,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          _outlinedText(label, 16),
          Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  static Widget _buildRoyaleSwitch({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: value
              ? LinearGradient(colors: [
                  Colors.lightBlue.shade300,
                  Colors.blue.shade600,
                  Colors.blue.shade800,
                ])
              : LinearGradient(colors: [
                  Colors.grey.shade400,
                  Colors.grey.shade600,
                  Colors.grey.shade800,
                ]),
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: _outlinedText(label, 16)),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.greenAccent,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _outlinedText(String text, double size) {
    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontFamily: 'ClashRoyale',
            fontSize: size,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = Colors.black,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'ClashRoyale',
            fontSize: size,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  static Widget _actionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            _outlinedText(label, 14),
          ],
        ),
      ),
    );
  }
}
