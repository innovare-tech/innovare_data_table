import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:innovare_data_table/src/data_sources/data_table_controller.dart';
import 'package:innovare_data_table/src/data_sources/data_table_models.dart';
import 'package:innovare_data_table/src/data_table_filters.dart';
import 'package:innovare_data_table/src/extensions/iterable_extensions.dart';
import 'package:innovare_data_table/src/filters/filter_models.dart';
import 'package:innovare_data_table/src/filters/quick_filters.dart';

// =============================================================================
// CONTROLLER UNIFICADO COM BUSCA CORRIGIDA E DEBOUNCE
// =============================================================================

class UnifiedFiltersController<T> extends ChangeNotifier {
  final UnifiedFiltersConfig<T> config;
  final DataTableController<T>? dataTableController;
  final String Function(T item, String field)? fieldGetter;

  // Estado interno
  FilterState<T> _state = const FilterState();
  List<FilterPreset<T>> _presets = [];

  // ✅ CONTROLE DE DEBOUNCE PARA BUSCA
  Timer? _searchDebounceTimer;
  final Duration searchDebounceDelay;

  UnifiedFiltersController({
    required this.config,
    this.dataTableController,
    this.fieldGetter,
    this.searchDebounceDelay = const Duration(milliseconds: 500), // ✅ DEBOUNCE PADRÃO DE 500ms
  });

  // =============================================================================
  // GETTERS
  // =============================================================================

  FilterState<T> get state => _state;
  List<UnifiedFilter<T>> get activeFilters => _state.activeFilters;
  String? get searchTerm => _state.searchTerm;
  bool get isLoading => _state.isLoading;
  bool get hasActiveFilters => _state.hasActiveFilters;
  List<FilterPreset<T>> get presets => List.unmodifiable(_presets);

  // Filtros por tipo
  List<UnifiedFilter<T>> get quickFilters => _state.quickFilters;
  List<UnifiedFilter<T>> get advancedFilters => _state.advancedFilters;

  // =============================================================================
  // SEARCH COM DEBOUNCE E PÁGINA CORRIGIDA
  // =============================================================================

  void search(String term) {
    if (!config.enableSearch) return;

    print('🔍 SEARCH INITIATED: "$term"');

    // ✅ CANCELAR TIMER ANTERIOR SE EXISTIR
    _searchDebounceTimer?.cancel();

    // ✅ ATUALIZAR ESTADO LOCAL IMEDIATAMENTE (PARA UI RESPONSIVA)
    final trimmedTerm = term.trim();
    _updateSearchTermInState(trimmedTerm.isEmpty ? null : trimmedTerm);

    // ✅ CONFIGURAR NOVO TIMER DE DEBOUNCE
    _searchDebounceTimer = Timer(searchDebounceDelay, () {
      print('🔍 SEARCH DEBOUNCE EXECUTED: "$trimmedTerm"');
      _executeSearch(trimmedTerm);
    });
  }

  void _updateSearchTermInState(String? searchTerm) {
    final newState = FilterState<T>(
      activeFilters: List<UnifiedFilter<T>>.from(_state.activeFilters),
      searchTerm: searchTerm,
      isLoading: _state.isLoading,
      error: _state.error,
      metadata: _state.metadata,
    );

    _updateState(newState);
  }

  void _executeSearch(String trimmedTerm) {
    print('🔍 EXECUTING SEARCH: "$trimmedTerm"');

    // Atualizar DataTableController se conectado
    if (dataTableController != null) {
      print('🔍 UPDATING DATA CONTROLLER...');

      final currentRequest = dataTableController!.currentRequest;
      final newRequest = currentRequest.copyWith(
        searchTerm: trimmedTerm.isEmpty ? null : trimmedTerm,
        page: 1, // ✅ CORREÇÃO: SEMPRE COMEÇAR NA PÁGINA 1 QUANDO BUSCA MUDA
      );

      print('🔍 NEW REQUEST: page=${newRequest.page}, searchTerm="${newRequest.searchTerm}"');
      dataTableController!.fetchData(newRequest);
    }
  }

  void clearSearch() {
    print('🔍 CLEARING SEARCH');

    // ✅ CANCELAR TIMER DE DEBOUNCE
    _searchDebounceTimer?.cancel();

    // ✅ LIMPAR BUSCA IMEDIATAMENTE
    _updateSearchTermInState(null);

    // ✅ EXECUTAR LIMPEZA NO DATA CONTROLLER
    if (dataTableController != null) {
      final currentRequest = dataTableController!.currentRequest;
      final newRequest = currentRequest.copyWith(
        searchTerm: null,
        page: 1, // ✅ VOLTAR PARA PÁGINA 1 QUANDO LIMPAR
      );

      print('🔍 CLEARING DATA CONTROLLER: page=${newRequest.page}');
      dataTableController!.fetchData(newRequest);
    }
  }

  // =============================================================================
  // QUICK FILTERS (SEM ALTERAÇÕES)
  // =============================================================================

  void toggleQuickFilter(String filterId) {
    print('🔥 TOGGLE QUICK FILTER: $filterId');
    print('🔥 CURRENT ACTIVE: ${_state.activeFilters.map((f) => f.id).toList()}');

    final quickFilter = _findQuickFilterById(filterId);
    if (quickFilter == null) {
      print('🔥 ERROR: Quick filter not found: $filterId');
      return;
    }

    final currentFilters = List<UnifiedFilter<T>>.from(_state.activeFilters);
    final existingIndex = currentFilters.indexWhere((f) => f.id == filterId);

    if (existingIndex != -1) {
      print('🔥 REMOVING filter: $filterId');
      currentFilters.removeAt(existingIndex);
    } else {
      print('🔥 ADDING filter: $filterId');
      final config = _getQuickFilterConfig(quickFilter);

      if (config != null && !config.allowMultiple) {
        print('🔥 REMOVING other filters from group: ${config.groupLabel}');
        currentFilters.removeWhere((f) =>
        f.type == UnifiedFilterType.quick &&
            _isFromSameGroup(f.id, quickFilter.id, config)
        );
      }

      currentFilters.add(UnifiedFilter<T>.fromQuickFilter(quickFilter));
    }

    print('🔥 NEW FILTERS COUNT: ${currentFilters.length}');
    _applyFilters(currentFilters);
  }

  void setQuickFilters(Set<String> filterIds) {
    final currentFilters = List<UnifiedFilter<T>>.from(_state.activeFilters);

    currentFilters.removeWhere((f) => f.type == UnifiedFilterType.quick);

    for (final filterId in filterIds) {
      final quickFilter = _findQuickFilterById(filterId);
      if (quickFilter != null) {
        currentFilters.add(UnifiedFilter<T>.fromQuickFilter(quickFilter));
      }
    }

    _applyFilters(currentFilters);
  }

  QuickFilter<T>? _findQuickFilterById(String id) {
    for (final config in this.config.quickFiltersConfigs) {
      try {
        return config.filters.firstWhere((f) => f.id == id);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  QuickFiltersConfig<T>? _getQuickFilterConfig(QuickFilter<T> filter) {
    for (final config in this.config.quickFiltersConfigs) {
      if (config.filters.any((f) => f.id == filter.id)) {
        return config;
      }
    }
    return null;
  }

  bool _isFromSameGroup(String filterId1, String filterId2, QuickFiltersConfig<T> config) {
    return config.filters.any((f) => f.id == filterId1) &&
        config.filters.any((f) => f.id == filterId2);
  }

  // =============================================================================
  // ADVANCED FILTERS (SEM ALTERAÇÕES)
  // =============================================================================

  void addAdvancedFilter(AdvancedFilterConfig<T> filterConfig, FilterOperator operator, dynamic value, [dynamic secondValue]) {
    final filter = UnifiedFilter<T>(
      id: '${filterConfig.field}_${DateTime.now().millisecondsSinceEpoch}',
      field: filterConfig.field,
      label: filterConfig.label,
      value: value,
      secondValue: secondValue,
      operator: operator,
      type: UnifiedFilterType.advanced,
      category: _getCategoryFromFilterType(filterConfig.type),
    );

    final currentFilters = List<UnifiedFilter<T>>.from(_state.activeFilters);
    currentFilters.add(filter);
    _applyFilters(currentFilters);
  }

  void updateAdvancedFilter(String filterId, {
    FilterOperator? operator,
    dynamic value,
    dynamic secondValue,
    bool? isActive,
  }) {
    final currentFilters = List<UnifiedFilter<T>>.from(_state.activeFilters);
    final index = currentFilters.indexWhere((f) => f.id == filterId);

    if (index != -1) {
      currentFilters[index] = currentFilters[index].copyWith(
        operator: operator,
        value: value,
        secondValue: secondValue,
        isActive: isActive,
      );
      _applyFilters(currentFilters);
    }
  }

  void removeAdvancedFilter(String filterId) {
    final currentFilters = List<UnifiedFilter<T>>.from(_state.activeFilters);
    currentFilters.removeWhere((f) => f.id == filterId);
    _applyFilters(currentFilters);
  }

  void setAdvancedFilters(List<ActiveFilter> filters) {
    final currentFilters = List<UnifiedFilter<T>>.from(_state.activeFilters);

    currentFilters.removeWhere((f) => f.type == UnifiedFilterType.advanced);

    for (final filter in filters) {
      final config = this.config.advancedFiltersConfigs.firstWhere(
            (c) => c.field == filter.field,
        orElse: () => AdvancedFilterConfig<T>(
          field: filter.field,
          label: filter.field,
          type: SimpleFilterType.text,
        ),
      );

      currentFilters.add(UnifiedFilter<T>.fromAdvancedFilter(filter, config.label));
    }

    print('🔥 ADVANCED FILTERS: Aplicando ${filters.length} filtros');
    print('🔥 CURRENT FILTERS: ${currentFilters.length} total');
    _applyFilters(currentFilters);
  }

  FilterCategory _getCategoryFromFilterType(SimpleFilterType type) {
    switch (type) {
      case SimpleFilterType.text:
        return FilterCategory.text;
      case SimpleFilterType.number:
        return FilterCategory.number;
      case SimpleFilterType.date:
        return FilterCategory.date;
      case SimpleFilterType.select:
        return FilterCategory.category;
    }
  }

  // =============================================================================
  // COLUMN FILTERS (SEM ALTERAÇÕES)
  // =============================================================================

  void addColumnFilter(String field, dynamic value) {
    final filter = UnifiedFilter<T>(
      id: 'column_$field',
      field: field,
      label: field,
      value: value,
      operator: FilterOperator.contains,
      type: UnifiedFilterType.column,
      category: FilterCategory.text,
    );

    final currentFilters = List<UnifiedFilter<T>>.from(_state.activeFilters);

    currentFilters.removeWhere((f) => f.field == field && f.type == UnifiedFilterType.column);

    if (value != null && value.toString().trim().isNotEmpty) {
      currentFilters.add(filter);
    }

    _applyFilters(currentFilters);
  }

  void removeColumnFilter(String field) {
    final currentFilters = List<UnifiedFilter<T>>.from(_state.activeFilters);
    currentFilters.removeWhere((f) => f.field == field && f.type == UnifiedFilterType.column);
    _applyFilters(currentFilters);
  }

  // =============================================================================
  // FILTER MANAGEMENT (COM CORREÇÃO DE PÁGINA)
  // =============================================================================

  void removeFilter(String filterId) {
    final currentFilters = List<UnifiedFilter<T>>.from(_state.activeFilters);
    currentFilters.removeWhere((f) => f.id == filterId);
    _applyFilters(currentFilters);
  }

  void clearAllFilters() {
    // ✅ CANCELAR TIMER DE BUSCA
    _searchDebounceTimer?.cancel();

    final newState = FilterState<T>(
      activeFilters: <UnifiedFilter<T>>[],
      searchTerm: null,
      isLoading: _state.isLoading,
      error: _state.error,
      metadata: _state.metadata,
    );

    _updateState(newState);

    if (dataTableController != null) {
      // ✅ CORREÇÃO: VOLTAR PARA PÁGINA 1 QUANDO LIMPAR TODOS OS FILTROS
      final currentRequest = dataTableController!.currentRequest;
      final newRequest = currentRequest.copyWith(
        filters: <DataTableFilter>[],
        searchTerm: null,
        page: 1,
      );

      print('🔥 CLEARING ALL FILTERS: page=${newRequest.page}');
      dataTableController!.fetchData(newRequest);
    }
  }

  void clearFiltersByType(UnifiedFilterType type) {
    final currentFilters = _state.activeFilters.where((f) => f.type != type).toList();
    _applyFilters(currentFilters);
  }

  // =============================================================================
  // PRESETS (SEM ALTERAÇÕES)
  // =============================================================================

  void savePreset(String name, {String? description}) {
    if (!config.enableFilterPresets) return;

    final preset = FilterPreset<T>(
      id: 'preset_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      filters: List.from(_state.activeFilters),
      searchTerm: _state.searchTerm,
      createdAt: DateTime.now(),
    );

    _presets.add(preset);
    notifyListeners();
  }

  void loadPreset(String presetId) {
    final preset = _presets.firstWhereOrNull((p) => p.id == presetId);
    if (preset == null) return;

    _updateState(_state.copyWith(
      activeFilters: List.from(preset.filters),
      searchTerm: preset.searchTerm,
    ));

    _syncWithDataTableController();
  }

  void deletePreset(String presetId) {
    _presets.removeWhere((p) => p.id == presetId);
    notifyListeners();
  }

  // =============================================================================
  // MÉTODOS PRIVADOS (COM CORREÇÃO DE PÁGINA)
  // =============================================================================

  void _applyFilters(List<UnifiedFilter<T>> filters) {
    print('🔥 APPLY FILTERS: ${filters.length} filtros');

    final newState = FilterState<T>(
      activeFilters: List<UnifiedFilter<T>>.from(filters),
      searchTerm: _state.searchTerm,
      isLoading: _state.isLoading,
      error: _state.error,
      metadata: _state.metadata,
    );

    _updateState(newState);
    _syncWithDataTableController();
  }

  void _updateState(FilterState<T> newState) {
    print('🔥 UPDATING STATE:');
    print('🔥 OLD FILTERS: ${_state.activeFilters.length}');
    print('🔥 NEW FILTERS: ${newState.activeFilters.length}');
    print('🔥 NEW FILTER IDS: ${newState.activeFilters.map((f) => f.id).toList()}');

    _state = newState;
    notifyListeners();

    print('🔥 STATE UPDATED - NOTIFIED LISTENERS');
  }

  void _syncWithDataTableController() {
    if (dataTableController == null) {
      print('🔥 NO DATA CONTROLLER - usando dados locais');
      return;
    }

    print('🔥 SYNCING WITH DATA CONTROLLER...');
    final dataTableFilters = <DataTableFilter>[];

    for (final filter in _state.activeFilters) {
      if (filter.isActive) {
        print('🔥 ADDING DATA FILTER: ${filter.field} = ${filter.value}');
        dataTableFilters.add(DataTableFilter(
          field: filter.field,
          value: filter.value,
          operator: filter.operator,
          type: _mapToDataTableFilterType(filter.type),
        ));
      }
    }

    print('🔥 TOTAL DATA FILTERS: ${dataTableFilters.length}');
    print('🔥 SEARCH TERM: ${_state.searchTerm}');

    final currentRequest = dataTableController!.currentRequest;
    final newRequest = currentRequest.copyWith(
      filters: dataTableFilters,
      searchTerm: _state.searchTerm,
      page: 1, // ✅ CORREÇÃO: SEMPRE VOLTAR PARA PÁGINA 1 QUANDO FILTROS MUDAM
    );

    print('🔥 FETCHING DATA WITH NEW REQUEST: page=${newRequest.page}');
    dataTableController!.fetchData(newRequest);
  }

  FilterType _mapToDataTableFilterType(UnifiedFilterType type) {
    switch (type) {
      case UnifiedFilterType.quick:
        return FilterType.quick;
      case UnifiedFilterType.advanced:
      case UnifiedFilterType.column:
      case UnifiedFilterType.dateRange:
      case UnifiedFilterType.multiSelect:
        return FilterType.advanced;
      default:
        return FilterType.quick;
    }
  }

  // =============================================================================
  // MÉTODOS PÚBLICOS PARA INTEGRAÇÃO (SEM ALTERAÇÕES)
  // =============================================================================

  Set<String> getActiveQuickFilterIds() {
    return _state.activeFilters
        .where((f) => f.type == UnifiedFilterType.quick)
        .map((f) => f.id)
        .toSet();
  }

  List<ActiveFilter> getActiveAdvancedFilters() {
    return _state.activeFilters
        .where((f) => f.type == UnifiedFilterType.advanced)
        .map((f) => ActiveFilter(
      field: f.field,
      operator: f.operator,
      value: f.value,
      secondValue: f.secondValue,
      isActive: f.isActive,
    ))
        .toList();
  }

  Map<String, dynamic> getActiveColumnFilters() {
    final filters = <String, dynamic>{};

    for (final filter in _state.activeFilters) {
      if (filter.type == UnifiedFilterType.column) {
        filters[filter.field] = filter.value;
      }
    }

    return filters;
  }

  // =============================================================================
  // INTEGRAÇÃO COM DADOS LOCAIS (SEM ALTERAÇÕES)
  // =============================================================================

  List<T> applyFiltersToLocalData(List<T> data) {
    var filteredData = data;

    // Aplicar busca
    if (_state.searchTerm?.isNotEmpty == true) {
      filteredData = _applySearchToLocalData(filteredData, _state.searchTerm!);
    }

    // Aplicar cada filtro
    for (final filter in _state.activeFilters.where((f) => f.isActive)) {
      filteredData = _applyFilterToLocalData(filteredData, filter);
    }

    return filteredData;
  }

  List<T> _applySearchToLocalData(List<T> data, String searchTerm) {
    final lowerTerm = searchTerm.toLowerCase();

    return data.where((item) {
      if (fieldGetter != null) {
        for (final field in config.searchFields) {
          final value = fieldGetter!(item, field);
          if (value.toLowerCase().contains(lowerTerm)) {
            return true;
          }
        }
      } else {
        return item.toString().toLowerCase().contains(lowerTerm);
      }
      return false;
    }).toList();
  }

  List<T> _applyFilterToLocalData(List<T> data, UnifiedFilter<T> filter) {
    return data.where((item) {
      if (fieldGetter != null) {
        final itemValue = fieldGetter!(item, filter.field);
        return _evaluateFilter(itemValue, filter);
      }
      return true;
    }).toList();
  }

  bool _evaluateFilter(dynamic itemValue, UnifiedFilter<T> filter) {
    if (itemValue == null) {
      switch (filter.operator) {
        case FilterOperator.isEmpty:
          return true;
        case FilterOperator.isNotEmpty:
          return false;
        default:
          return false;
      }
    }

    final valueStr = itemValue.toString();
    final filterValueStr = filter.value?.toString() ?? '';

    switch (filter.operator) {
      case FilterOperator.equals:
        return valueStr.toLowerCase() == filterValueStr.toLowerCase();

      case FilterOperator.notEquals:
        return valueStr.toLowerCase() != filterValueStr.toLowerCase();

      case FilterOperator.contains:
        return valueStr.toLowerCase().contains(filterValueStr.toLowerCase());

      case FilterOperator.notContains:
        return !valueStr.toLowerCase().contains(filterValueStr.toLowerCase());

      case FilterOperator.startsWith:
        return valueStr.toLowerCase().startsWith(filterValueStr.toLowerCase());

      case FilterOperator.endsWith:
        return valueStr.toLowerCase().endsWith(filterValueStr.toLowerCase());

      case FilterOperator.greaterThan:
        return _compareNumeric(itemValue, filter.value, (a, b) => a > b);

      case FilterOperator.lessThan:
        return _compareNumeric(itemValue, filter.value, (a, b) => a < b);

      case FilterOperator.between:
        if (filter.secondValue != null) {
          return _isInRange(itemValue, filter.value, filter.secondValue);
        }
        return false;

      case FilterOperator.isEmpty:
        return valueStr.trim().isEmpty;

      case FilterOperator.isNotEmpty:
        return valueStr.trim().isNotEmpty;
    }
  }

  bool _compareNumeric(dynamic value1, dynamic value2, bool Function(double, double) comparison) {
    final num1 = _parseNumber(value1);
    final num2 = _parseNumber(value2);

    if (num1 == null || num2 == null) {
      return comparison(
        value1.toString().length.toDouble(),
        value2.toString().length.toDouble(),
      );
    }

    return comparison(num1, num2);
  }

  bool _isInRange(dynamic value, dynamic min, dynamic max) {
    if (value is DateTime && min is DateTime && max is DateTime) {
      return value.isAfter(min.subtract(const Duration(days: 1))) &&
          value.isBefore(max.add(const Duration(days: 1)));
    }

    final numValue = _parseNumber(value);
    final numMin = _parseNumber(min);
    final numMax = _parseNumber(max);

    if (numValue != null && numMin != null && numMax != null) {
      return numValue >= numMin && numValue <= numMax;
    }

    final valueStr = value.toString();
    final minStr = min.toString();
    final maxStr = max.toString();
    return valueStr.compareTo(minStr) >= 0 && valueStr.compareTo(maxStr) <= 0;
  }

  double? _parseNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    String str = value.toString().trim();
    str = str.replaceAll(RegExp(r'[^\d.,-]'), '');
    str = str.replaceAll(',', '.');

    return double.tryParse(str);
  }

  // =============================================================================
  // DISPOSE
  // =============================================================================

  @override
  void dispose() {
    // ✅ CANCELAR TIMER DE DEBOUNCE AO FAZER DISPOSE
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}