import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_design/innovare_design.dart';

/// Tests for the Wave 4 empty/error states. We pump the actual
/// `InnovareDataTable` (not the private builders directly) so that
/// we also catch regressions in the routing logic between
/// `_buildContent`, `_buildEmpty` and `_buildError`.
void main() {
  Widget _withDesign(Widget child) {
    final theme = InnvPresets.resolve(InnvPreset.slate, Brightness.light);
    return MaterialApp(
      theme: theme.toThemeData(),
      home: Scaffold(body: child),
    );
  }

  Widget _bareMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  List<DataColumnConfig<_Row>> _columns() => [
        DataColumnConfig(
          field: 'name',
          label: 'Name',
          valueGetter: (r) => r.name,
        ),
      ];

  testWidgets('empty rows → InnvEmptyState when design system is '
      'installed', (tester) async {
    await tester.pumpWidget(_withDesign(
      InnovareDataTable<_Row>(
        rows: const [],
        columns: _columns(),
        emptyTitle: 'No orders yet',
        emptyMessage: 'Place one to see it here.',
        paginationEnabled: false,
        enableColumnResize: false,
        enableColumnDragDrop: false,
      ),
    ));
    await tester.pump();

    expect(find.byType(InnvEmptyState), findsOneWidget);
    expect(find.text('No orders yet'), findsOneWidget);
    expect(find.text('Place one to see it here.'), findsOneWidget);
  });

  testWidgets('empty rows → Material fallback (no InnvEmptyState) when '
      'design system is absent', (tester) async {
    await tester.pumpWidget(_bareMaterial(
      InnovareDataTable<_Row>(
        rows: const [],
        columns: _columns(),
        emptyTitle: 'Nada por aqui',
        paginationEnabled: false,
        enableColumnResize: false,
        enableColumnDragDrop: false,
      ),
    ));
    await tester.pump();

    expect(find.byType(InnvEmptyState), findsNothing);
    expect(find.text('Nada por aqui'), findsOneWidget);
  });

  testWidgets('errorMessage takes precedence over empty state when '
      'design system is installed', (tester) async {
    await tester.pumpWidget(_withDesign(
      InnovareDataTable<_Row>(
        rows: const [],
        columns: _columns(),
        errorMessage: 'Network is down',
        onErrorRetry: () {},
        paginationEnabled: false,
        enableColumnResize: false,
        enableColumnDragDrop: false,
      ),
    ));
    await tester.pump();

    expect(find.byType(InnvErrorState), findsOneWidget);
    expect(find.byType(InnvEmptyState), findsNothing,
        reason: 'error takes precedence — empty must not render too');
    expect(find.text('Network is down'), findsOneWidget);
  });

  testWidgets('errorMessage Material fallback (no InnvErrorState) when '
      'design system is absent', (tester) async {
    var retries = 0;
    await tester.pumpWidget(_bareMaterial(
      InnovareDataTable<_Row>(
        rows: const [],
        columns: _columns(),
        errorMessage: 'API exploded',
        onErrorRetry: () => retries++,
        paginationEnabled: false,
        enableColumnResize: false,
        enableColumnDragDrop: false,
      ),
    ));
    await tester.pump();

    expect(find.byType(InnvErrorState), findsNothing);
    expect(find.text('API exploded'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);

    await tester.tap(find.text('Tentar de novo'));
    expect(retries, 1);
  });

  testWidgets('non-empty rows render the table, not the empty state',
      (tester) async {
    await tester.pumpWidget(_withDesign(
      InnovareDataTable<_Row>(
        rows: const [_Row(name: 'Ada')],
        columns: _columns(),
        paginationEnabled: false,
        enableColumnResize: false,
        enableColumnDragDrop: false,
      ),
    ));
    await tester.pump();

    expect(find.byType(InnvEmptyState), findsNothing);
    expect(find.byType(InnvErrorState), findsNothing);
    expect(find.text('Ada'), findsOneWidget);
  });
}

class _Row {
  final String name;
  const _Row({required this.name});
}
