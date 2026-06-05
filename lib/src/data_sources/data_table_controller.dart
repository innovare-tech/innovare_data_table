import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_data_table/src/data_table_filters.dart';

import 'data_table_models.dart';
import 'data_table_source.dart';

// CONTROLLER PARA GERENCIAR ESTADO DO DATASOURCE
class DataTableController<T> extends ChangeNotifier {
  final DataTableSource<T> _dataSource;

  /// Optional function that returns the **stable identity** of a row — used
  /// by the realtime update path to apply `insert`/`update`/`delete` events
  /// in place on `_currentResult.data` instead of issuing a full HTTP
  /// refetch.
  ///
  /// When `null`, every realtime event falls back to [refresh] (current
  /// behaviour, retained for backward compatibility). When provided, the
  /// controller compares either `realtimeKeyExtractor(update.item)` against
  /// the rows in the current page or matches `update.itemId.toString()`
  /// against `realtimeKeyExtractor(row).toString()` for delete events.
  ///
  /// Typical usage:
  ///
  /// ```dart
  /// DataTableController<User>(
  ///   dataSource: source,
  ///   realtimeKeyExtractor: (u) => u.id,
  /// );
  /// ```
  final dynamic Function(T item)? realtimeKeyExtractor;

  // Estado atual
  DataTableResult<T>? _currentResult;
  DataTableRequest _currentRequest = const DataTableRequest();
  bool _isLoading = false;
  String? _error;

  // Cache para performance
  final Map<String, DataTableResult<T>> _cache = {};
  Timer? _debounceTimer;
  StreamSubscription<DataTableUpdate<T>>? _updatesSubscription;

  DataTableController({
    required DataTableSource<T> dataSource,
    this.realtimeKeyExtractor,
  }) : _dataSource = dataSource {
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
      var cacheable = false;

      if (_dataSource is HttpDataTableSource) {
        cacheable = (_dataSource as HttpDataTableSource).enableCache;
      }

      final cacheKey = _generateCacheKey(targetRequest);

      if (cacheable) {
        if (_cache.containsKey(cacheKey)) {
          _currentResult = _cache[cacheKey];
          _currentRequest = targetRequest;
          _setLoading(false);
          return;
        }
      }

      // Buscar do servidor
      final result = await _dataSource.fetch(targetRequest);

      // Atualizar estado
      _currentResult = result;
      _currentRequest = targetRequest;
      if (cacheable) {
        _cache[cacheKey] = result;
      }

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // PAGINAÇÃO ─ page é 1-indexed (ver `DataTableRequest`).
  Future<void> goToPage(int page) async {
    if (page < 1 || _isLoading) return;

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
        page: 1, // Reset para primeira página
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
      page: 1, // Reset para primeira página (1-indexed)
    );

    await fetchData(newRequest);
  }

  /// Replaces the entire sort stack with [sorts] (in priority order — the
  /// first entry is the primary sort).
  ///
  /// Use this when the UI supports multi-column sorting (Shift+click) and
  /// needs to express ordering across several columns at once. For a
  /// single-column sort, use [sort].
  Future<void> sortMulti(List<DataTableSort> sorts) async {
    final newRequest = _currentRequest.copyWith(
      sorts: List<DataTableSort>.of(sorts),
      page: 1,
    );
    await fetchData(newRequest);
  }

  // FILTROS
  Future<void> addFilter(
    String field,
    dynamic value, [
    FilterOperator? operator,
  ]) async {
    final existingFilters = List<DataTableFilter>.from(_currentRequest.filters);

    // Remover filtro existente para este campo
    existingFilters.removeWhere((f) => f.field == field);

    // Adicionar novo filtro se valor não for vazio
    if (value != null && value.toString().isNotEmpty) {
      existingFilters.add(
        DataTableFilter(
          field: field,
          value: value,
          operator: operator ?? FilterOperator.contains,
        ),
      );
    }

    final newRequest = _currentRequest.copyWith(
      filters: existingFilters,
      page: 1, // Reset para primeira página (1-indexed)
    );

    await fetchData(newRequest);
  }

  Future<void> removeFilter(String field) async {
    final newFilters = _currentRequest.filters
        .where((f) => f.field != field)
        .toList();

    final newRequest = _currentRequest.copyWith(filters: newFilters, page: 1);

    await fetchData(newRequest);
  }

  Future<void> clearFilters() async {
    final newRequest = _currentRequest.copyWith(
      filters: [],
      searchTerm: null,
      page: 1,
    );

    await fetchData(newRequest);
  }

  // REFRESH
  Future<void> refresh() async {
    _clearCache();
    _dataSource.clearCache();
    await fetchData();
  }

  /// Notifica listeners sem refetch. Usar quando os DTOs em [currentData]
  /// foram mutados in-place (ex.: classes mutaveis / freezed `@unfreezed`).
  void notifyDataChanged() {
    notifyListeners();
  }

  /// Substitui in-place o primeiro item de [currentData] que satisfaca
  /// [predicate], chamando [updater] para produzir o novo valor. Retorna
  /// `true` se algo foi atualizado e notifica listeners.
  ///
  /// Util quando o T e imutavel (freezed padrao) e o consumidor recebe um
  /// evento realtime de update de um unico registro: evita um refetch HTTP
  /// completo.
  bool updateItemWhere(
    bool Function(T item) predicate,
    T Function(T item) updater,
  ) {
    final result = _currentResult;
    if (result == null) return false;

    final index = result.data.indexWhere(predicate);
    if (index < 0) return false;

    final newData = List<T>.of(result.data);
    newData[index] = updater(newData[index]);

    _currentResult = DataTableResult<T>(
      data: newData,
      totalCount: result.totalCount,
      page: result.page,
      pageSize: result.pageSize,
      metadata: result.metadata,
    );

    notifyListeners();
    return true;
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

  /// Applies a realtime [update] to the current page in place when possible.
  ///
  /// - `refresh` always re-fetches.
  /// - `insert` appends [DataTableUpdate.item] (and any [DataTableUpdate.items])
  ///   to `_currentResult.data` and increments `totalCount`. The new rows
  ///   land at the end of the current page; callers that want strict
  ///   server-side ordering must call [refresh] themselves.
  /// - `update` requires [realtimeKeyExtractor]. The matching row in the
  ///   current page is replaced by [DataTableUpdate.item]. If the updated
  ///   row is not on the current page, falls back to [refresh] (so other
  ///   pages eventually see the change when navigated to).
  /// - `delete` removes the matching row by [DataTableUpdate.itemId] or by
  ///   key when [DataTableUpdate.item] is provided. `totalCount` is
  ///   decremented. If the row is not on the current page but the
  ///   `totalCount` decrement would change paging boundaries, falls back
  ///   to [refresh].
  ///
  /// Falls back to [refresh] whenever [realtimeKeyExtractor] is `null` —
  /// preserving the legacy behaviour for consumers that have not adopted
  /// the in-place path yet.
  void _handleRealtimeUpdate(DataTableUpdate<T> update) {
    final result = _currentResult;
    if (result == null) return;

    switch (update.type) {
      case DataTableUpdateType.refresh:
        refresh();
        return;
      case DataTableUpdateType.insert:
        _applyInsert(result, update);
        return;
      case DataTableUpdateType.update:
        _applyUpdate(result, update);
        return;
      case DataTableUpdateType.delete:
        _applyDelete(result, update);
        return;
    }
  }

  void _applyInsert(DataTableResult<T> result, DataTableUpdate<T> update) {
    final inserted = <T>[
      if (update.item != null) update.item as T,
      if (update.items != null) ...update.items!,
    ];
    if (inserted.isEmpty) {
      refresh();
      return;
    }
    _replaceResult(
      data: [...result.data, ...inserted],
      totalCount: result.totalCount + inserted.length,
    );
  }

  void _applyUpdate(DataTableResult<T> result, DataTableUpdate<T> update) {
    final extractor = realtimeKeyExtractor;
    final item = update.item;
    if (extractor == null || item == null) {
      refresh();
      return;
    }
    final targetKey = extractor(item);
    final index =
        result.data.indexWhere((row) => extractor(row) == targetKey);
    if (index < 0) {
      // The updated row is not on the current page — its effect will only
      // be visible when the user navigates to its page, so re-fetching is
      // the safest catch-all.
      refresh();
      return;
    }
    final newData = List<T>.of(result.data);
    newData[index] = item;
    _replaceResult(data: newData, totalCount: result.totalCount);
  }

  void _applyDelete(DataTableResult<T> result, DataTableUpdate<T> update) {
    final extractor = realtimeKeyExtractor;
    if (extractor == null) {
      refresh();
      return;
    }
    int index = -1;
    if (update.itemId != null) {
      final id = update.itemId!;
      index = result.data.indexWhere(
        (row) => extractor(row).toString() == id,
      );
    } else if (update.item != null) {
      final key = extractor(update.item as T);
      index = result.data.indexWhere((row) => extractor(row) == key);
    }
    if (index < 0) {
      // Row lives on another page — re-fetch so totalCount and pages stay
      // consistent.
      refresh();
      return;
    }
    final newData = List<T>.of(result.data)..removeAt(index);
    _replaceResult(
      data: newData,
      totalCount: (result.totalCount - 1).clamp(0, 1 << 31),
    );
  }

  void _replaceResult({
    required List<T> data,
    required int totalCount,
  }) {
    final result = _currentResult;
    if (result == null) return;
    _currentResult = DataTableResult<T>(
      data: data,
      totalCount: totalCount,
      page: result.page,
      pageSize: result.pageSize,
      metadata: result.metadata,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _updatesSubscription?.cancel();
    _dataSource.dispose();
    super.dispose();
  }
}
