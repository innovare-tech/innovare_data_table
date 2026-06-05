import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_design/innovare_design.dart';
import 'package:innovare_data_table_example/shell/app_shell.dart';
import 'package:innovare_data_table_example/shell/sample_employees.dart';

/// Live demo for Wave 3.5 — selective cache invalidation.
///
/// Uses a fake `http.Client` so we can both (a) count requests and (b)
/// show the user every entry currently in the source's in-memory
/// cache. Two "Invalidate" buttons illustrate the two modes:
///
/// - `invalidateCache()` wipes everything (legacy behaviour).
/// - `invalidateCache(where: ...)` drops only the entries whose
///   `DataTableRequest` matches the predicate — in this demo, only
///   the page currently being viewed.
class CacheInvalidationShowcase extends StatefulWidget {
  const CacheInvalidationShowcase({super.key});

  @override
  State<CacheInvalidationShowcase> createState() =>
      _CacheInvalidationShowcaseState();
}

class _CacheInvalidationShowcaseState
    extends State<CacheInvalidationShowcase> {
  late final _CountingFakeClient _client;
  late final HttpDataTableSource<Employee> _source;
  late final DataTableController<Employee> _controller;

  @override
  void initState() {
    super.initState();
    _client = _CountingFakeClient(sampleEmployees(count: 60));
    _source = HttpDataTableSource<Employee>(
      urlBuilder: (req) {
        final qp = <String, String>{
          'page': req.page.toString(),
          'pageSize': req.pageSize.toString(),
          if (req.searchTerm != null && req.searchTerm!.isNotEmpty)
            'q': req.searchTerm!,
          for (final f in req.filters) f.field: f.value.toString(),
        };
        return Uri.https('demo.test', '/employees', qp).toString();
      },
      responseParser: (json) => DataTableResult<Employee>(
        data: (json['data'] as List)
            .map((e) => Employee(
                  id: e['id'] as int,
                  name: e['name'] as String,
                  role: e['role'] as String,
                  department: e['department'] as String,
                  yearsAtCompany: e['yearsAtCompany'] as int,
                  rating: (e['rating'] as num).toDouble(),
                  status: EmployeeStatus.active,
                ))
            .toList(),
        totalCount: json['total'] as int,
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
      ),
      httpClient: _client,
    );
    _controller = DataTableController<Employee>(dataSource: _source);
    _controller.addListener(() => setState(() {}));
    _client.callsListenable.addListener(() => setState(() {}));
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
        title: 'Cache invalidation',
        subtitle:
            'Wave 3.5 — drop only the pages affected by a write, or '
            'wipe the whole cache when there is no smarter answer.',
      ),
      body: Padding(
        padding: const EdgeInsets.all(InnvSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: _buildTable()),
            const SizedBox(width: InnvSpacing.lg),
            Expanded(child: _buildSidePanel()),
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
        field: 'department',
        label: 'Department',
        valueGetter: (e) => e.department,
        sortable: true,
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
      pageSize: 10,
      enableColumnResize: false,
      enableColumnDragDrop: false,
    );
  }

  Widget _buildSidePanel() {
    final theme = Theme.of(context);
    final currentPage = _controller.currentResult?.page ?? 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(InnvSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cache', style: theme.textTheme.titleMedium),
            const SizedBox(height: InnvSpacing.xs),
            Text(
              'Paginate to fetch new pages — each is memoized. Then '
              'invalidate and watch the request count.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: InnvSpacing.xl),
            _statTile('Network requests', '${_client.calls}'),
            _statTile('Cached entries', '${_source.cacheLength}'),
            const SizedBox(height: InnvSpacing.md),
            Text('Cached pages',
                style: theme.textTheme.labelLarge),
            const SizedBox(height: InnvSpacing.xs),
            if (_source.cacheLength == 0)
              Text(
                'Cache is empty.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final req in _source.cachedRequests)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• page ${req.page} (pageSize ${req.pageSize})',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: _source.cacheLength == 0
                  ? null
                  : () {
                      _source.invalidateCache(
                        where: (req) => req.page == currentPage,
                      );
                      setState(() {});
                    },
              icon: const Icon(Icons.filter_alt_off),
              label: Text('Invalidate current page only (page $currentPage)'),
            ),
            const SizedBox(height: InnvSpacing.xs),
            OutlinedButton.icon(
              onPressed: _source.cacheLength == 0
                  ? null
                  : () {
                      _source.invalidateCache();
                      setState(() {});
                    },
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Invalidate everything'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fake `http.Client` that serves paginated slices of an in-memory
/// dataset. Counts every send for the demo's stat tile.
class _CountingFakeClient extends http.BaseClient {
  final List<Employee> _data;
  final ValueNotifier<int> _calls = ValueNotifier<int>(0);

  _CountingFakeClient(this._data);

  int get calls => _calls.value;
  ValueListenable<int> get callsListenable => _calls;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Simulate just enough latency that the user can spot the spinner.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _calls.value = _calls.value + 1;

    final qp = request.url.queryParameters;
    final page = int.tryParse(qp['page'] ?? '') ?? 1;
    final pageSize = int.tryParse(qp['pageSize'] ?? '') ?? 10;
    final start = (page - 1) * pageSize;
    final end = min(_data.length, start + pageSize);
    final slice = start >= _data.length
        ? const <Employee>[]
        : _data.sublist(start, end);

    final body = jsonEncode({
      'data': slice
          .map((e) => {
                'id': e.id,
                'name': e.name,
                'role': e.role,
                'department': e.department,
                'yearsAtCompany': e.yearsAtCompany,
                'rating': e.rating,
              })
          .toList(),
      'total': _data.length,
      'page': page,
      'pageSize': pageSize,
    });
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(body)),
      200,
      reasonPhrase: 'OK',
    );
  }
}
