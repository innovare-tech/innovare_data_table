import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:innovare_data_table/innovare_data_table.dart';

/// Tests the public `invalidateCache({where})` API introduced in Wave 3.5.
///
/// Each test uses a fake `http.Client` that counts requests, so assertions
/// verify both the cache mutation (`cachedRequests` / `cacheLength`) and
/// the network impact (a subsequent `fetch` should or shouldn't go out
/// to the wire depending on whether the entry was invalidated).
void main() {
  group('HttpDataTableSource.invalidateCache', () {
    late _CountingClient client;
    late HttpDataTableSource<_Row> source;

    setUp(() {
      client = _CountingClient();
      source = HttpDataTableSource<_Row>(
        urlBuilder: (req) {
          final qp = {
            'page': req.page.toString(),
            'pageSize': req.pageSize.toString(),
            for (final f in req.filters) f.field: f.value.toString(),
          };
          return Uri.https('example.test', '/rows', qp).toString();
        },
        responseParser: (json) => DataTableResult<_Row>(
          data: (json['data'] as List)
              .map((e) => _Row(id: (e as Map)['id'] as int))
              .toList(),
          totalCount: json['total'] ?? 0,
          page: json['page'] ?? 1,
          pageSize: json['pageSize'] ?? 10,
        ),
        httpClient: client,
      );
    });

    tearDown(() => source.dispose());

    test('without a predicate, wipes the whole cache (same as clearCache)',
        () async {
      await source.fetch(const DataTableRequest(page: 1, pageSize: 10));
      await source.fetch(const DataTableRequest(page: 2, pageSize: 10));
      expect(source.cacheLength, 2);
      expect(client.calls, 2);

      source.invalidateCache();

      expect(source.cacheLength, 0);
      // Next fetch on the same page must hit the wire again.
      await source.fetch(const DataTableRequest(page: 1, pageSize: 10));
      expect(client.calls, 3);
    });

    test('with a predicate, only entries matching are dropped', () async {
      // Cache: page 1 unfiltered, page 1 filtered by status=active,
      // page 2 unfiltered.
      await source.fetch(const DataTableRequest(page: 1, pageSize: 10));
      await source.fetch(const DataTableRequest(
        page: 1,
        pageSize: 10,
        filters: [DataTableFilter(field: 'status', value: 'active')],
      ));
      await source.fetch(const DataTableRequest(page: 2, pageSize: 10));
      expect(source.cacheLength, 3);
      expect(client.calls, 3);

      // Invalidate only the entries with a status=active filter.
      source.invalidateCache(
        where: (req) => req.filters
            .any((f) => f.field == 'status' && f.value == 'active'),
      );

      expect(source.cacheLength, 2);
      // Page 1 unfiltered still cached.
      await source.fetch(const DataTableRequest(page: 1, pageSize: 10));
      expect(client.calls, 3, reason: 'unaffected entry must remain cached');

      // The invalidated filtered request now refetches.
      await source.fetch(const DataTableRequest(
        page: 1,
        pageSize: 10,
        filters: [DataTableFilter(field: 'status', value: 'active')],
      ));
      expect(client.calls, 4);
    });

    test('cached entry stores the original DataTableRequest, exposed via '
        'cachedRequests', () async {
      await source.fetch(const DataTableRequest(
        page: 3,
        pageSize: 25,
        searchTerm: 'foo',
      ));

      final cached = source.cachedRequests.single;
      expect(cached.page, 3);
      expect(cached.pageSize, 25);
      expect(cached.searchTerm, 'foo');
    });

    test('predicate that matches nothing is a no-op', () async {
      await source.fetch(const DataTableRequest(page: 1, pageSize: 10));
      expect(source.cacheLength, 1);

      source.invalidateCache(where: (req) => req.page == 999);
      expect(source.cacheLength, 1);
    });
  });
}

class _Row {
  final int id;
  const _Row({required this.id});
}

/// Minimal fake `http.Client` that returns a constant payload and counts
/// the number of GET requests it received.
class _CountingClient extends http.BaseClient {
  int calls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls++;
    final body = jsonEncode({
      'data': [
        {'id': 1},
        {'id': 2},
      ],
      'total': 50,
      'page': int.tryParse(request.url.queryParameters['page'] ?? '') ?? 1,
      'pageSize':
          int.tryParse(request.url.queryParameters['pageSize'] ?? '') ?? 10,
    });
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(body)),
      200,
      reasonPhrase: 'OK',
    );
  }
}
