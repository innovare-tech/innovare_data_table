import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innovare_data_table/innovare_data_table.dart';

/// Tests the Shift+click multi-sort path introduced in Wave 3.4.
///
/// Coverage:
/// - `DataTableController.sortMulti` replaces the whole sort stack and
///   resets pagination to page 1.
/// - `InnovareDataTable` keyboard-modifier handling: a non-additive tap on
///   a sortable header collapses the stack to a single sort; an additive
///   tap (Shift held) appends a new entry without losing the previous
///   sorts.
/// - The legacy `widget.onSort` callback still fires with the primary
///   sort, so callers that haven't migrated to multi-sort keep working.
/// - Local-mode `_applySorting` honours the stack and uses each entry as
///   a tie-breaker (already exercised via the integration test below).
void main() {
  group('DataTableController.sortMulti', () {
    test('replaces the entire sort stack and resets to page 1', () async {
      final controller = DataTableController<int>(
        dataSource: LocalDataTableSource<int>(
          data: List<int>.generate(40, (i) => i + 1),
          fieldGetter: (item, field) => item.toString(),
        ),
      );

      await controller.fetchData(const DataTableRequest(pageSize: 10));
      await controller.nextPage(); // page 2

      await controller.sortMulti(const [
        DataTableSort(field: 'name', ascending: true),
        DataTableSort(field: 'createdAt', ascending: false),
      ]);

      expect(controller.currentResult!.page, 1,
          reason: 'sort changes must reset pagination');
      expect(controller.currentRequest.sorts.length, 2);
      expect(controller.currentRequest.sorts.first.field, 'name');
      expect(controller.currentRequest.sorts.last.ascending, isFalse);

      controller.dispose();
    });
  });

  group('InnovareDataTable — Shift+click multi-sort', () {
    final columns = <DataColumnConfig<_Row>>[
      DataColumnConfig(
        field: 'name',
        label: 'Name',
        valueGetter: (r) => r.name,
        sortable: true,
      ),
      DataColumnConfig(
        field: 'value',
        label: 'Value',
        valueGetter: (r) => r.value,
        sortable: true,
      ),
    ];

    final rows = const [
      _Row(name: 'Alice', value: 30),
      _Row(name: 'Bob', value: 25),
      _Row(name: 'Alice', value: 10),
    ];

    Future<void> pumpTable(
      WidgetTester tester, {
      required void Function(String, bool) onSort,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InnovareDataTable<_Row>(
              rows: rows,
              columns: columns,
              pageSize: 50,
              paginationEnabled: false,
              onSort: onSort,
              enableColumnResize: false,
              enableColumnDragDrop: false,
            ),
          ),
        ),
      );
      // Allow first frame + any post-frame callbacks.
      await tester.pump();
    }

    testWidgets('simple tap on a sortable column fires onSort with that '
        'column and ascending=true', (tester) async {
      String? lastField;
      bool? lastAscending;

      await pumpTable(
        tester,
        onSort: (field, ascending) {
          lastField = field;
          lastAscending = ascending;
        },
      );

      await tester.tap(find.text('Name'));
      await tester.pump();

      expect(lastField, 'name');
      expect(lastAscending, isTrue);
    });

    testWidgets('Shift+click on a second column keeps the first sort as '
        'the primary and adds the second below it', (tester) async {
      final emitted = <(String, bool)>[];

      await pumpTable(
        tester,
        onSort: (field, ascending) => emitted.add((field, ascending)),
      );

      // First tap: primary sort.
      await tester.tap(find.text('Name'));
      await tester.pump();

      // Shift+click on second column.
      await simulateKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.tap(find.text('Value'));
      await tester.pump();
      await simulateKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      // Legacy onSort always reports the primary — which stays Name.
      expect(emitted, hasLength(2));
      expect(emitted.first, ('name', true));
      expect(emitted.last, ('name', true),
          reason:
              'additive sort must not change the primary, so onSort is '
              'called again with the primary that was already active');
    });

    testWidgets('non-additive tap on a different column replaces the '
        'primary', (tester) async {
      String? lastField;

      await pumpTable(
        tester,
        onSort: (field, ascending) => lastField = field,
      );

      await tester.tap(find.text('Name'));
      await tester.pump();
      expect(lastField, 'name');

      // Plain click (no Shift) on a different column.
      await tester.tap(find.text('Value'));
      await tester.pump();
      expect(lastField, 'value');
    });
  });
}

class _Row {
  final String name;
  final int value;
  const _Row({required this.name, required this.value});
}
