import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color panel;
  final Color border;
  final Color track;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.panel,
    required this.border,
    required this.track,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
  });

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>()!;
  }

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? panel,
    Color? border,
    Color? track,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      panel: panel ?? this.panel,
      border: border ?? this.border,
      track: track ?? this.track,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      border: Color.lerp(border, other.border, t)!,
      track: Color.lerp(track, other.track, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

class AppTheme {
  static const Color darkBase = Color(0xFF121F25);
  static const Color darkAccent = Color(0xFF49C0F7);

  static ThemeData light() {
    const colors = AppColors(
      background: Colors.white,
      surface: Color(0xFFF1F4F6),
      surfaceAlt: Color(0xFFE8EDF1),
      panel: Color(0xFFF7FAFC),
      border: Color(0xFFD0D7DE),
      track: Color(0xFFCBD5DC),
      textPrimary: darkBase,
      textSecondary: Color(0xFF37464F),
      accent: darkBase,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: colors.background,
      colorScheme: const ColorScheme.light(
        primary: darkBase,
        onPrimary: Colors.white,
        secondary: darkBase,
        onSecondary: Colors.white,
        surface: Color(0xFFF1F4F6),
        onSurface: darkBase,
        background: Colors.white,
        onBackground: darkBase,
      ),
      extensions: const [colors],
    );
  }

  static ThemeData dark({required Color background}) {
    final colors = AppColors(
      background: background,
      surface: const Color(0xFF1A2A34),
      surfaceAlt: const Color(0xFF1F2C36),
      panel: const Color(0xFF0A1519),
      border: const Color(0xFF2A3A42),
      track: const Color(0xFF37464F),
      textPrimary: Colors.white,
      textSecondary: Colors.white70,
      accent: darkAccent,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: colors.background,
      colorScheme: const ColorScheme.dark(
        primary: darkAccent,
        onPrimary: Colors.white,
        secondary: darkAccent,
        onSecondary: Colors.white,
        surface: Color(0xFF1A2A34),
        onSurface: Colors.white,
        background: Color(0xFF131F24),
        onBackground: Colors.white,
      ),
      extensions: [colors],
    );
  }
}
