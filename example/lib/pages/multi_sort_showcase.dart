import 'package:flutter/material.dart';
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_design/innovare_design.dart';
import 'package:innovare_data_table_example/shell/app_shell.dart';
import 'package:innovare_data_table_example/shell/sample_employees.dart';

/// Live demo for Wave 3.4 — Shift+click multi-column sort.
///
/// The page is intentionally narrow so the user's full attention is on
/// the table header: try clicking columns and try Shift+clicking to see
/// the priority badge appear. The right-hand side panel mirrors the
/// current `_activeSorts` stack so the cause/effect relationship is
/// obvious without opening the inspector.
class MultiSortShowcase extends StatefulWidget {
  const MultiSortShowcase({super.key});

  @override
  State<MultiSortShowcase> createState() => _MultiSortShowcaseState();
}

class _MultiSortShowcaseState extends State<MultiSortShowcase> {
  late final List<Employee> _rows;

  /// Mirror of the table's `_activeSorts` stack, fed directly by the
  /// `onSortsChanged` callback shipped in Wave 3.4. We don't have to
  /// duplicate the Shift+click logic — the widget already does it.
  List<DataTableSort> _sorts = const [];

  @override
  void initState() {
    super.initState();
    _rows = sampleEmployees(count: 24);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ShellHeader(
        title: 'Multi-column sort',
        subtitle:
            'Wave 3.4 — Shift+click a sortable column to add it to the '
            'sort stack. The numeric badge shows its priority.',
      ),
      body: Padding(
        padding: const EdgeInsets.all(InnvSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: _buildTable(),
            ),
            const SizedBox(width: InnvSpacing.lg),
            Expanded(child: _SortStackPanel(sorts: _sorts)),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    final columns = <DataColumnConfig<Employee>>[
      DataColumnConfig(
        field: 'name',
        label: 'Name',
        valueGetter: (e) => e.name,
        sortable: true,
      ),
      DataColumnConfig(
        field: 'department',
        label: 'Department',
        valueGetter: (e) => e.department,
        sortable: true,
      ),
      DataColumnConfig(
        field: 'role',
        label: 'Role',
        valueGetter: (e) => e.role,
        sortable: true,
      ),
      DataColumnConfig(
        field: 'yearsAtCompany',
        label: 'Years',
        valueGetter: (e) => e.yearsAtCompany,
        sortable: true,
        alignment: Alignment.centerRight,
      ),
      DataColumnConfig(
        field: 'rating',
        label: 'Rating',
        valueGetter: (e) => e.rating,
        sortable: true,
        alignment: Alignment.centerRight,
        cellBuilder: (e) => Text(e.rating.toStringAsFixed(2)),
      ),
    ];

    return InnovareDataTable<Employee>(
      rows: _rows,
      columns: columns,
      pageSize: 8,
      paginationEnabled: true,
      enableColumnResize: false,
      enableColumnDragDrop: false,
      onSortsChanged: (sorts) => setState(() => _sorts = sorts),
    );
  }
}

class _SortStackPanel extends StatelessWidget {
  final List<DataTableSort> sorts;
  const _SortStackPanel({required this.sorts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(InnvSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active sort stack', style: theme.textTheme.titleMedium),
            const SizedBox(height: InnvSpacing.xs),
            Text(
              'The first row is the primary sort. Each row below it is '
              'a tie-breaker.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: InnvSpacing.xl),
            if (sorts.isEmpty)
              Text(
                'No sort applied yet — click a column header.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (var i = 0; i < sorts.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: InnvSpacing.md),
                      Expanded(
                        child: Text(
                          sorts[i].field,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Icon(
                        sorts[i].ascending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                      ),
                    ],
                  ),
                ),
            const Spacer(),
            Text(
              'Tip: hold ⇧ Shift while clicking another column to '
              'append it as a tie-breaker.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
