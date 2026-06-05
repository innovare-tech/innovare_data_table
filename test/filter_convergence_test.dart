// ignore_for_file: deprecated_member_use_from_same_package
//
// Wave 3.3 — Filter convergence pin tests.
//
// 1. Confirms that the unified-filter primitives the package now
//    declares "canonical" are importable from the public barrel
//    (`package:innovare_data_table/innovare_data_table.dart`).
// 2. Confirms that the deprecated top-level filter props
//    (`columnFilters`, `advancedFilters`) keep producing a working
//    widget — regression net so we can't accidentally break trunk
//    apps before v0.2.0.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innovare_data_table/innovare_data_table.dart';

void main() {
  group('Canonical filter primitives are exported', () {
    test('UnifiedFilter / UnifiedFilterType / UnifiedFiltersConfig / '
        'FilterState / FilterPreset / UnifiedFiltersController are '
        'reachable from the barrel', () {
      // Just touching the types is enough — if any of them were not
      // exported, this file would not compile.
      const filter = UnifiedFilter<String>(
        id: 'demo',
        field: 'name',
        label: 'Demo',
        value: 'foo',
      );
      expect(filter.type, UnifiedFilterType.quick);
      expect(filter.category, FilterCategory.text);

      final cfg = UnifiedFiltersConfig<String>.simple();
      expect(cfg.enableQuickFilters, isFalse);

      final state = FilterState<String>(activeFilters: [filter]);
      expect(state.hasActiveFilters, isTrue);
      expect(state.totalFiltersCount, 1);

      final preset = FilterPreset<String>(
        id: 'p1',
        name: 'Demo preset',
        filters: const [filter],
        createdAt: DateTime(2026, 1, 1),
      );
      expect(preset.filters, hasLength(1));

      final controller = UnifiedFiltersController<String>(config: cfg);
      expect(controller.state.activeFilters, isEmpty);
      controller.dispose();
    });

    test('UnifiedFilter.fromQuickFilter / fromAdvancedFilter / search '
        'factory constructors preserve the source label', () {
      final q = QuickFilter<String>(
        id: 'active',
        label: 'Active',
        field: 'status',
        value: 'active',
      );
      final u = UnifiedFilter<String>.fromQuickFilter(q);
      expect(u.type, UnifiedFilterType.quick);
      expect(u.label, 'Active');
      expect(u.field, 'status');
      expect(u.value, 'active');

      final adv = ActiveFilter(
        field: 'name',
        operator: FilterOperator.contains,
        value: 'foo',
      );
      final u2 = UnifiedFilter<String>.fromAdvancedFilter(adv, 'Name');
      expect(u2.type, UnifiedFilterType.advanced);
      expect(u2.label, 'Name');

      final u3 = UnifiedFilter<String>.search('hello');
      expect(u3.type, UnifiedFilterType.search);
      expect(u3.value, 'hello');
    });
  });

  group('Deprecated top-level filter props still render', () {
    testWidgets('columnFilters (deprecated) keeps mounting the widget '
        'without crashing', (tester) async {
      // The annotation is suppressed by the file-level ignore — we
      // want to use the deprecated prop on purpose to pin the
      // regression net.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: InnovareDataTable<_Row>(
            rows: const [_Row(name: 'Ada')],
            columns: [
              DataColumnConfig(
                field: 'name',
                label: 'Name',
                valueGetter: (r) => r.name,
              ),
            ],
            columnFilters: const [
              ColumnFilterOption<_Row>(
                field: 'name',
                label: 'Name',
                type: SimpleFilterType.text,
              ),
            ],
            paginationEnabled: false,
            enableColumnResize: false,
            enableColumnDragDrop: false,
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('Ada'), findsOneWidget);
    });

    testWidgets('advancedFilters (deprecated) keeps mounting the widget '
        'without crashing', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: InnovareDataTable<_Row>(
            rows: const [_Row(name: 'Ada')],
            columns: [
              DataColumnConfig(
                field: 'name',
                label: 'Name',
                valueGetter: (r) => r.name,
              ),
            ],
            advancedFilters: [
              AdvancedFilterConfig<_Row>(
                field: 'name',
                label: 'Name',
                type: SimpleFilterType.text,
              ),
            ],
            paginationEnabled: false,
            enableColumnResize: false,
            enableColumnDragDrop: false,
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('Ada'), findsOneWidget);
    });
  });
}

class _Row {
  final String name;
  const _Row({required this.name});
}
