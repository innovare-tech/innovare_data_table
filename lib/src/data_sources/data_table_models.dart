import 'package:innovare_data_table/src/data_table_filters.dart';

class DataTableRequest {
  final int page;
  final int pageSize;
  final String? searchTerm;
  final List<DataTableSort> sorts;
  final List<DataTableFilter> filters;
  final Map<String, dynamic> customParams;

  const DataTableRequest({
    this.page = 1,
    this.pageSize = 10,
    this.searchTerm,
    this.sorts = const [],
    this.filters = const [],
    this.customParams = const {},
  });

  // Converter para query parameters para APIs REST
  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (searchTerm?.isNotEmpty == true) {
      params['search'] = searchTerm;
    }

    if (sorts.isNotEmpty) {
      params['sort'] = sorts.map((s) => '${s.field}:${s.ascending ? 'asc' : 'desc'}').join(',');
    }

    if (filters.isNotEmpty) {
      for (final filter in filters) {
        params['filter[${filter.field}]'] = filter.value;
      }
    }

    params.addAll(customParams);
    return params;
  }

  DataTableRequest copyWith({
    int? page,
    int? pageSize,
    String? searchTerm,
    List<DataTableSort>? sorts,
    List<DataTableFilter>? filters,
    Map<String, dynamic>? customParams,
  }) {
    return DataTableRequest(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      searchTerm: searchTerm ?? this.searchTerm,
      sorts: sorts ?? this.sorts,
      filters: filters ?? this.filters,
      customParams: customParams ?? this.customParams,
    );
  }
}

class DataTableSort {
  final String field;
  final bool ascending;

  const DataTableSort({
    required this.field,
    this.ascending = true,
  });
}

enum FilterType {
  quick,
  advanced,
}

class DataTableFilter {
  final String field;
  final dynamic value;
  final FilterOperator operator;
  final FilterType type;

  const DataTableFilter({
    required this.field,
    required this.value,
    this.operator = FilterOperator.equals,
    this.type = FilterType.quick,
  });

  bool get isQuickFilter => type == FilterType.quick;
  bool get isAdvancedFilter => type == FilterType.advanced;
}

class DataTableResult<T> {
  final List<T> data;
  final int totalCount;
  final int page;
  final int pageSize;
  final Map<String, dynamic>? metadata;

  const DataTableResult({
    required this.data,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    this.metadata,
  });

  bool get hasNextPage => page * pageSize < totalCount;
  bool get hasPreviousPage => page > 0;
  int get totalPages => (totalCount / pageSize).ceil();

  factory DataTableResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return DataTableResult<T>(
      data: (json['data'] as List).map((item) => fromJson(item)).toList(),
      totalCount: json['totalCount'] ?? json['total'] ?? 0,
      page: json['page'] ?? json['currentPage'] ?? 0,
      pageSize: json['pageSize'] ?? json['limit'] ?? 10,
      metadata: json['metadata'],
    );
  }
}

class DataTableUpdate<T> {
  final DataTableUpdateType type;
  final T? item;
  final List<T>? items;
  final String? itemId;

  const DataTableUpdate({
    required this.type,
    this.item,
    this.items,
    this.itemId,
  });
}

enum DataTableUpdateType {
  insert,
  update,
  delete,
  refresh,
}