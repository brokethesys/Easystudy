import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../data/account_service.dart';
import '../data/backend_client.dart';
import '../data/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/settings_panel.dart';
import '../widgets/themed_action_button.dart';
import '../widgets/themed_blue_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool localSound;
  late bool localMusic;
  late bool localVibration;
  late double localVolume;
  late AppThemeMode localThemeMode;

  @override
  void initState() {
    super.initState();
    final state = context.read<GameState>();
    localSound = state.soundEnabled;
    localMusic = state.musicEnabled;
    localVibration = state.vibrationEnabled;
    localVolume = state.musicVolume;
    localThemeMode = state.themeMode;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<GameState>();
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orangeAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "НАСТРОЙКИ",
          style: TextStyle(
            fontFamily: 'ClashRoyale',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: colors.border,
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ================= Аудио =================
              _sectionHeader(text: "АУДИО", colors: colors),
              const SizedBox(height: 12),
              _customSwitchRow(
                label: 'ЗВУКИ',
                value: localSound,
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  setState(() => localSound = v);
                  state.setSoundEnabled = v;
                },
                colors: colors,
              ),
              const SizedBox(height: 16),
              _customSwitchRow(
                label: 'ФОНОВАЯ МУЗЫКА',
                value: localMusic,
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  setState(() => localMusic = v);
                  state.setMusicEnabled = v;
                },
                colors: colors,
              ),
              if (localMusic) ...[
                const SizedBox(height: 16),
                _volumeSlider(
                  value: localVolume,
                  colors: colors,
                  onChanged: (v) {
                    setState(() => localVolume = v);
                    state.setMusicVolume = v;
                  },
                ),
              ],

              const SizedBox(height: 24),
              // ================= Тема =================
              _sectionHeader(text: "ТЕМА", colors: colors),
              const SizedBox(height: 12),
              _themeModeSelector(
                context: context,
                current: localThemeMode,
                colors: colors,
                onChanged: (mode) {
                  HapticFeedback.lightImpact();
                  setState(() => localThemeMode = mode);
                  state.setThemeMode = mode;
                },
              ),

              const SizedBox(height: 24),
              // ================= Вибрация =================
              _sectionHeader(text: "ОБРАТНАЯ СВЯЗЬ", colors: colors),
              const SizedBox(height: 12),
              _customSwitchRow(
                label: 'ВИБРАЦИЯ',
                value: localVibration,
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  setState(() => localVibration = v);
                  state.setVibrationEnabled = v;
                },
                colors: colors,
              ),

              const SizedBox(height: 24),
              // ================= Поддержка =================
              _actionButton(
                context: context,
                label: 'ПОДДЕРЖКА',
                icon: Icons.support_agent,
                variant: ThemedActionButtonVariant.blue,
                onTap: () => _showSupportMessage(context),
              ),

              const SizedBox(height: 24),
              _sectionHeader(text: "АККАУНТ", colors: colors),
              const SizedBox(height: 12),
              _actionButton(
                context: context,
                label: 'ВОЙТИ / РЕГИСТРАЦИЯ',
                icon: Icons.person,
                variant: ThemedActionButtonVariant.blue,
                onTap: () => SettingsPanel.openAccountDialog(context),
              ),
              const SizedBox(height: 12),
              _actionButton(
                context: context,
                label: 'СИНХРОНИЗИРОВАТЬ',
                icon: Icons.sync,
                variant: ThemedActionButtonVariant.green,
                onTap: () => _syncNow(context),
              ),

              const SizedBox(height: 20),
              _buildVersionInfo(colors),
            ],
          ),
        ),
      ),
    );
  }

  // ================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ==================
  static Widget _sectionHeader({
    required String text,
    required AppColors colors,
  }) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: colors.accent,
        letterSpacing: 1.2,
      ),
    );
  }

  // Стиль переключателя - более узкий и компактный
  static Widget _customSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required AppColors colors,
  }) {
    final Color activeColor = colors.accent;
    final Color inactiveColor = colors.border;
    final Color thumbColor = colors.panel;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Название функции
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          // Переключатель - более узкий
          GestureDetector(
            onTap: () => onChanged(!value),
            child: SizedBox(
              width: 58, // Уменьшил ширину (было 68) - теперь менее массивный
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Прямоугольник с скругленными краями - БЕЗ ОБВОДКИ
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 26, // Уменьшил высоту (было 32)
                    decoration: BoxDecoration(
                      color: value ? activeColor : inactiveColor,
                      borderRadius: BorderRadius.circular(13), // Соответственно уменьшил скругление
                    ),
                  ),
                  
                  // Подвижный квадратик - тоже уменьшил немного
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 34, // Уменьшил размер квадратика (было 40)
                      height: 34, // Уменьшил размер квадратика (было 40)
                    decoration: BoxDecoration(
                      color: thumbColor,
                      borderRadius: BorderRadius.circular(6), // Чуть меньше скругление
                      border: Border.all(
                        color: value ? activeColor : inactiveColor,
                        width: 1.5, // Немного тоньше обводка
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 3,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
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

  static Widget _volumeSlider({
    required double value,
    required AppColors colors,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          value: value,
          min: 0,
          max: 1,
          divisions: 10,
          onChanged: onChanged,
          activeColor: colors.accent,
          inactiveColor: colors.border,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Тихо",
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            Text(
              "Громко",
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _actionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    ThemedActionButtonVariant variant = ThemedActionButtonVariant.custom,
  }) {
    if (variant == ThemedActionButtonVariant.blue) {
      return ThemedBlueButton(
        label: label,
        icon: icon,
        onTap: onTap,
      );
    }

    return ThemedActionButton(
      label: label,
      icon: icon,
      onTap: onTap,
      color: color,
      variant: variant,
    );
  }

  static Color _blueButtonTextColor(BuildContext context, Color buttonColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBlue = buttonColor.value == 0xFF49C0F7 ||
        buttonColor.value == 0xFF29B6F6 ||
        buttonColor.value == AppTheme.darkAccent.value;
    if (isDark && isBlue) {
      return const Color(0xFF102124);
    }
    return Colors.white;
  }


  static Widget _buildVersionInfo(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        'EasyStudy v1.0.0',
        style: TextStyle(
          fontSize: 11,
          color: colors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  static Widget _themeModeSelector({
    required BuildContext context,
    required AppThemeMode current,
    required AppColors colors,
    required ValueChanged<AppThemeMode> onChanged,
  }) {
    Widget buildOption(AppThemeMode mode, String label) {
      final bool isSelected = current == mode;
      final Color selectedText =
          _blueButtonTextColor(context, colors.accent);
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(mode),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? colors.accent : colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? selectedText : colors.textPrimary,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        buildOption(AppThemeMode.system, 'Системная'),
        const SizedBox(width: 8),
        buildOption(AppThemeMode.light, 'Светлая'),
        const SizedBox(width: 8),
        buildOption(AppThemeMode.dark, 'Темная'),
      ],
    );
  }

  void _showSupportMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('telegram username: @yaivanov 💬')),
    );
  }

  Future<void> _syncNow(BuildContext context) async {
    HapticFeedback.lightImpact();
    final account = AccountService();
    final state = context.read<GameState>();

    try {
      await account.syncUp(state);
      if (context.mounted) {
        _showSnackBar(
          context,
          'Сохранения синхронизированы',
          Icons.cloud_done,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(
          context,
          _friendlyError(e),
          Icons.error_outline,
        );
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, IconData icon) {
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

  String _friendlyError(Object error) {
    if (error is AuthRequiredException) {
      return 'Сначала выполните вход';
    }
    if (error is BackendException) {
      return error.message;
    }
    return 'Не удалось связаться с сервером';
  }
}
