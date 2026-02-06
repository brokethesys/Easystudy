import 'package:flutter/material.dart';

import 'themed_action_button.dart';

class ThemedBlueButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool playTapSound;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;
  final TextStyle? textStyle;

  const ThemedBlueButton({
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
  });

  @override
  Widget build(BuildContext context) {
    return ThemedActionButton.blue(
      label: label,
      icon: icon,
      onTap: onTap,
      playTapSound: playTapSound,
      margin: margin,
      padding: padding,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
      width: width,
      height: height,
      textStyle: textStyle,
    );
  }
}
