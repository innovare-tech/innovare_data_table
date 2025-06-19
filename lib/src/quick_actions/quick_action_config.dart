import 'package:flutter/material.dart';

class QuickActionConfig {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isEnabled;
  final bool isVisible;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final double? iconSize;

  const QuickActionConfig({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isEnabled = true,
    this.isVisible = true,
    this.backgroundColor,
    this.textStyle,
    this.iconSize,
  });

  factory QuickActionConfig.add({
    String label = "Adicionar",
    IconData icon = Icons.add,
    required VoidCallback onPressed,
    bool isEnabled = true,
    bool isVisible = true,
    Color? backgroundColor,
    TextStyle? textStyle,
    double? iconSize,
  }) {
    return QuickActionConfig(
      label: label,
      icon: icon,
      onPressed: onPressed,
      isEnabled: isEnabled,
      isVisible: isVisible,
      backgroundColor: backgroundColor,
      textStyle: textStyle,
      iconSize: iconSize,
    );
  }

  factory QuickActionConfig.export({
    String label = "Exportar",
    IconData icon = Icons.file_download,
    required VoidCallback onPressed,
    bool isEnabled = true,
    bool isVisible = true,
    Color? backgroundColor,
    TextStyle? textStyle,
    double? iconSize,
  }) {
    return QuickActionConfig(
      label: label,
      icon: icon,
      onPressed: onPressed,
      isEnabled: isEnabled,
      isVisible: isVisible,
      backgroundColor: backgroundColor,
      textStyle: textStyle,
      iconSize: iconSize,
    );
  }
}