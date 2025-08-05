import 'package:flutter/material.dart';
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_data_table/src/data_table_filters.dart';

// =============================================================================
// MODELOS UNIFICADOS PARA TODOS OS TIPOS DE FILTROS
// =============================================================================

enum UnifiedFilterType {
  quick,
  advanced,
  column,
  search,
  dateRange,
  multiSelect,
}

enum FilterCategory {
  status,
  category,
  date,
  number,
  text,
  custom,
}

class UnifiedFilter<T> {
  final String id;
  final String field;
  final String label;
  final dynamic value;
  final dynamic secondValue; // Para between/range
  final FilterOperator operator;
  final UnifiedFilterType type;
  final FilterCategory category;
  final bool isActive;
  final Color? color;
  final IconData? icon;
  final String? description;
  final Map<String, dynamic>? metadata;

  const UnifiedFilter({
    required this.id,
    required this.field,
    required this.label,
    required this.value,
    this.secondValue,
    this.operator = FilterOperator.equals,
    this.type = UnifiedFilterType.quick,
    this.category = FilterCategory.text,
    this.isActive = true,
    this.color,
    this.icon,
    this.description,
    this.metadata,
  });

  // Criar de Quick Filter
  factory UnifiedFilter.fromQuickFilter(QuickFilter<T> quickFilter) {
    return UnifiedFilter<T>(
      id: quickFilter.id,
      field: quickFilter.field,
      label: quickFilter.label,
      value: quickFilter.value,
      operator: quickFilter.operator,
      type: UnifiedFilterType.quick,
      category: _getQuickFilterCategory(quickFilter.field),
      color: quickFilter.color,
      icon: quickFilter.icon,
    );
  }

  // Criar de Advanced Filter
  factory UnifiedFilter.fromAdvancedFilter(ActiveFilter advancedFilter, String label) {
    return UnifiedFilter<T>(
      id: '${advancedFilter.field}_${advancedFilter.value}',
      field: advancedFilter.field,
      label: label,
      value: advancedFilter.value,
      secondValue: advancedFilter.secondValue,
      operator: advancedFilter.operator,
      type: UnifiedFilterType.advanced,
      category: _getAdvancedFilterCategory(advancedFilter.operator),
      isActive: advancedFilter.isActive,
    );
  }

  // Criar filtro de busca
  factory UnifiedFilter.search(String searchTerm) {
    return UnifiedFilter<T>(
      id: 'search_global',
      field: 'search',
      label: 'Busca',
      value: searchTerm,
      operator: FilterOperator.contains,
      type: UnifiedFilterType.search,
      category: FilterCategory.text,
      icon: Icons.search,
      description: 'Busca global: "$searchTerm"',
    );
  }

  // Criar filtro de data range
  factory UnifiedFilter.dateRange({
    required String id,
    required String label,
    required DateTime startDate,
    required DateTime endDate,
    String? field = 'createdAt',
  }) {
    return UnifiedFilter<T>(
      id: id,
      field: field!,
      label: label,
      value: startDate,
      secondValue: endDate,
      operator: FilterOperator.between,
      type: UnifiedFilterType.dateRange,
      category: FilterCategory.date,
      icon: Icons.date_range,
      description: 'De ${_formatDate(startDate)} até ${_formatDate(endDate)}',
    );
  }

  // Métodos úteis
  String get displayText {
    switch (type) {
      case UnifiedFilterType.search:
        return 'Busca: "$value"';
      case UnifiedFilterType.dateRange:
        return '$label: ${_formatDateRange()}';
      case UnifiedFilterType.quick:
        return label;
      case UnifiedFilterType.advanced:
        return _getAdvancedDisplayText();
      default:
        return '$label: $value';
    }
  }

  String _getAdvancedDisplayText() {
    switch (operator) {
      case FilterOperator.between:
        return '$label entre $value e $secondValue';
      case FilterOperator.isEmpty:
        return '$label está vazio';
      case FilterOperator.isNotEmpty:
        return '$label não está vazio';
      default:
        return '$label ${_getOperatorText()} $value';
    }
  }

  String _getOperatorText() {
    switch (operator) {
      case FilterOperator.equals: return 'igual a';
      case FilterOperator.notEquals: return 'diferente de';
      case FilterOperator.contains: return 'contém';
      case FilterOperator.notContains: return 'não contém';
      case FilterOperator.startsWith: return 'começa com';
      case FilterOperator.endsWith: return 'termina com';
      case FilterOperator.greaterThan: return 'maior que';
      case FilterOperator.lessThan: return 'menor que';
      default: return '';
    }
  }

  String _formatDateRange() {
    if (secondValue != null) {
      return '${_formatDate(value)} - ${_formatDate(secondValue)}';
    }
    return _formatDate(value);
  }

  static String _formatDate(dynamic date) {
    if (date is DateTime) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    return date.toString();
  }

  static FilterCategory _getQuickFilterCategory(String field) {
    switch (field.toLowerCase()) {
      case 'status':
      case 'state':
        return FilterCategory.status;
      case 'category':
      case 'type':
        return FilterCategory.category;
      case 'createdat':
      case 'updatedat':
      case 'date':
        return FilterCategory.date;
      default:
        return FilterCategory.text;
    }
  }

  static FilterCategory _getAdvancedFilterCategory(FilterOperator operator) {
    switch (operator) {
      case FilterOperator.between:
        return FilterCategory.date;
      case FilterOperator.greaterThan:
      case FilterOperator.lessThan:
        return FilterCategory.number;
      default:
        return FilterCategory.text;
    }
  }

  UnifiedFilter<T> copyWith({
    String? id,
    String? field,
    String? label,
    dynamic value,
    dynamic secondValue,
    FilterOperator? operator,
    UnifiedFilterType? type,
    FilterCategory? category,
    bool? isActive,
    Color? color,
    IconData? icon,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return UnifiedFilter<T>(
      id: id ?? this.id,
      field: field ?? this.field,
      label: label ?? this.label,
      value: value ?? this.value,
      secondValue: secondValue ?? this.secondValue,
      operator: operator ?? this.operator,
      type: type ?? this.type,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnifiedFilter && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// =============================================================================
// CONFIGURAÇÕES UNIFICADAS
// =============================================================================

class UnifiedFiltersConfig<T> {
  final bool enableQuickFilters;
  final bool enableAdvancedFilters;
  final bool enableSearch;
  final bool enableColumnFilters;
  final bool showFilterPills;
  final bool enableFilterPresets;
  final bool enableMobileOptimization;

  // Quick filters
  final List<QuickFiltersConfig<T>> quickFiltersConfigs;

  // Advanced filters
  final List<AdvancedFilterConfig<T>> advancedFiltersConfigs;

  // Search
  final String searchPlaceholder;
  final List<String> searchFields;
  final String Function(T item, String field)? fieldGetter;

  // UI Customization
  final Color? primaryColor;
  final double maxPillsHeight;
  final int maxVisiblePills;
  final bool autoCollapsePills;

  const UnifiedFiltersConfig({
    this.enableQuickFilters = true,
    this.enableAdvancedFilters = true,
    this.enableSearch = true,
    this.enableColumnFilters = true,
    this.showFilterPills = true,
    this.enableFilterPresets = false,
    this.enableMobileOptimization = true,
    this.quickFiltersConfigs = const [],
    this.advancedFiltersConfigs = const [],
    this.searchPlaceholder = 'Buscar...',
    this.searchFields = const [],
    this.fieldGetter,
    this.primaryColor,
    this.maxPillsHeight = 120,
    this.maxVisiblePills = 8,
    this.autoCollapsePills = true,
  });

  factory UnifiedFiltersConfig.simple() {
    return UnifiedFiltersConfig<T>(
      enableQuickFilters: false,
      enableAdvancedFilters: false,
      enableFilterPresets: false,
    );
  }

  factory UnifiedFiltersConfig.full({
    List<QuickFiltersConfig<T>> quickFilters = const [],
    List<AdvancedFilterConfig<T>> advancedFilters = const [],
    List<String> searchFields = const [],
    String Function(T item, String field)? fieldGetter,
  }) {
    return UnifiedFiltersConfig<T>(
      quickFiltersConfigs: quickFilters,
      advancedFiltersConfigs: advancedFilters,
      searchFields: searchFields,
      fieldGetter: fieldGetter,
      enableFilterPresets: true,
    );
  }
}

// =============================================================================
// ESTADOS E RESULTADOS
// =============================================================================

class FilterState<T> {
  final List<UnifiedFilter<T>> activeFilters;
  final String? searchTerm;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> metadata;

  const FilterState({
    this.activeFilters = const [],
    this.searchTerm,
    this.isLoading = false,
    this.error,
    this.metadata = const {},
  });

  // Getters úteis
  List<UnifiedFilter<T>> get quickFilters =>
      activeFilters.where((f) => f.type == UnifiedFilterType.quick).toList();

  List<UnifiedFilter<T>> get advancedFilters =>
      activeFilters.where((f) => f.type == UnifiedFilterType.advanced).toList();

  UnifiedFilter<T>? get searchFilter {
    try {
      return activeFilters.firstWhere(
            (f) => f.type == UnifiedFilterType.search,
      );
    } catch (e) {
      return null;
    }
  }

  bool get hasActiveFilters => activeFilters.isNotEmpty || searchTerm?.isNotEmpty == true;

  int get totalFiltersCount => activeFilters.length + (searchTerm?.isNotEmpty == true ? 1 : 0);

  FilterState<T> copyWith({
    List<UnifiedFilter<T>>? activeFilters,
    String? searchTerm,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    return FilterState<T>(
      activeFilters: activeFilters ?? this.activeFilters,
      searchTerm: searchTerm ?? this.searchTerm,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
    );
  }
}

// =============================================================================
// PRESETS DE FILTROS
// =============================================================================

class FilterPreset<T> {
  final String id;
  final String name;
  final String? description;
  final List<UnifiedFilter<T>> filters;
  final String? searchTerm;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const FilterPreset({
    required this.id,
    required this.name,
    this.description,
    required this.filters,
    this.searchTerm,
    required this.createdAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'searchTerm': searchTerm,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
      // TODO: Serializar filtros
    };
  }
}