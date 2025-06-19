import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_data_table/src/accessibility/accessibility_config.dart';
import 'package:innovare_data_table/src/accessibility/keyboard_navigation.dart';

class HighContrastDataTableTheme {
  static DataTableColorScheme createHighContrastTheme({
    required bool isDarkMode,
  }) {
    if (isDarkMode) {
      return const DataTableColorScheme(
        primary: Color(0xFFFFFFFF),
        primaryLight: Color(0xFF333333),
        surface: Color(0xFF000000),
        surfaceVariant: Color(0xFF1A1A1A),
        outline: Color(0xFFFFFFFF),
        onSurface: Color(0xFFFFFFFF),
        onSurfaceVariant: Color(0xFFCCCCCC),
        success: Color(0xFF00FF00),
        warning: Color(0xFFFFFF00),
        error: Color(0xFFFF0000),
      );
    } else {
      return const DataTableColorScheme(
        primary: Color(0xFF000000),
        primaryLight: Color(0xFFEEEEEE),
        surface: Color(0xFFFFFFFF),
        surfaceVariant: Color(0xFFF5F5F5),
        outline: Color(0xFF000000),
        onSurface: Color(0xFF000000),
        onSurfaceVariant: Color(0xFF333333),
        success: Color(0xFF006600),
        warning: Color(0xFF996600),
        error: Color(0xFF990000),
      );
    }
  }

  static TextTheme createHighContrastTextTheme({
    required bool isDarkMode,
  }) {
    final baseColor = isDarkMode ? Colors.white : Colors.black;

    return TextTheme(
      displayLarge: TextStyle(
        color: baseColor,
        fontWeight: FontWeight.w700,
        fontSize: 24,
      ),
      displayMedium: TextStyle(
        color: baseColor,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      bodyLarge: TextStyle(
        color: baseColor,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: baseColor,
        fontWeight: FontWeight.w400,
        fontSize: 14,
      ),
      labelLarge: TextStyle(
        color: baseColor,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }
}

class AccessibilityProvider extends InheritedWidget {
  final DataTableAccessibilityConfig config;
  final AccessibilityAnnouncer announcer;
  final KeyboardNavigationController? keyboardController;

  const AccessibilityProvider({
    super.key,
    required this.config,
    required this.announcer,
    this.keyboardController,
    required super.child,
  });

  static AccessibilityProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AccessibilityProvider>();
  }

  @override
  bool updateShouldNotify(AccessibilityProvider oldWidget) {
    return config != oldWidget.config;
  }
}