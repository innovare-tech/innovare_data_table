import 'package:innovare_data_table/src/data_table_filters.dart';

/// A read request issued by `DataTableController` to a `DataTableSource`.
///
/// **Page indexing convention: 1-indexed.** The first page is `1`, never
/// `0`. This matches:
///
/// - Real-world APIs (Laravel, Django REST Framework, Rails — all 1-indexed).
/// - User-facing pagination text (the UI displays "Página 1 de N").
/// - `hasNextPage` / `hasPreviousPage` semantics in [DataTableResult].
///
/// Custom `DataTableSource` implementations and `urlBuilder` callbacks must
/// produce 1-indexed values to the backend. Built-in factories
/// (`HttpDataTableSource.laravel`/`.django`/`.custom`) pass `request.page`
/// straight through to the API.
class DataTableRequest {
  /// 1-indexed page number. The first page is `1`.
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
  }) : assert(page >= 1, 'page is 1-indexed; pass 1 for the first page');

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

/// A page of results returned by a `DataTableSource`.
///
/// `page` follows the 1-indexed convention documented in [DataTableRequest].
class DataTableResult<T> {
  final List<T> data;
  final int totalCount;

  /// 1-indexed page number. The first page is `1`.
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

  /// `true` when there is at least one page after this one.
  ///
  /// Uses 1-indexed arithmetic: `page * pageSize` is the number of items
  /// covered by pages 1..[page], so when it is below [totalCount] there is
  /// still data to fetch.
  bool get hasNextPage => page * pageSize < totalCount;

  /// `true` when there is at least one page before this one — i.e. this is
  /// not the first page.
  bool get hasPreviousPage => page > 1;

  /// Total number of pages. Always `>= 1` when [totalCount] > 0; returns
  /// `0` for an empty data set so callers can distinguish "no pages" from
  /// "first page".
  int get totalPages =>
      totalCount == 0 ? 0 : (totalCount / pageSize).ceil();

  /// `true` when this is the very first page.
  bool get isFirstPage => page == 1;

  /// `true` when this is the very last page (or the only page).
  bool get isLastPage => totalPages == 0 || page >= totalPages;

  factory DataTableResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return DataTableResult<T>(
      data: (json['data'] as List).map((item) => fromJson(item)).toList(),
      totalCount: json['totalCount'] ?? json['total'] ?? 0,
      // Default to 1 (first page), 1-indexed convention. Accepts the same
      // common backend keys as before.
      page: json['page'] ?? json['currentPage'] ?? 1,
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