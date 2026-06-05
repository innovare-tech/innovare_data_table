import 'package:flutter_test/flutter_test.dart';
import 'package:innovare_data_table/innovare_data_table.dart';

/// Tests that lock down the 1-indexed page convention announced in
/// `DataTableRequest`. Pagination has historically drifted between 0-indexed
/// (internal) and 1-indexed (display, defaults, API factories) — these
/// regressions caught a real bug in `LocalDataTableSource.fetch` that skipped
/// `pageSize` items on the first page when `request.page = 1` was passed.
void main() {
  group('DataTableRequest', () {
    test('defaults to page 1 (1-indexed)', () {
      const r = DataTableRequest();
      expect(r.page, 1);
    });

    test('rejects page < 1 via assertion', () {
      expect(() => DataTableRequest(page: 0), throwsA(isA<AssertionError>()));
      expect(() => DataTableRequest(page: -1), throwsA(isA<AssertionError>()));
    });

    test('toQueryParameters emits the 1-indexed page value as-is', () {
      const r = DataTableRequest(page: 3, pageSize: 25);
      expect(r.toQueryParameters()['page'], 3);
      expect(r.toQueryParameters()['pageSize'], 25);
    });
  });

  group('DataTableResult', () {
    test('hasPreviousPage is false on the first page', () {
      const r = DataTableResult<int>(
        data: [],
        totalCount: 100,
        page: 1,
        pageSize: 10,
      );
      expect(r.hasPreviousPage, isFalse);
      expect(r.isFirstPage, isTrue);
      expect(r.isLastPage, isFalse);
    });

    test('hasNextPage is correct on intermediate pages', () {
      const r = DataTableResult<int>(
        data: [],
        totalCount: 100,
        page: 5,
        pageSize: 10,
      );
      expect(r.hasPreviousPage, isTrue);
      expect(r.hasNextPage, isTrue);
      expect(r.isFirstPage, isFalse);
      expect(r.isLastPage, isFalse);
    });

    test('hasNextPage is false on the last page', () {
      const r = DataTableResult<int>(
        data: [],
        totalCount: 100,
        page: 10,
        pageSize: 10,
      );
      expect(r.hasPreviousPage, isTrue);
      expect(r.hasNextPage, isFalse);
      expect(r.isLastPage, isTrue);
    });

    test('totalPages is 0 for an empty data set, >= 1 otherwise', () {
      const empty = DataTableResult<int>(
        data: [],
        totalCount: 0,
        page: 1,
        pageSize: 10,
      );
      expect(empty.totalPages, 0);
      expect(empty.isLastPage, isTrue);

      const single = DataTableResult<int>(
        data: [],
        totalCount: 7,
        page: 1,
        pageSize: 10,
      );
      expect(single.totalPages, 1);
      expect(single.isFirstPage, isTrue);
      expect(single.isLastPage, isTrue);
    });

    test('fromJson defaults page to 1 (was 0 before)', () {
      final r = DataTableResult<int>.fromJson(
        {'data': <int>[], 'totalCount': 0},
        (json) => json['n'] as int,
      );
      expect(r.page, 1);
    });
  });

  group('LocalDataTableSource.fetch — regression: first page used to skip '
      'pageSize items because startIndex was `page * pageSize`', () {
    final source = LocalDataTableSource<int>(
      data: List<int>.generate(50, (i) => i + 1), // 1..50
      fieldGetter: (item, field) => item.toString(),
    );

    test('page 1 returns items 1..10 (used to return 11..20)', () async {
      final result = await source.fetch(const DataTableRequest());
      expect(result.data, equals(List<int>.generate(10, (i) => i + 1)));
      expect(result.page, 1);
      expect(result.totalCount, 50);
      expect(result.hasPreviousPage, isFalse);
      expect(result.hasNextPage, isTrue);
    });

    test('page 3 returns items 21..30', () async {
      final result = await source.fetch(
        const DataTableRequest(page: 3, pageSize: 10),
      );
      expect(result.data, equals(List<int>.generate(10, (i) => i + 21)));
    });

    test('last page returns the trailing slice and reports isLastPage',
        () async {
      final result = await source.fetch(
        const DataTableRequest(page: 5, pageSize: 10),
      );
      expect(result.data, equals(List<int>.generate(10, (i) => i + 41)));
      expect(result.isLastPage, isTrue);
      expect(result.hasNextPage, isFalse);
    });

    test('page beyond range returns empty list (no crash)', () async {
      final result = await source.fetch(
        const DataTableRequest(page: 99, pageSize: 10),
      );
      expect(result.data, isEmpty);
      expect(result.totalCount, 50);
    });
  });

  group('DataTableController — pagination boundary guards', () {
    late DataTableController<int> controller;

    setUp(() {
      controller = DataTableController<int>(
        dataSource: LocalDataTableSource<int>(
          data: List<int>.generate(30, (i) => i + 1),
          fieldGetter: (item, field) => item.toString(),
        ),
      );
    });

    tearDown(() => controller.dispose());

    test('initial fetch lands on page 1', () async {
      await controller.fetchData();
      expect(controller.currentResult!.page, 1);
      expect(controller.currentData.first, 1);
    });

    test('goToPage rejects page < 1 silently', () async {
      await controller.fetchData();
      await controller.goToPage(0);
      expect(controller.currentResult!.page, 1);

      await controller.goToPage(-3);
      expect(controller.currentResult!.page, 1);
    });

    test('nextPage advances and previousPage retreats', () async {
      await controller.fetchData(const DataTableRequest(pageSize: 10));
      expect(controller.currentResult!.page, 1);

      await controller.nextPage();
      expect(controller.currentResult!.page, 2);

      await controller.nextPage();
      expect(controller.currentResult!.page, 3);

      // No fourth page — stays put.
      await controller.nextPage();
      expect(controller.currentResult!.page, 3);

      await controller.previousPage();
      expect(controller.currentResult!.page, 2);
    });

    test('sort resets to page 1 (was page 0, used to violate the assert)',
        () async {
      await controller.fetchData(const DataTableRequest(pageSize: 10));
      await controller.nextPage(); // page 2
      expect(controller.currentResult!.page, 2);

      await controller.sort('value', true);
      expect(controller.currentResult!.page, 1);
    });

    test('addFilter/removeFilter/clearFilters all reset to page 1', () async {
      await controller.fetchData(const DataTableRequest(pageSize: 10));
      await controller.nextPage();
      expect(controller.currentResult!.page, 2);

      await controller.addFilter('value', '5');
      expect(controller.currentResult!.page, 1);

      await controller.fetchData(const DataTableRequest(page: 2));
      await controller.removeFilter('value');
      expect(controller.currentResult!.page, 1);

      await controller.fetchData(const DataTableRequest(page: 2));
      await controller.clearFilters();
      expect(controller.currentResult!.page, 1);
    });
  });

  group('HttpDataTableSource factories — page indexing', () {
    test('laravel response parser keeps 1-indexed current_page', () {
      // Build a Laravel factory just to grab its response parser.
      final source = HttpDataTableSource<int>.laravel(
        baseUrl: 'https://example.com',
        endpoint: '/users',
        fromJson: (json) => json['id'] as int,
      );

      // ResponseParser is a closure inside the factory; round-trip via fetch
      // is overkill for a parser unit test, so we exercise it via a minimal
      // JSON payload through the parser field.
      final parsed = source.responseParser({
        'data': [
          {'id': 1},
          {'id': 2},
        ],
        'meta': {
          'total': 42,
          'current_page': 3, // Laravel's 1-indexed value
          'per_page': 2,
        },
      });

      expect(parsed.page, 3);
      expect(parsed.totalCount, 42);
      expect(parsed.pageSize, 2);
      expect(parsed.isFirstPage, isFalse);
    });

    test('laravel url builder forwards page as-is (no +1 anymore)', () {
      final source = HttpDataTableSource<int>.laravel(
        baseUrl: 'https://example.com',
        endpoint: '/users',
        fromJson: (json) => json['id'] as int,
      );

      final url = source.urlBuilder(const DataTableRequest(page: 4));
      expect(Uri.parse(url).queryParameters['page'], '4');
    });

    test('django url builder forwards page as-is (no +1 anymore)', () {
      final source = HttpDataTableSource<int>.django(
        baseUrl: 'https://example.com',
        endpoint: '/users/',
        fromJson: (json) => json['id'] as int,
      );

      final url = source.urlBuilder(const DataTableRequest(page: 7));
      expect(Uri.parse(url).queryParameters['page'], '7');
    });
  });
}
