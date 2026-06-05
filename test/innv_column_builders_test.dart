import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_design/innovare_design.dart';

/// Tests for the Wave 4 column builders: `InnvColumns.badge`,
/// `InnvColumns.actions`, and the new `InnvRowAction` flags
/// (`isVisible`, `isEnabled`, `danger`).
///
/// Each widget test wraps the column's cell in a minimal `InnvDesign
/// Theme`-installed scaffold so the design-system primitives can read
/// from `context.innv`.
void main() {
  Widget _wrap(Widget child) {
    final design = InnvPresets.resolve(InnvPreset.aurora, Brightness.light);
    return MaterialApp(
      theme: design.toThemeData(),
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('InnvColumns.badge', () {
    final col = InnvColumns.badge<_Order>(
      field: 'status',
      label: 'Status',
      labelOf: (o) => o.statusLabel,
      kindOf: (o) => o.kind,
    );

    test('valueGetter mirrors labelOf so sort/filter use the display '
        'text without extra wiring', () {
      final paid = _Order(id: 1, kind: InnvStatusKind.success, statusLabel: 'Paid');
      final pending =
          _Order(id: 2, kind: InnvStatusKind.warning, statusLabel: 'Pending');
      expect(col.valueGetter(paid), 'Paid');
      expect(col.valueGetter(pending), 'Pending');
    });

    test('column metadata: not sortable/filterable by default, label '
        'and field preserved', () {
      expect(col.field, 'status');
      expect(col.label, 'Status');
      expect(col.sortable, isFalse);
      expect(col.filterable, isFalse);
    });

    testWidgets('cellBuilder renders an InnvBadge with the resolved '
        'label and kind', (tester) async {
      final paid = _Order(id: 1, kind: InnvStatusKind.success, statusLabel: 'Paid');
      await tester.pumpWidget(_wrap(col.cellBuilder!(paid)));
      expect(find.text('Paid'), findsOneWidget);
      expect(find.byType(InnvBadge), findsOneWidget);

      final badge = tester.widget<InnvBadge>(find.byType(InnvBadge));
      expect(badge.kind, InnvStatusKind.success);
      expect(badge.dense, isTrue,
          reason: 'badge columns default to dense for row density');
    });
  });

  group('InnvColumns.actions', () {
    testWidgets('renders one IconButton per visible action', (tester) async {
      final col = InnvColumns.actions<_Order>(
        actions: [
          InnvRowAction(
            icon: Icons.edit,
            tooltip: 'Edit',
            onPressed: (_) {},
          ),
          InnvRowAction(
            icon: Icons.delete,
            tooltip: 'Delete',
            danger: true,
            onPressed: (_) {},
          ),
        ],
      );
      final item = _Order(id: 7, kind: InnvStatusKind.neutral, statusLabel: '');
      await tester.pumpWidget(_wrap(col.cellBuilder!(item)));
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('isVisible(item) == false hides the action entirely',
        (tester) async {
      final col = InnvColumns.actions<_Order>(
        actions: [
          InnvRowAction(
            icon: Icons.edit,
            tooltip: 'Edit',
            onPressed: (_) {},
            isVisible: (o) => o.id != 99,
          ),
        ],
      );
      final hidden = _Order(id: 99, kind: InnvStatusKind.neutral, statusLabel: '');
      await tester.pumpWidget(_wrap(col.cellBuilder!(hidden)));
      expect(find.byIcon(Icons.edit), findsNothing);
    });

    testWidgets('isEnabled(item) == false disables the IconButton',
        (tester) async {
      final col = InnvColumns.actions<_Order>(
        actions: [
          InnvRowAction(
            icon: Icons.archive,
            tooltip: 'Archive',
            onPressed: (_) {},
            isEnabled: (o) => o.id.isEven,
          ),
        ],
      );
      final oddItem = _Order(id: 3, kind: InnvStatusKind.neutral, statusLabel: '');
      await tester.pumpWidget(_wrap(col.cellBuilder!(oddItem)));
      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.onPressed, isNull,
          reason: 'odd id must disable the icon button');
    });

    test('default resize config locks the column to a fixed width '
        'proportional to the number of actions', () {
      final col = InnvColumns.actions<_Order>(
        actions: [
          for (var i = 0; i < 3; i++)
            InnvRowAction(
              icon: Icons.edit,
              tooltip: 'Edit',
              onPressed: (_) {},
            ),
        ],
      );
      expect(col.resizeConfig?.resizable, isFalse);
      expect(col.resizeConfig?.initialWidth, 36.0 + 3 * 44.0);
    });
  });
}

class _Order {
  final int id;
  final InnvStatusKind kind;
  final String statusLabel;
  _Order({required this.id, required this.kind, required this.statusLabel});
}
