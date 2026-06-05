import 'package:flutter/material.dart';
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_design/innovare_design.dart';
import 'package:innovare_data_table_example/shell/app_shell.dart';
import 'package:innovare_data_table_example/shell/sample_employees.dart';

/// Wave 4 — Design system primitives in cells, plus the new empty/error
/// states. Three sub-pages cycled via a `SegmentedButton`:
///
/// 1. **Status badges** — `InnvColumns.badge` rendering tinted pills
///    that adapt to every preset + brightness automatically.
/// 2. **Row actions** — `InnvColumns.actions` with `isVisible`,
///    `isEnabled` and `danger` flags doing real work.
/// 3. **Empty / Error states** — toggle between "no rows", "API
///    error" and "loaded" to see the three branches.
class DsPrimitivesShowcase extends StatefulWidget {
  const DsPrimitivesShowcase({super.key});

  @override
  State<DsPrimitivesShowcase> createState() => _DsPrimitivesShowcaseState();
}

enum _Section { badges, actions, states }

class _DsPrimitivesShowcaseState extends State<DsPrimitivesShowcase> {
  _Section _section = _Section.badges;

  late List<Employee> _rows;
  _StateKind _stateKind = _StateKind.loaded;

  @override
  void initState() {
    super.initState();
    _rows = sampleEmployees(count: 18);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ShellHeader(
        title: 'Design system primitives',
        subtitle: 'Wave 4 — InnvBadge / InnvButton / InnvEmptyState / '
            'InnvErrorState inside the table',
      ),
      body: Padding(
        padding: const EdgeInsets.all(InnvSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SegmentedButton<_Section>(
                segments: const [
                  ButtonSegment(
                    value: _Section.badges,
                    icon: Icon(Icons.label_outline),
                    label: Text('Status badges'),
                  ),
                  ButtonSegment(
                    value: _Section.actions,
                    icon: Icon(Icons.bolt_outlined),
                    label: Text('Row actions'),
                  ),
                  ButtonSegment(
                    value: _Section.states,
                    icon: Icon(Icons.inbox_outlined),
                    label: Text('Empty / Error'),
                  ),
                ],
                selected: {_section},
                onSelectionChanged: (s) =>
                    setState(() => _section = s.first),
              ),
            ),
            const SizedBox(height: InnvSpacing.lg),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_section) {
      case _Section.badges:
        return _BadgeTable(rows: _rows);
      case _Section.actions:
        return _ActionsTable(
          rows: _rows,
          onUpdate: () => setState(() {
            _rows = List<Employee>.of(_rows);
          }),
        );
      case _Section.states:
        return _StatesTable(
          rows: _rows,
          state: _stateKind,
          onStateChanged: (k) => setState(() => _stateKind = k),
        );
    }
  }
}

class _BadgeTable extends StatelessWidget {
  final List<Employee> rows;
  const _BadgeTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return InnovareDataTable<Employee>(
      rows: rows,
      pageSize: 8,
      paginationEnabled: true,
      enableColumnResize: false,
      enableColumnDragDrop: false,
      columns: [
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
        ),
        InnvColumns.badge<Employee>(
          field: 'status',
          label: 'Status',
          sortable: true,
          labelOf: (e) => e.status.label,
          kindOf: (e) => switch (e.status) {
            EmployeeStatus.active => InnvStatusKind.success,
            EmployeeStatus.onLeave => InnvStatusKind.warning,
            EmployeeStatus.terminated => InnvStatusKind.danger,
          },
          iconOf: (e) => switch (e.status) {
            EmployeeStatus.active => Icons.check_circle_outline,
            EmployeeStatus.onLeave => Icons.access_time,
            EmployeeStatus.terminated => Icons.block,
          },
        ),
      ],
    );
  }
}

class _ActionsTable extends StatelessWidget {
  final List<Employee> rows;
  final VoidCallback onUpdate;

  const _ActionsTable({required this.rows, required this.onUpdate});

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InnovareDataTable<Employee>(
      rows: rows,
      pageSize: 8,
      paginationEnabled: true,
      enableColumnResize: false,
      enableColumnDragDrop: false,
      columns: [
        DataColumnConfig(
          field: 'id',
          label: '#',
          valueGetter: (e) => e.id,
          alignment: Alignment.centerRight,
        ),
        DataColumnConfig(
          field: 'name',
          label: 'Name',
          valueGetter: (e) => e.name,
        ),
        DataColumnConfig(
          field: 'role',
          label: 'Role',
          valueGetter: (e) => e.role,
        ),
        InnvColumns.actions<Employee>(
          actions: [
            InnvRowAction(
              icon: Icons.visibility_outlined,
              tooltip: 'View',
              onPressed: (e) => _toast(context, 'Viewing ${e.name}'),
            ),
            InnvRowAction(
              icon: Icons.archive_outlined,
              tooltip: 'Archive',
              // Disabled for terminated employees — they're already
              // out, no point archiving twice.
              isEnabled: (e) => e.status != EmployeeStatus.terminated,
              onPressed: (e) => _toast(context, 'Archived ${e.name}'),
            ),
            InnvRowAction(
              icon: Icons.delete_outline,
              tooltip: 'Delete',
              danger: true,
              // Hidden for currently active employees — only HR
              // exposes the delete affordance for off-boarded ones.
              isVisible: (e) => e.status != EmployeeStatus.active,
              onPressed: (e) => _toast(context, 'Deleted ${e.name}'),
            ),
          ],
        ),
      ],
    );
  }
}

enum _StateKind { loaded, empty, error }

class _StatesTable extends StatelessWidget {
  final List<Employee> rows;
  final _StateKind state;
  final ValueChanged<_StateKind> onStateChanged;

  const _StatesTable({
    required this.rows,
    required this.state,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: InnvSpacing.sm,
          children: [
            for (final k in _StateKind.values)
              ChoiceChip(
                label: Text(switch (k) {
                  _StateKind.loaded => 'Loaded',
                  _StateKind.empty => 'Empty',
                  _StateKind.error => 'Error',
                }),
                selected: state == k,
                onSelected: (_) => onStateChanged(k),
              ),
          ],
        ),
        const SizedBox(height: InnvSpacing.lg),
        Expanded(
          child: InnovareDataTable<Employee>(
            rows: state == _StateKind.loaded ? rows : const [],
            errorMessage: state == _StateKind.error
                ? 'Could not reach the employees service. The team is '
                    'aware — try again in a moment.'
                : null,
            onErrorRetry: state == _StateKind.error
                ? () => onStateChanged(_StateKind.loaded)
                : null,
            emptyTitle: 'No employees match',
            emptyMessage:
                'Try clearing the filters or expanding the search.',
            emptyIcon: Icons.person_search,
            pageSize: 8,
            paginationEnabled: true,
            enableColumnResize: false,
            enableColumnDragDrop: false,
            columns: [
              DataColumnConfig(
                field: 'name',
                label: 'Name',
                valueGetter: (e) => e.name,
              ),
              DataColumnConfig(
                field: 'role',
                label: 'Role',
                valueGetter: (e) => e.role,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
