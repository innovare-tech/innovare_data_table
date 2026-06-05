// =============================================================================
// ARQUIVO: lib/app/ui/widgets/data_table/data_sources/http_data_table_source.dart
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innovare_core/data/rest_connect.dart';
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
  final RestConnect? customRestConnect;

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
    this.customRestConnect,
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

      print('🔍 HTTP FETCH: Fazendo requisição...');

      int statusCode;
      String? body;
      String? statusText;

      if (customRestConnect != null) {
        final response = await customRestConnect!.get<dynamic>(url, headers: headers);
        print('🔍 HTTP FETCH: Status da resposta: ${response.statusCode}');

        statusCode = response.statusCode!;
        body = response.bodyString;
        statusText = response.statusText;
      } else {
        final client = httpClient ?? http.Client();

        final response = await client.get(uri, headers: headers).timeout(timeout);

        print('🔍 HTTP FETCH: Status da resposta: ${response.statusCode}');

        statusCode = response.statusCode;
        body = response.body;
        statusText = response.reasonPhrase;
      }


      // Verificar status da resposta
      if (statusCode >= 200 && statusCode < 300) {
        // ✅ Parse da resposta SEM cast forçado
        print('🔍 HTTP FETCH: Fazendo json.decode...');
        final jsonData = json.decode(body!);
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
          'HTTP ${statusCode}: ${statusText}',
          statusCode,
          body,
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

        // Paginação — `request.page` é 1-indexed (ver `DataTableRequest`),
        // o mesmo que Laravel espera.
        queryParams[pageParam] = request.page.toString();
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

        // Laravel pagination meta — `current_page` já é 1-indexed.
        final meta = json['meta'] ?? json;

        return DataTableResult<T>(
          data: items,
          totalCount: meta['total'] ?? data.length,
          page: meta['current_page'] ?? 1,
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

        // Paginação — `request.page` é 1-indexed (ver `DataTableRequest`),
        // o mesmo que Django REST Framework espera.
        queryParams[pageParam] = request.page.toString();
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
          // Django REST Framework não retorna a página atual na resposta.
          // Como o request foi 1-indexed, devolvemos 1 como base segura
          // (`fetchData` já tem `_currentRequest.page` para o controller
          // soubesse a "real" página atual, então este valor é apenas o
          // fallback informativo).
          page: 1,
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
        // Parser genérico - adapte conforme sua API.
        // `page` é 1-indexed (ver `DataTableRequest`); default 1.
        final data = json['data'] ?? json['items'] ?? json;
        if (data is List) {
          final items = data.map((item) => fromJson(item as Map<String, dynamic>)).toList();
          return DataTableResult<T>(
            data: items,
            totalCount: json['total'] ?? json['count'] ?? items.length,
            page: json['page'] ?? 1,
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
      // 1-indexed — see DataTableRequest documentation.
      page: json[pageKey] ?? 1,
      pageSize: json[pageSizeKey] ?? items.length,
      metadata: json,
    );
  }
}