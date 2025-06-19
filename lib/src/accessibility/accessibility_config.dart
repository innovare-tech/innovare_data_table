import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

class DataTableAccessibilityConfig {
  final bool enableScreenReader;
  final bool enableKeyboardNavigation;
  final bool enableHighContrast;
  final bool enableFocusIndicators;
  final bool enableSemanticLabels;
  final bool enableAnnouncements;
  final double minimumTouchTargetSize;
  final Duration focusAnimationDuration;
  final Map<String, String> customLabels;
  final Map<String, String> customHints;

  const DataTableAccessibilityConfig({
    this.enableScreenReader = true,
    this.enableKeyboardNavigation = true,
    this.enableHighContrast = false,
    this.enableFocusIndicators = true,
    this.enableSemanticLabels = true,
    this.enableAnnouncements = true,
    this.minimumTouchTargetSize = 44.0,
    this.focusAnimationDuration = const Duration(milliseconds: 200),
    this.customLabels = const {},
    this.customHints = const {},
  });

  DataTableAccessibilityConfig copyWith({
    bool? enableScreenReader,
    bool? enableKeyboardNavigation,
    bool? enableHighContrast,
    bool? enableFocusIndicators,
    bool? enableSemanticLabels,
    bool? enableAnnouncements,
    double? minimumTouchTargetSize,
    Duration? focusAnimationDuration,
    Map<String, String>? customLabels,
    Map<String, String>? customHints,
  }) {
    return DataTableAccessibilityConfig(
      enableScreenReader: enableScreenReader ?? this.enableScreenReader,
      enableKeyboardNavigation: enableKeyboardNavigation ?? this.enableKeyboardNavigation,
      enableHighContrast: enableHighContrast ?? this.enableHighContrast,
      enableFocusIndicators: enableFocusIndicators ?? this.enableFocusIndicators,
      enableSemanticLabels: enableSemanticLabels ?? this.enableSemanticLabels,
      enableAnnouncements: enableAnnouncements ?? this.enableAnnouncements,
      minimumTouchTargetSize: minimumTouchTargetSize ?? this.minimumTouchTargetSize,
      focusAnimationDuration: focusAnimationDuration ?? this.focusAnimationDuration,
      customLabels: customLabels ?? this.customLabels,
      customHints: customHints ?? this.customHints,
    );
  }
}

enum AccessibilityAction {
  sortColumn,
  filterColumn,
  selectRow,
  selectAll,
  nextPage,
  previousPage,
  openMenu,
  closeMenu,
  expandRow,
  collapseRow,
}

class AccessibilityAnnouncer {
  static final _instance = AccessibilityAnnouncer._internal();
  factory AccessibilityAnnouncer() => _instance;
  AccessibilityAnnouncer._internal();

  static const Map<String, String> _defaultMessages = {
    'loading': 'Carregando dados da tabela',
    'loaded': 'Dados carregados. {count} itens encontrados',
    'filtered': 'Filtros aplicados. {count} itens correspondem aos critérios',
    'sorted': 'Tabela ordenada por {column} em ordem {direction}',
    'selected': '{count} itens selecionados',
    'pageChanged': 'Página {page} de {total}',
    'noResults': 'Nenhum resultado encontrado',
    'error': 'Erro ao carregar dados: {error}',
  };

  void announce(String messageKey, {Map<String, dynamic>? parameters}) {
    String message = _defaultMessages[messageKey] ?? messageKey;

    if (parameters != null) {
      parameters.forEach((key, value) {
        message = message.replaceAll('{$key}', value.toString());
      });
    }

    SemanticsService.announce(message, TextDirection.ltr);
  }

  void announceCustom(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }
}