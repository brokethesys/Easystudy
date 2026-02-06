import 'package:flutter/material.dart';

import '../audio/audio_manager.dart';
import '../theme/app_theme.dart';

enum ThemedActionButtonVariant { custom, green, blue }

class ThemedActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final ThemedActionButtonVariant variant;
  final Color? color;
  final bool playTapSound;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;
  final TextStyle? textStyle;

  const ThemedActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.variant = ThemedActionButtonVariant.custom,
    this.color,
    this.playTapSound = false,
    this.margin = const EdgeInsets.only(bottom: 8),
    this.padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    this.borderRadius = 10,
    this.boxShadow,
    this.width,
    this.height,
    this.textStyle,
  }) : assert(
          variant == ThemedActionButtonVariant.custom || color == null,
          'Color must be null when using green/blue variant.',
        );

  const ThemedActionButton.green({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.playTapSound = false,
    this.margin = const EdgeInsets.only(bottom: 8),
    this.padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    this.borderRadius = 10,
    this.boxShadow,
    this.width,
    this.height,
    this.textStyle,
  })  : variant = ThemedActionButtonVariant.green,
        color = null;

  const ThemedActionButton.blue({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.playTapSound = false,
    this.margin = const EdgeInsets.only(bottom: 8),
    this.padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    this.borderRadius = 10,
    this.boxShadow,
    this.width,
    this.height,
    this.textStyle,
  })  : variant = ThemedActionButtonVariant.blue,
        color = null;

  @override
  State<ThemedActionButton> createState() => _ThemedActionButtonState();
}

class _ThemedActionButtonState extends State<ThemedActionButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (!_hasVolume) return;
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  bool get _isGreen => widget.variant == ThemedActionButtonVariant.green;
  bool get _isBlue => widget.variant == ThemedActionButtonVariant.blue;
  bool get _hasVolume => _isGreen || _isBlue;

  Color _greenButtonColor(bool isDark) {
    return isDark ? const Color(0xFF92D333) : const Color(0xFF59CB0B);
  }

  Color _greenLineColor(bool isDark) {
    return isDark ? const Color(0xFF729462) : const Color(0xFF6F9A4A);
  }

  Color _blueButtonColor(bool isDark) {
    return isDark ? const Color(0xFF4ABFF8) : const Color(0xFF20AFF6);
  }

  Color _blueLineColor() {
    return const Color(0xFF2299D4);
  }

  bool _isBlueColor(Color color) {
    return color.value == 0xFF49C0F7 ||
        color.value == 0xFF29B6F6 ||
        color.value == AppTheme.darkAccent.value;
  }

  Color _textColorFor(Color baseColor, bool isDark) {
    if (_isGreen) {
      return isDark ? const Color(0xFF101E27) : Colors.white;
    }
    if (_isBlue) {
      return isDark ? const Color(0xFF102124) : Colors.white;
    }
    if (isDark && _isBlueColor(baseColor)) {
      return const Color(0xFF102124);
    }
    return Colors.white;
  }

  void _handleTap() {
    if (widget.playTapSound) {
      AudioManager().playTapSound();
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = _isGreen
        ? _greenButtonColor(isDark)
        : _isBlue
            ? _blueButtonColor(isDark)
            : (widget.color ?? colors.accent);
    final lineColor =
        _isGreen ? _greenLineColor(isDark) : _blueLineColor();
    final showLine = _hasVolume && !_isPressed;
    final pressOffset = _hasVolume && _isPressed ? 4.0 : 0.0;
    final textColor = _textColorFor(baseColor, isDark);

    final labelStyle = (widget.textStyle ??
            const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ))
        .copyWith(color: textColor);

    final label = Text(
      widget.label,
      style: labelStyle,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );

    Widget content;
    if (widget.icon == null) {
      content = Center(child: label);
    } else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Flexible(child: label),
        ],
      );
    }

    if (widget.width != null || widget.height != null) {
      content = SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(child: content),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      margin: widget.margin,
      transform: Matrix4.translationValues(0, pressOffset, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.boxShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: InkWell(
          onTap: _handleTap,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Ink(
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: showLine
                  ? Border(
                      bottom: BorderSide(
                        color: lineColor,
                        width: 4,
                      ),
                    )
                  : null,
            ),
            child: Padding(
              padding: widget.padding,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
