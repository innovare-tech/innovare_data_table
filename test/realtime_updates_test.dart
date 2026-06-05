import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:innovare_data_table/innovare_data_table.dart';

/// Locks down the in-place realtime update path on `DataTableController`.
///
/// Previously every realtime event (`insert`/`update`/`delete`) triggered
/// a full HTTP refetch; the new path mutates `_currentResult` directly
/// when a `realtimeKeyExtractor` is provided, falling back to `refresh()`
/// for the legacy behaviour when it isn't.
void main() {
  group('DataTableController — realtime updates', () {
    late _FakeSource source;
    late DataTableController<_User> controller;

    setUp(() async {
      source = _FakeSource(
        initialData: List<_User>.generate(
          5,
          (i) => _User(id: i + 1, name: 'User ${i + 1}'),
        ),
      );
      controller = DataTableController<_User>(
        dataSource: source,
        realtimeKeyExtractor: (u) => u.id,
      );
      await controller.fetchData(const DataTableRequest(pageSize: 50));
      // Reset fetch counter after the initial load so each test asserts on
      // the realtime path alone.
      source.fetchCount = 0;
    });

    tearDown(() => controller.dispose());

    test('insert appends item and increments totalCount, no refetch',
        () async {
      source.emit(const DataTableUpdate<_User>(
        type: DataTableUpdateType.insert,
        item: _User(id: 99, name: 'New'),
      ));
      await _flush();

      expect(source.fetchCount, 0, reason: 'insert must be in-place');
      expect(controller.currentData.length, 6);
      expect(controller.currentData.last.id, 99);
      expect(controller.totalCount, 6);
    });

    test('insert with batch items appends all and increments totalCount',
        () async {
      source.emit(const DataTableUpdate<_User>(
        type: DataTableUpdateType.insert,
        items: [
          _User(id: 100, name: 'A'),
          _User(id: 101, name: 'B'),
          _User(id: 102, name: 'C'),
        ],
      ));
      await _flush();

      expect(source.fetchCount, 0);
      expect(controller.currentData.length, 8);
      expect(controller.totalCount, 8);
    });

    test('update replaces the matching row in place, no refetch', () async {
      source.emit(const DataTableUpdate<_User>(
        type: DataTableUpdateType.update,
        item: _User(id: 3, name: 'Updated User 3'),
      ));
      await _flush();

      expect(source.fetchCount, 0, reason: 'update must be in-place');
      final updated = controller.currentData.firstWhere((u) => u.id == 3);
      expect(updated.name, 'Updated User 3');
      expect(controller.totalCount, 5);
    });

    test('update for row not on the current page falls back to refresh',
        () async {
      source.emit(const DataTableUpdate<_User>(
        type: DataTableUpdateType.update,
        item: _User(id: 9999, name: 'Off-page'),
      ));
      await _flush();

      expect(source.fetchCount, 1,
          reason: 'unknown row must trigger a refresh');
    });

    test('delete by itemId removes the row and decrements totalCount, no '
        'refetch', () async {
      source.emit(const DataTableUpdate<_User>(
        type: DataTableUpdateType.delete,
        itemId: '2',
      ));
      await _flush();

      expect(source.fetchCount, 0);
      expect(controller.currentData.map((u) => u.id), isNot(contains(2)));
      expect(controller.currentData.length, 4);
      expect(controller.totalCount, 4);
    });

    test('delete by item key removes the row, no refetch', () async {
      source.emit(const DataTableUpdate<_User>(
        type: DataTableUpdateType.delete,
        item: _User(id: 4, name: 'whatever'),
      ));
      await _flush();

      expect(source.fetchCount, 0);
      expect(controller.currentData.map((u) => u.id), isNot(contains(4)));
      expect(controller.totalCount, 4);
    });

    test('delete for row not on current page falls back to refresh',
        () async {
      source.emit(const DataTableUpdate<_User>(
        type: DataTableUpdateType.delete,
        itemId: '9999',
      ));
      await _flush();

      expect(source.fetchCount, 1);
    });

    test('refresh event always re-fetches', () async {
      source.emit(const DataTableUpdate<_User>(
        type: DataTableUpdateType.refresh,
      ));
      await _flush();

      expect(source.fetchCount, 1);
    });

    test('notifyListeners fires on in-place mutations', () async {
      var notifications = 0;
      controller.addListener(() => notifications++);

      source.emit(const DataTableUpdate<_User>(
        type: DataTableUpdateType.insert,
        item: _User(id: 50, name: 'X'),
      ));
      await _flush();

      expect(notifications, greaterThanOrEqualTo(1));
    });
  });

  group('DataTableController — realtime fallback when no extractor', () {
    late _FakeSource source;
    late DataTableController<_User> controller;

    setUp(() async {
      source = _FakeSource(
        initialData: const [_User(id: 1, name: 'A'), _User(id: 2, name: 'B')],
      );
      // No realtimeKeyExtractor passed — must keep legacy refresh-on-every
      // -realtime-event behaviour.
      controller = DataTableController<_User>(dataSource: source);
      await controller.fetchData();
      source.fetchCount = 0;
    });

    tearDown(() => controller.dispose());

    test('update without extractor falls back to refresh', () async {
      source.emit(const DataTableUpdate<_User>(
        type: DataTableUpdateType.update,
        item: _User(id: 1, name: 'Renamed'),
      ));
      await _flush();
      expect(source.fetchCount, 1);
    });

    test('delete without extractor falls back to refresh', () async {
      source.emit(const DataTableUpdate<_User>(
        type: DataTableUpdateType.delete,
        itemId: '1',
      ));
      await _flush();
      expect(source.fetchCount, 1);
    });

    test('insert without extractor still applies in place (no key needed)',
        () async {
      source.emit(const DataTableUpdate<_User>(
        type: DataTableUpdateType.insert,
        item: _User(id: 9, name: 'New'),
      ));
      await _flush();

      expect(source.fetchCount, 0,
          reason: 'insert does not need a key extractor');
      expect(controller.currentData.length, 3);
      expect(controller.totalCount, 3);
    });
  });
}

/// Flushes microtasks so listeners on the source stream run before assertions.
Future<void> _flush() => Future<void>.delayed(Duration.zero);

class _User {
  final int id;
  final String name;
  const _User({required this.id, required this.name});
}

class _FakeSource extends DataTableSource<_User> {
  _FakeSource({required List<_User> initialData}) : _data = List.of(initialData);

  List<_User> _data;
  final StreamController<DataTableUpdate<_User>> _updates =
      StreamController<DataTableUpdate<_User>>.broadcast();
  int fetchCount = 0;

  @override
  Future<DataTableResult<_User>> fetch(DataTableRequest request) async {
    fetchCount++;
    return DataTableResult<_User>(
      data: List.of(_data),
      totalCount: _data.length,
      page: request.page,
      pageSize: request.pageSize,
    );
  }

  @override
  Stream<DataTableUpdate<_User>>? get updates => _updates.stream;

  void emit(DataTableUpdate<_User> update) => _updates.add(update);

  @override
  void dispose() {
    _updates.close();
    super.dispose();
  }
}
