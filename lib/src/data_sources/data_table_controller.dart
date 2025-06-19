import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:innovare_data_table/src/data_table_filters.dart';

import 'data_table_models.dart';
import 'data_table_source.dart';

// CONTROLLER PARA GERENCIAR ESTADO DO DATASOURCE
class DataTableController<T> extends ChangeNotifier {
  final DataTableSource<T> _dataSource;

  // Estado atual
  DataTableResult<T>? _currentResult;
  DataTableRequest _currentRequest = const DataTableRequest();
  bool _isLoading = false;
  String? _error;

  // Cache para performance
  final Map<String, DataTableResult<T>> _cache = {};
  Timer? _debounceTimer;
  StreamSubscription<DataTableUpdate<T>>? _updatesSubscription;

  DataTableController({required DataTableSource<T> dataSource})
      : _dataSource = dataSource {
    _setupRealtimeUpdates();
  }

  // Getters
  DataTableResult<T>? get currentResult => _currentResult;
  DataTableRequest get currentRequest => _currentRequest;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<T> get currentData => _currentResult?.data ?? [];
  int get totalCount => _currentResult?.totalCount ?? 0;

  // FETCH INICIAL
  Future<void> fetchData([DataTableRequest? request]) async {
    final targetRequest = request ?? _currentRequest;

    _setLoading(true);
    _setError(null);

    try {
      // Verificar cache primeiro
      final cacheKey = _generateCacheKey(targetRequest);
      if (_cache.containsKey(cacheKey)) {
        _currentResult = _cache[cacheKey];
        _currentRequest = targetRequest;
        _setLoading(false);
        return;
      }

      // Buscar do servidor
      final result = await _dataSource.fetch(targetRequest);

      // Atualizar estado
      _currentResult = result;
      _currentRequest = targetRequest;
      _cache[cacheKey] = result;

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // PAGINAÇÃO
  Future<void> goToPage(int page) async {
    if (page < 0 || _isLoading) return;

    final newRequest = _currentRequest.copyWith(page: page);
    await fetchData(newRequest);
  }

  Future<void> nextPage() async {
    if (_currentResult?.hasNextPage == true) {
      await goToPage(_currentRequest.page + 1);
    }
  }

  Future<void> previousPage() async {
    if (_currentResult?.hasPreviousPage == true) {
      await goToPage(_currentRequest.page - 1);
    }
  }

  // BUSCA
  void search(String term) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final newRequest = _currentRequest.copyWith(
        searchTerm: term.isEmpty ? null : term,
        page: 0, // Reset para primeira página
      );
      fetchData(newRequest);
    });
  }

  // ORDENAÇÃO
  Future<void> sort(String field, bool ascending) async {
    final existingSorts = List<DataTableSort>.from(_currentRequest.sorts);

    // Remover sort existente para este campo
    existingSorts.removeWhere((s) => s.field == field);

    // Adicionar novo sort no início
    existingSorts.insert(0, DataTableSort(field: field, ascending: ascending));

    final newRequest = _currentRequest.copyWith(
      sorts: existingSorts,
      page: 0, // Reset para primeira página
    );

    await fetchData(newRequest);
  }

  // FILTROS
  Future<void> addFilter(String field, dynamic value, [FilterOperator? operator]) async {
    final existingFilters = List<DataTableFilter>.from(_currentRequest.filters);

    // Remover filtro existente para este campo
    existingFilters.removeWhere((f) => f.field == field);

    // Adicionar novo filtro se valor não for vazio
    if (value != null && value.toString().isNotEmpty) {
      existingFilters.add(DataTableFilter(
        field: field,
        value: value,
        operator: operator ?? FilterOperator.contains,
      ));
    }

    final newRequest = _currentRequest.copyWith(
      filters: existingFilters,
      page: 0, // Reset para primeira página
    );

    await fetchData(newRequest);
  }

  Future<void> removeFilter(String field) async {
    final newFilters = _currentRequest.filters
        .where((f) => f.field != field)
        .toList();

    final newRequest = _currentRequest.copyWith(
      filters: newFilters,
      page: 0,
    );

    await fetchData(newRequest);
  }

  Future<void> clearFilters() async {
    final newRequest = _currentRequest.copyWith(
      filters: [],
      searchTerm: null,
      page: 0,
    );

    await fetchData(newRequest);
  }

  // REFRESH
  Future<void> refresh() async {
    _clearCache();
    await fetchData();
  }

  // UTILS PRIVADOS
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  String _generateCacheKey(DataTableRequest request) {
    return '${request.page}_${request.pageSize}_${request.searchTerm}_'
        '${request.sorts.map((s) => '${s.field}:${s.ascending}').join(',')}_'
        '${request.filters.map((f) => '${f.field}:${f.value}').join(',')}';
  }

  void _clearCache() {
    _cache.clear();
  }

  void _setupRealtimeUpdates() {
    final updatesStream = _dataSource.updates;
    if (updatesStream != null) {
      _updatesSubscription = updatesStream.listen((update) {
        _handleRealtimeUpdate(update);
      });
    }
  }

  void _handleRealtimeUpdate(DataTableUpdate<T> update) {
    if (_currentResult == null) return;

    switch (update.type) {
      case DataTableUpdateType.refresh:
        refresh();
        break;
      case DataTableUpdateType.insert:
      // TODO: Implementar inserção otimizada
        refresh();
        break;
      case DataTableUpdateType.update:
      // TODO: Implementar update otimizado
        refresh();
        break;
      case DataTableUpdateType.delete:
      // TODO: Implementar remoção otimizada
        refresh();
        break;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _updatesSubscription?.cancel();
    _dataSource.dispose();
    super.dispose();
  }
}