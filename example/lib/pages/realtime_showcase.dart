import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_design/innovare_design.dart';
import 'package:innovare_data_table_example/shell/app_shell.dart';
import 'package:innovare_data_table_example/shell/sample_employees.dart';

/// Live demo for Wave 3.2 — in-place realtime updates.
///
/// Three buttons emit synthetic `DataTableUpdate` events on a
/// `StreamingEmployeeSource`. The table is wired up with the matching
/// `realtimeKeyExtractor`, so the controller mutates the current page
/// in place instead of refetching the whole dataset. We also count
/// every `fetch()` so the user can see that "Update first row" stays
/// at 1 fetch — the row mutates without a server roundtrip.
class RealtimeShowcase extends StatefulWidget {
  const RealtimeShowcase({super.key});

  @override
  State<RealtimeShowcase> createState() => _RealtimeShowcaseState();
}

class _RealtimeShowcaseState extends State<RealtimeShowcase> {
  late final StreamingEmployeeSource _source;
  late final DataTableController<Employee> _controller;

  @override
  void initState() {
    super.initState();
    _source = StreamingEmployeeSource(sampleEmployees(count: 30));
    _controller = DataTableController<Employee>(
      dataSource: _source,
      realtimeKeyExtractor: (e) => e.id,
    );
    // Bump the UI when fetches / mutations land.
    _controller.addListener(() => setState(() {}));
    _source.fetchCountListenable.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ShellHeader(
        title: 'Realtime updates (in-place)',
        subtitle:
            'Wave 3.2 — insert / update / delete mutate the current page '
            'directly. No refetch unless the row is off-page.',
      ),
      body: Padding(
        padding: const EdgeInsets.all(InnvSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ActionsBar(
              fetchCount: _source.fetchCount,
              onInsert: _insertOne,
              onUpdate: _updateFirst,
              onDelete: _deleteFirst,
              onReset: _reset,
            ),
            const SizedBox(height: InnvSpacing.lg),
            Expanded(child: _buildTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    final columns = <DataColumnConfig<Employee>>[
      DataColumnConfig(
        field: 'id',
        label: '#',
        valueGetter: (e) => e.id,
        sortable: true,
        alignment: Alignment.centerRight,
      ),
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
      ),
      DataColumnConfig(
        field: 'rating',
        label: 'Rating',
        valueGetter: (e) => e.rating.toStringAsFixed(2),
        alignment: Alignment.centerRight,
      ),
    ];

    return InnovareDataTable<Employee>.withDataSource(
      columns: columns,
      dataSource: _source,
      controller: _controller,
      pageSize: 8,
      enableColumnResize: false,
      enableColumnDragDrop: false,
    );
  }

  void _insertOne() {
    final next = _source.nextSyntheticEmployee();
    _source.push(DataTableUpdate<Employee>(
      type: DataTableUpdateType.insert,
      item: next,
    ));
  }

  void _updateFirst() {
    final current = _controller.currentData.firstOrNull;
    if (current == null) return;
    final updated = current.copyWith(
      rating: ((current.rating + 0.5) % 5.0).clamp(0.0, 5.0),
      name: '${current.name} ⚡',
    );
    _source.push(DataTableUpdate<Employee>(
      type: DataTableUpdateType.update,
      item: updated,
    ));
  }

  void _deleteFirst() {
    final current = _controller.currentData.firstOrNull;
    if (current == null) return;
    _source.push(DataTableUpdate<Employee>(
      type: DataTableUpdateType.delete,
      itemId: current.id.toString(),
    ));
  }

  void _reset() {
    _source.reset(sampleEmployees(count: 30));
    _controller.refresh();
  }
}

class _ActionsBar extends StatelessWidget {
  final int fetchCount;
  final VoidCallback onInsert;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onReset;

  const _ActionsBar({
    required this.fetchCount,
    required this.onInsert,
    required this.onUpdate,
    required this.onDelete,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: InnvSpacing.lg,
          vertical: InnvSpacing.md,
        ),
        child: Row(
          children: [
            FilledButton.icon(
              onPressed: onInsert,
              icon: const Icon(Icons.add),
              label: const Text('Insert row'),
            ),
            const SizedBox(width: InnvSpacing.sm),
            FilledButton.tonalIcon(
              onPressed: onUpdate,
              icon: const Icon(Icons.bolt),
              label: const Text('Update first row'),
            ),
            const SizedBox(width: InnvSpacing.sm),
            OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete first row'),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: InnvSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'fetch() calls: $fetchCount',
                style: theme.textTheme.labelMedium,
              ),
            ),
            const SizedBox(width: InnvSpacing.sm),
            TextButton(
              onPressed: onReset,
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Drop-in subclass of [LocalDataTableSource] that also exposes an
/// `updates` stream and counts the number of `fetch()` calls. The
/// extension is intentionally minimal — every actual filtering /
/// sorting / paging concern is delegated to the parent class.
class StreamingEmployeeSource extends LocalDataTableSource<Employee> {
  final _streamController = StreamController<DataTableUpdate<Employee>>
      .broadcast();
  final List<Employee> _ownedData;
  final ValueNotifier<int> _fetchCount = ValueNotifier<int>(0);
  int _nextId;

  StreamingEmployeeSource(List<Employee> data)
      : _ownedData = List<Employee>.of(data),
        _nextId = (data.isEmpty
                ? 0
                : data.map((e) => e.id).reduce((a, b) => a > b ? a : b)) +
            1,
        super(data: data, fieldGetter: _searchField);

  static String _searchField(Employee e, String field) {
    switch (field) {
      case 'search':
        return '${e.id} ${e.name} ${e.role} ${e.department}';
      case 'id':
        return e.id.toString();
      case 'name':
        return e.name;
      case 'role':
        return e.role;
      case 'rating':
        return e.rating.toStringAsFixed(2);
      default:
        return '';
    }
  }

  int get fetchCount => _fetchCount.value;
  ValueListenable<int> get fetchCountListenable => _fetchCount;

  @override
  Stream<DataTableUpdate<Employee>>? get updates => _streamController.stream;

  @override
  Future<DataTableResult<Employee>> fetch(DataTableRequest request) async {
    _fetchCount.value = _fetchCount.value + 1;
    return super.fetch(request);
  }

  void push(DataTableUpdate<Employee> update) {
    // Keep the backing list in sync so a later refresh / reset reflects
    // the realtime mutations.
    switch (update.type) {
      case DataTableUpdateType.insert:
        if (update.item != null) _ownedData.insert(0, update.item!);
        if (update.items != null) _ownedData.insertAll(0, update.items!);
        break;
      case DataTableUpdateType.update:
        if (update.item != null) {
          final idx = _ownedData.indexWhere((e) => e.id == update.item!.id);
          if (idx >= 0) _ownedData[idx] = update.item!;
        }
        break;
      case DataTableUpdateType.delete:
        if (update.itemId != null) {
          _ownedData.removeWhere((e) => e.id.toString() == update.itemId);
        }
        break;
      case DataTableUpdateType.refresh:
        break;
    }
    _streamController.add(update);
  }

  Employee nextSyntheticEmployee() {
    final id = _nextId++;
    return Employee(
      id: id,
      name: 'New Hire #$id',
      role: 'Engineer',
      department: 'Platform',
      yearsAtCompany: 0,
      rating: 3.5,
      status: EmployeeStatus.active,
    );
  }

  void reset(List<Employee> data) {
    _ownedData
      ..clear()
      ..addAll(data);
    _nextId = data.isEmpty
        ? 1
        : data.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    _fetchCount.value = 0;
  }

  @override
  void dispose() {
    _streamController.close();
    _fetchCount.dispose();
    super.dispose();
  }
}
