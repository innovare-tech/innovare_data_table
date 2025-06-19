// =============================================================================
// ARQUIVO: lib/app/ui/widgets/data_table/data_sources/http_data_table_source.dart
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'data_table_source.dart';
import 'data_table_models.dart';

// TIPEDEFS PARA BUILDERS FLEXÍVEIS
typedef UrlBuilder = String Function(DataTableRequest request);
typedef HeadersBuilder = Map<String, String> Function();
typedef ResponseParser<T> = DataTableResult<T> Function(dynamic json);
typedef ItemParser<T> = T Function(Map<String, dynamic> json);
typedef ErrorHandler = void Function(dynamic error, StackTrace? stackTrace);

// HTTP DATASOURCE ULTRA-FLEXÍVEL
class HttpDataTableSource<T> extends DataTableSource<T> {
  final UrlBuilder urlBuilder;
  final HeadersBuilder? headersBuilder;
  final ResponseParser<T> responseParser;
  final ErrorHandler? errorHandler;
  final http.Client? httpClient;
  final Duration timeout;
  final bool enableCache;

  // Cache opcional
  final Map<String, DataTableResult<T>> _cache = {};

  HttpDataTableSource({
    required this.urlBuilder,
    required this.responseParser,
    this.headersBuilder,
    this.errorHandler,
    this.httpClient,
    this.timeout = const Duration(seconds: 30),
    this.enableCache = true,
  });

  @override
  Future<DataTableResult<T>> fetch(DataTableRequest request) async {
    try {
      print('🔍 HTTP FETCH: Iniciando requisição');

      // Verificar cache primeiro
      if (enableCache) {
        final cacheKey = _generateCacheKey(request);
        if (_cache.containsKey(cacheKey)) {
          print('🔍 HTTP FETCH: Cache hit');
          return _cache[cacheKey]!;
        }
      }

      // Construir URL
      final url = urlBuilder(request);
      final uri = Uri.parse(url);
      print('🔍 HTTP FETCH: URL construída: $url');

      // Construir headers
      final headers = headersBuilder?.call() ?? <String, String>{};
      print('🔍 HTTP FETCH: Headers: $headers');

      // Fazer requisição
      final client = httpClient ?? http.Client();
      print('🔍 HTTP FETCH: Fazendo requisição...');
      final response = await client.get(uri, headers: headers).timeout(timeout);

      print('🔍 HTTP FETCH: Status da resposta: ${response.statusCode}');

      // Verificar status da resposta
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('🔍 HTTP FETCH: Response body (primeiros 100 chars): ${response.body.substring(0, response.body.length.clamp(0, 100))}...');

        // ✅ Parse da resposta SEM cast forçado
        print('🔍 HTTP FETCH: Fazendo json.decode...');
        final jsonData = json.decode(response.body);
        print('🔍 HTTP FETCH: JSON decodificado, tipo: ${jsonData.runtimeType}');

        print('🔍 HTTP FETCH: Chamando responseParser...');
        final result = responseParser(jsonData);
        print('🔍 HTTP FETCH: ResponseParser executado com sucesso');

        // Salvar no cache
        if (enableCache) {
          final cacheKey = _generateCacheKey(request);
          _cache[cacheKey] = result;
        }

        print('🔍 HTTP FETCH: Retornando resultado com ${result.data.length} itens');
        return result;
      } else {
        throw HttpException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          response.statusCode,
          response.body,
        );
      }
    } catch (e, stackTrace) {
      print('🔍 HTTP FETCH: ERRO CAPTURADO: $e');
      print('🔍 HTTP FETCH: Stack trace: $stackTrace');
      errorHandler?.call(e, stackTrace);
      rethrow;
    }
  }

  @override
  void clearCache() {
    _cache.clear();
  }

  String _generateCacheKey(DataTableRequest request) {
    return '${request.page}_${request.pageSize}_${request.searchTerm}_'
        '${request.sorts.map((s) => '${s.field}:${s.ascending}').join(',')}_'
        '${request.filters.map((f) => '${f.field}:${f.value}').join(',')}';
  }

  // FACTORY CONSTRUCTORS PARA DIFERENTES PADRÕES DE API

  /// Preset para APIs no padrão Laravel
  factory HttpDataTableSource.laravel({
    required String baseUrl,
    required String endpoint,
    required ItemParser<T> fromJson,
    String Function()? tokenProvider,
    Map<String, String>? additionalHeaders,
    String searchParam = 'search',
    String pageParam = 'page',
    String pageSizeParam = 'per_page',
    String sortParam = 'sort',
    ErrorHandler? errorHandler,
  }) {
    return HttpDataTableSource<T>(
      urlBuilder: (request) {
        final uri = Uri.parse('$baseUrl$endpoint');
        final queryParams = <String, String>{};

        // Paginação
        queryParams[pageParam] = (request.page + 1).toString(); // Laravel usa base-1
        queryParams[pageSizeParam] = request.pageSize.toString();

        // Busca
        if (request.searchTerm?.isNotEmpty == true) {
          queryParams[searchParam] = request.searchTerm!;
        }

        // Ordenação
        if (request.sorts.isNotEmpty) {
          final sort = request.sorts.first;
          queryParams[sortParam] = '${sort.field}:${sort.ascending ? 'asc' : 'desc'}';
        }

        // Filtros
        for (final filter in request.filters) {
          queryParams['filter[${filter.field}]'] = filter.value.toString();
        }

        return uri.replace(queryParameters: queryParams).toString();
      },
      headersBuilder: () {
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };

        if (tokenProvider != null) {
          headers['Authorization'] = 'Bearer ${tokenProvider()}';
        }

        if (additionalHeaders != null) {
          headers.addAll(additionalHeaders);
        }

        return headers;
      },
      responseParser: (json) {
        final data = json['data'] as List;
        final items = data.map((item) => fromJson(item as Map<String, dynamic>)).toList();

        // Laravel pagination meta
        final meta = json['meta'] ?? json;

        return DataTableResult<T>(
          data: items,
          totalCount: meta['total'] ?? data.length,
          page: (meta['current_page'] ?? 1) - 1, // Converter para base-0
          pageSize: meta['per_page'] ?? items.length,
          metadata: meta,
        );
      },
      errorHandler: errorHandler,
    );
  }

  /// Preset para APIs no padrão Django REST Framework
  factory HttpDataTableSource.django({
    required String baseUrl,
    required String endpoint,
    required ItemParser<T> fromJson,
    String Function()? tokenProvider,
    Map<String, String>? additionalHeaders,
    String searchParam = 'search',
    String pageParam = 'page',
    String pageSizeParam = 'page_size',
    String orderingParam = 'ordering',
    ErrorHandler? errorHandler,
  }) {
    return HttpDataTableSource<T>(
      urlBuilder: (request) {
        final uri = Uri.parse('$baseUrl$endpoint');
        final queryParams = <String, String>{};

        // Paginação (Django usa base-1)
        queryParams[pageParam] = (request.page + 1).toString();
        queryParams[pageSizeParam] = request.pageSize.toString();

        // Busca
        if (request.searchTerm?.isNotEmpty == true) {
          queryParams[searchParam] = request.searchTerm!;
        }

        // Ordenação
        if (request.sorts.isNotEmpty) {
          final sorts = request.sorts.map((s) =>
          s.ascending ? s.field : '-${s.field}'
          ).join(',');
          queryParams[orderingParam] = sorts;
        }

        // Filtros
        for (final filter in request.filters) {
          queryParams[filter.field] = filter.value.toString();
        }

        return uri.replace(queryParameters: queryParams).toString();
      },
      headersBuilder: () {
        final headers = <String, String>{
          'Content-Type': 'application/json',
        };

        if (tokenProvider != null) {
          headers['Authorization'] = 'Token ${tokenProvider()}';
        }

        if (additionalHeaders != null) {
          headers.addAll(additionalHeaders);
        }

        return headers;
      },
      responseParser: (json) {
        final results = json['results'] as List;
        final items = results.map((item) => fromJson(item as Map<String, dynamic>)).toList();

        return DataTableResult<T>(
          data: items,
          totalCount: json['count'] ?? results.length,
          page: 0, // 🔧 CORRIGIDO: Django não retorna página na resposta
          pageSize: items.length,
          metadata: json,
        );
      },
      errorHandler: errorHandler,
    );
  }

  /// Preset customizável para qualquer API
  factory HttpDataTableSource.custom({
    required String baseUrl,
    required String endpoint,
    required ItemParser<T> fromJson,
    String Function()? tokenProvider,
    Map<String, String>? additionalHeaders,
    Map<String, String> paramNames = const {
      'page': 'page',
      'pageSize': 'limit',
      'search': 'q',
      'sort': 'sort',
    },
    String Function(DataTableRequest)? customUrlBuilder,
    DataTableResult<T> Function(Map<String, dynamic>, ItemParser<T>)? customResponseParser,
    ErrorHandler? errorHandler,
  }) {
    return HttpDataTableSource<T>(
      urlBuilder: customUrlBuilder ?? (request) {
        final uri = Uri.parse('$baseUrl$endpoint');
        final queryParams = <String, String>{};

        // Usar nomes de parâmetros customizados
        queryParams[paramNames['page']!] = request.page.toString();
        queryParams[paramNames['pageSize']!] = request.pageSize.toString();

        if (request.searchTerm?.isNotEmpty == true) {
          queryParams[paramNames['search']!] = request.searchTerm!;
        }

        if (request.sorts.isNotEmpty) {
          final sort = request.sorts.first;
          queryParams[paramNames['sort']!] = '${sort.field}:${sort.ascending ? 'asc' : 'desc'}';
        }

        for (final filter in request.filters) {
          queryParams[filter.field] = filter.value.toString();
        }

        return uri.replace(queryParameters: queryParams).toString();
      },
      headersBuilder: () {
        final headers = <String, String>{
          'Content-Type': 'application/json',
        };

        if (tokenProvider != null) {
          headers['Authorization'] = 'Bearer ${tokenProvider()}';
        }

        if (additionalHeaders != null) {
          headers.addAll(additionalHeaders);
        }

        return headers;
      },
      responseParser: customResponseParser != null
          ? (json) => customResponseParser(json, fromJson)
          : (json) {
        // Parser genérico - adapte conforme sua API
        final data = json['data'] ?? json['items'] ?? json;
        if (data is List) {
          final items = data.map((item) => fromJson(item as Map<String, dynamic>)).toList();
          return DataTableResult<T>(
            data: items,
            totalCount: json['total'] ?? json['count'] ?? items.length,
            page: json['page'] ?? 0,
            pageSize: json['pageSize'] ?? json['limit'] ?? items.length,
            metadata: json,
          );
        }
        throw FormatException('Formato de resposta não suportado');
      },
      errorHandler: errorHandler,
    );
  }
}

// CLASSE DE EXCEÇÃO CUSTOMIZADA
class HttpException implements Exception {
  final String message;
  final int statusCode;
  final String? responseBody;

  HttpException(this.message, this.statusCode, [this.responseBody]);

  @override
  String toString() => 'HttpException: $message (Status: $statusCode)';
}

// =============================================================================
// ARQUIVO: lib/app/ui/widgets/data_table/data_sources/api_helpers.dart
// =============================================================================

// HELPERS PARA CONSTRUÇÃO DE URLs E PARSING
class ApiHelpers {
  /// Helper para construir query parameters de filtros
  static Map<String, String> buildFilterParams(
      List<DataTableFilter> filters, {
        String Function(String field, dynamic value)? customFilter,
      }) {
    final params = <String, String>{};

    for (final filter in filters) {
      if (customFilter != null) {
        final customParam = customFilter(filter.field, filter.value);
        if (customParam.isNotEmpty) {
          params[filter.field] = customParam;
        }
      } else {
        params[filter.field] = filter.value.toString();
      }
    }

    return params;
  }

  /// Helper para construir parâmetros de ordenação
  static String buildSortParam(
      List<DataTableSort> sorts, {
        String Function(DataTableSort sort)? customSort,
      }) {
    if (sorts.isEmpty) return '';

    return sorts.map((sort) {
      if (customSort != null) {
        return customSort(sort);
      }
      return '${sort.field}:${sort.ascending ? 'asc' : 'desc'}';
    }).join(',');
  }

  /// Helper para parsing de paginação comum
  static DataTableResult<T> parseStandardPagination<T>(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJson, {
        String dataKey = 'data',
        String totalKey = 'total',
        String pageKey = 'page',
        String pageSizeKey = 'pageSize',
      }) {
    final data = json[dataKey] as List;
    final items = data.map((item) => fromJson(item as Map<String, dynamic>)).toList();

    return DataTableResult<T>(
      data: items,
      totalCount: json[totalKey] ?? data.length,
      page: json[pageKey] ?? 0,
      pageSize: json[pageSizeKey] ?? items.length,
      metadata: json,
    );
  }
}