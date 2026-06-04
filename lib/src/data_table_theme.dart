import 'package:flutter/material.dart';

enum DataTableDensity { compact, normal, comfortable, custom }

// Sistema de cores padronizado
class DataTableColorScheme {
  final Color primary;
  final Color primaryLight;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceContainer;
  final Color outline;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color onPrimary;
  final Color shadow;
  final Color success;
  final Color warning;
  final Color error;

  const DataTableColorScheme({
    this.primary = const Color(0xFF1976D2),
    this.primaryLight = const Color(0xFFE3F2FD),
    this.surface = Colors.white,
    this.surfaceVariant = const Color(0xFFF5F5F5),
    this.surfaceContainer = const Color(0xFFFAFAFA),
    this.outline = const Color(0xFFE0E0E0),
    this.onSurface = const Color(0xFF212121),
    this.onSurfaceVariant = const Color(0xFF757575),
    this.onPrimary = Colors.white,
    this.shadow = Colors.black,
    this.success = const Color(0xFF4CAF50),
    this.warning = const Color(0xFFFF9800),
    this.error = const Color(0xFFF44336),
  });

  /// Resolve cores a partir do [ColorScheme] do tema Material do host.
  factory DataTableColorScheme.fromTheme(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DataTableColorScheme(
      primary: cs.primary,
      primaryLight: cs.primaryContainer,
      surface: cs.surface,
      surfaceVariant: cs.surfaceContainerHighest,
      surfaceContainer: cs.surfaceContainer,
      outline: cs.outlineVariant,
      onSurface: cs.onSurface,
      onSurfaceVariant: cs.onSurfaceVariant,
      onPrimary: cs.onPrimary,
      shadow: cs.shadow,
      success: const Color(0xFF4CAF50),
      warning: const Color(0xFFFF9800),
      error: cs.error,
    );
  }
}

// Configuracoes de densidade
class DensityConfig {
  final double rowHeight;
  final double headerHeight;
  final EdgeInsets cellPadding;
  final EdgeInsets headerPadding;
  final double fontSize;
  final double headerFontSize;

  const DensityConfig({
    required this.rowHeight,
    required this.headerHeight,
    required this.cellPadding,
    required this.headerPadding,
    required this.fontSize,
    required this.headerFontSize,
  });

  static const compact = DensityConfig(
    rowHeight: 40,
    headerHeight: 48,
    cellPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    headerPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    fontSize: 13,
    headerFontSize: 13,
  );

  static const normal = DensityConfig(
    rowHeight: 52,
    headerHeight: 56,
    cellPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    headerPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    fontSize: 14,
    headerFontSize: 14,
  );

  static const comfortable = DensityConfig(
    rowHeight: 64,
    headerHeight: 64,
    cellPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    headerPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    fontSize: 15,
    headerFontSize: 15,
  );

  copyWith({
    double? rowHeight,
    double? headerHeight,
    EdgeInsets? cellPadding,
    EdgeInsets? headerPadding,
    double? fontSize,
    double? headerFontSize,
  }) {
    return DensityConfig(
      rowHeight: rowHeight ?? this.rowHeight,
      headerHeight: headerHeight ?? this.headerHeight,
      cellPadding: cellPadding ?? this.cellPadding,
      headerPadding: headerPadding ?? this.headerPadding,
      fontSize: fontSize ?? this.fontSize,
      headerFontSize: headerFontSize ?? this.headerFontSize,
    );
  }
}

class InnovareDataTableThemeData {
  final Color? headerBackgroundColor;
  final TextStyle? headerTextStyle;
  final TextStyle? cellTextStyle;
  final Color? rowStripedColor;
  final double? columnWidth;
  final double? rowHeight;
  final DataTableDensity density;
  final DataTableColorScheme colorScheme;
  final DensityConfig? customDensity;

  const InnovareDataTableThemeData({
    this.headerBackgroundColor,
    this.headerTextStyle,
    this.cellTextStyle,
    this.rowStripedColor,
    this.columnWidth,
    this.rowHeight,
    this.density = DataTableDensity.normal,
    this.colorScheme = const DataTableColorScheme(),
    this.customDensity
  }) : assert(
    density != DataTableDensity.custom || customDensity != null,
    'Custom density must be provided when using DataTableDensity.custom',
  );

  DensityConfig get densityConfig {
    switch (density) {
      case DataTableDensity.compact:
        return DensityConfig.compact;
      case DataTableDensity.comfortable:
        return DensityConfig.comfortable;
      case DataTableDensity.normal:
        return DensityConfig.normal;
      default:
        return customDensity!;
    }
  }
}

class InnovareDataTableTheme extends InheritedWidget {
  final InnovareDataTableThemeData data;

  const InnovareDataTableTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static InnovareDataTableThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<InnovareDataTableTheme>();
    if (theme != null) {
      final data = theme.data;
      // Se o consumer usou o colorScheme padrao (hardcoded light),
      // resolve automaticamente a partir do host theme.
      if (identical(data.colorScheme, const DataTableColorScheme())) {
        return InnovareDataTableThemeData(
          headerBackgroundColor: data.headerBackgroundColor,
          headerTextStyle: data.headerTextStyle,
          cellTextStyle: data.cellTextStyle,
          rowStripedColor: data.rowStripedColor,
          columnWidth: data.columnWidth,
          rowHeight: data.rowHeight,
          density: data.density,
          colorScheme: DataTableColorScheme.fromTheme(context),
          customDensity: data.customDensity,
        );
      }
      return data;
    }
    // Sem InnovareDataTableTheme no widget tree: resolve tudo do host.
    return InnovareDataTableThemeData(
      colorScheme: DataTableColorScheme.fromTheme(context),
    );
  }

  @override
  bool updateShouldNotify(covariant InnovareDataTableTheme oldWidget) => data != oldWidget.data;
}
