import 'dart:async';

import '../data_table_filters.dart'; // Para usar FilterOperator
import 'data_table_models.dart';

abstract class DataTableSource<T> {
  Future<DataTableResult<T>> fetch(DataTableRequest request);

  Stream<DataTableUpdate<T>>? get updates => null;

  void clearCache() {}

  void dispose() {}
}

class LocalDataTableSource<T> extends DataTableSource<T> {
  final List<T> _allData;
  final String Function(T item, String field)? _fieldGetter;

  LocalDataTableSource({
    required List<T> data,
    String Function(T item, String field)? fieldGetter,
  }) : _allData = data,
        _fieldGetter = fieldGetter;

  @override
  Future<DataTableResult<T>> fetch(DataTableRequest request) async {
    var filteredData = List<T>.from(_allData);

    // Aplicar busca global
    if (request.searchTerm?.isNotEmpty == true) {
      filteredData = filteredData.where((item) {
        if (_fieldGetter != null) {
          // Use custom field getter se disponível
          return _fieldGetter!(item, 'search')
              .toLowerCase()
              .contains(request.searchTerm!.toLowerCase());
        }
        // Fallback: converter item para string
        return item.toString()
            .toLowerCase()
            .contains(request.searchTerm!.toLowerCase());
      }).toList();
    }

    // Aplicar filtros específicos
    for (final filter in request.filters) {
      filteredData = filteredData.where((item) {
        if (_fieldGetter != null) {
          final value = _fieldGetter!(item, filter.field);
          return _applyFilter(value, filter);
        }
        return true; // Skip se não há field getter
      }).toList();
    }

    // Aplicar ordenação
    if (request.sorts.isNotEmpty) {
      filteredData.sort((a, b) {
        for (final sort in request.sorts) {
          int comparison = 0;

          if (_fieldGetter != null) {
            final valueA = _fieldGetter!(a, sort.field);
            final valueB = _fieldGetter!(b, sort.field);
            comparison = _compareValues(valueA, valueB);
          }

          if (comparison != 0) {
            return sort.ascending ? comparison : -comparison;
          }
        }
        return 0;
      });
    }

    // Aplicar paginação
    final totalCount = filteredData.length;
    final startIndex = request.page * request.pageSize;
    final endIndex = (startIndex + request.pageSize).clamp(0, totalCount);

    final pageData = startIndex < totalCount
        ? filteredData.sublist(startIndex, endIndex)
        : <T>[];

    return DataTableResult<T>(
      data: pageData,
      totalCount: totalCount,
      page: request.page,
      pageSize: request.pageSize,
    );
  }

  bool _applyFilter(String value, DataTableFilter filter) {
    switch (filter.operator) {
      case FilterOperator.equals:
        return value.toLowerCase() == filter.value.toString().toLowerCase();
      case FilterOperator.contains:
        return value.toLowerCase().contains(filter.value.toString().toLowerCase());
      case FilterOperator.startsWith:
        return value.toLowerCase().startsWith(filter.value.toString().toLowerCase());
      case FilterOperator.endsWith:
        return value.toLowerCase().endsWith(filter.value.toString().toLowerCase());
      default:
        return true;
    }
  }

  int _compareValues(String a, String b) {
    // Tentar comparar como números primeiro
    final numA = double.tryParse(a);
    final numB = double.tryParse(b);

    if (numA != null && numB != null) {
      return numA.compareTo(numB);
    }

    // Fallback para comparação de string
    return a.compareTo(b);
  }
}