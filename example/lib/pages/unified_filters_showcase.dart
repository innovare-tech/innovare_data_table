import 'package:flutter/material.dart';
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_design/innovare_design.dart';
import 'package:innovare_data_table_example/shell/app_shell.dart';
import 'package:innovare_data_table_example/shell/sample_employees.dart';

/// Live demo for Wave 3.3 — Filter convergence.
///
/// The page wires a single [UnifiedFiltersController] to four
/// **different** UX surfaces at once and shows the resulting state in
/// a side panel:
///
/// 1. **Quick filters** (chips) for status presets.
/// 2. **Advanced filters** (multi-condition dialog) for department.
/// 3. **Search** (global text) over name + role.
/// 4. **A filtered [InnovareDataTable]** that re-reads
///    `controller.applyFiltersToLocalData(rows)` on every state tick.
///
/// The right-hand panel mirrors `controller.state.activeFilters`
/// expressed as `UnifiedFilter<T>`, so it is obvious that the
/// convergence happens at the **data model** layer — every surface
/// produces the same shape, and a single controller is the source of
/// truth.
class UnifiedFiltersShowcase extends StatefulWidget {
  const UnifiedFiltersShowcase({super.key});

  @override
  State<UnifiedFiltersShowcase> createState() =>
      _UnifiedFiltersShowcaseState();
}

class _UnifiedFiltersShowcaseState extends State<UnifiedFiltersShowcase> {
  late final List<Employee> _rows;
  late final UnifiedFiltersController<Employee> _controller;

  @override
  void initState() {
    super.initState();
    _rows = sampleEmployees(count: 60);

    _controller = UnifiedFiltersController<Employee>(
      config: UnifiedFiltersConfig<Employee>.full(
        quickFilters: const [
          QuickFiltersConfig<Employee>(
            filters: [
              QuickFilter(
                id: 'active',
                label: 'Active',
                field: 'status',
                value: 'Active',
                icon: Icons.check_circle_outline,
              ),
              QuickFilter(
                id: 'on_leave',
                label: 'On leave',
                field: 'status',
                value: 'On leave',
                icon: Icons.pause_circle_outline,
              ),
              QuickFilter(
                id: 'terminated',
                label: 'Terminated',
                field: 'status',
                value: 'Terminated',
                icon: Icons.cancel_outlined,
              ),
            ],
          ),
        ],
        advancedFilters: [
          AdvancedFilterConfig<Employee>(
            field: 'department',
            label: 'Department',
            type: SimpleFilterType.text,
          ),
          AdvancedFilterConfig<Employee>(
            field: 'role',
            label: 'Role',
            type: SimpleFilterType.text,
          ),
          AdvancedFilterConfig<Employee>(
            field: 'yearsAtCompany',
            label: 'Years at company',
            type: SimpleFilterType.number,
          ),
        ],
        searchFields: const ['name', 'role'],
        fieldGetter: _byField,
      ),
    );

    _controller.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    _controller.dispose();
    super.dispose();
  }

  static String _byField(Employee e, String field) {
    switch (field) {
      case 'name':
        return e.name;
      case 'role':
        return e.role;
      case 'department':
        return e.department;
      case 'status':
        return e.status.label;
      case 'yearsAtCompany':
        return e.yearsAtCompany.toString();
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleRows = _controller.applyFiltersToLocalData(_rows);
    return Scaffold(
      appBar: const ShellHeader(
        title: 'Unified filters',
        subtitle: 'Wave 3.3 — one controller drives chips, advanced '
            'dialog and search at once.',
      ),
      body: Padding(
        padding: const EdgeInsets.all(InnvSpacing.lg),
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 1100;
            final table = _buildBarAndTable(visibleRows);
            final panel = _ActiveFiltersPanel(controller: _controller);
            if (!wide) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 560, child: table),
                    const SizedBox(height: InnvSpacing.lg),
                    SizedBox(height: 360, child: panel),
                  ],
                ),
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: table),
                const SizedBox(width: InnvSpacing.lg),
                Expanded(child: panel),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBarAndTable(List<Employee> visibleRows) {
    final colors = DataTableColorScheme.fromTheme(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The shared bar — quick chips + advanced dialog + search box.
        UnifiedFiltersBar<Employee>(
          controller: _controller,
          data: _rows,
          colors: colors,
        ),
        const SizedBox(height: InnvSpacing.md),
        Expanded(
          child: InnovareDataTable<Employee>(
            rows: visibleRows,
            columns: _buildColumns(),
            pageSize: 12,
            paginationEnabled: true,
            enableColumnResize: false,
            enableColumnDragDrop: false,
            emptyTitle: 'No matches',
            emptyMessage:
                'No employee in the seed dataset satisfies every '
                'active filter. Try removing one of the chips on top, '
                'or clear the search box.',
            emptyAction: TextButton.icon(
              onPressed: _controller.clearAllFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Clear all filters'),
            ),
          ),
        ),
      ],
    );
  }

  List<DataColumnConfig<Employee>> _buildColumns() {
    return <DataColumnConfig<Employee>>[
      DataColumnConfig(
        field: 'name',
        label: 'Name',
        valueGetter: (e) => e.name,
        sortable: true,
      ),
      DataColumnConfig(
        field: 'role',
        label: 'Role',
        valueGetter: (e) => e.role,
        sortable: true,
      ),
      DataColumnConfig(
        field: 'department',
        label: 'Department',
        valueGetter: (e) => e.department,
        sortable: true,
      ),
      DataColumnConfig(
        field: 'yearsAtCompany',
        label: 'Years',
        valueGetter: (e) => e.yearsAtCompany,
        sortable: true,
        alignment: Alignment.centerRight,
      ),
      InnvColumns.badge<Employee>(
        field: 'status',
        label: 'Status',
        labelOf: (e) => e.status.label,
        kindOf: (e) => switch (e.status) {
          EmployeeStatus.active => InnvStatusKind.success,
          EmployeeStatus.onLeave => InnvStatusKind.warning,
          EmployeeStatus.terminated => InnvStatusKind.danger,
        },
      ),
    ];
  }
}

class _ActiveFiltersPanel extends StatelessWidget {
  final UnifiedFiltersController<Employee> controller;
  const _ActiveFiltersPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = controller.state.activeFilters;
    final search = controller.searchTerm ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(InnvSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'controller.state',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: controller.clearAllFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: InnvSpacing.xs),
            Text(
              'Every chip, every dialog field and the search box write '
              'to this single state. Convergence happens here, not in '
              'the widgets above.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: InnvSpacing.xl),
            _kv(theme, 'searchTerm', search.isEmpty ? '∅' : '"$search"'),
            _kv(theme, 'activeFilters.length', '${filters.length}'),
            _kv(theme, 'hasActiveFilters',
                controller.state.hasActiveFilters.toString()),
            const SizedBox(height: InnvSpacing.md),
            Text(
              'activeFilters',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: InnvSpacing.xs),
            Expanded(
              child: filters.isEmpty
                  ? _emptyHint(theme)
                  : ListView.separated(
                      itemCount: filters.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: InnvSpacing.xs),
                      itemBuilder: (_, i) => _FilterChipRow(
                        filter: filters[i],
                        onRemove: () => controller.removeFilter(filters[i].id),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(ThemeData theme, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              k,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(ThemeData theme) {
    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        'No active filters yet.\nClick a chip, type in the search box, '
        'or open the advanced dialog.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  final UnifiedFilter<Employee> filter;
  final VoidCallback onRemove;
  const _FilterChipRow({required this.filter, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeLabel = switch (filter.type) {
      UnifiedFilterType.quick => 'quick',
      UnifiedFilterType.advanced => 'advanced',
      UnifiedFilterType.column => 'column',
      UnifiedFilterType.search => 'search',
      UnifiedFilterType.dateRange => 'dateRange',
      UnifiedFilterType.multiSelect => 'multiSelect',
    };
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: InnvSpacing.md,
          vertical: InnvSpacing.xs,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                typeLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: InnvSpacing.md),
            Expanded(
              child: Text(
                filter.displayText,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'Remove this filter',
              icon: const Icon(Icons.close, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: 24,
                height: 24,
              ),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
