import 'package:flutter/material.dart';
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_data_table/src/performance/debounced_operations.dart';
import 'package:innovare_data_table/src/performance/memory_optimization.dart';
import 'package:innovare_data_table/src/performance/performance_monitor.dart';
import 'package:innovare_data_table/src/performance/virtual_scrolling.dart';

class OptimizedDataTable<T> extends StatefulWidget {
  final List<T> items;
  final List<DataColumnConfig<T>> columns;
  final VirtualScrollConfig? virtualScrollConfig;
  final bool enableVirtualScrolling;
  final bool enableMemoryOptimization;
  final bool enablePerformanceMonitoring;
  final Widget Function(BuildContext context, int index, T item)? rowBuilder;

  const OptimizedDataTable({
    super.key,
    required this.items,
    required this.columns,
    this.virtualScrollConfig,
    this.enableVirtualScrolling = true,
    this.enableMemoryOptimization = true,
    this.enablePerformanceMonitoring = false,
    this.rowBuilder,
  });

  @override
  State<OptimizedDataTable<T>> createState() => _OptimizedDataTableState<T>();
}

class _OptimizedDataTableState<T> extends State<OptimizedDataTable<T>> {
  late VirtualScrollController _virtualController;
  late MemoryManager<Widget> _memoryManager;
  late DebouncedOperation _searchDebouncer;
  late ThrottledOperation _scrollThrottler;

  @override
  void initState() {
    super.initState();

    if (widget.enableVirtualScrolling) {
      _virtualController = VirtualScrollController(
        config: widget.virtualScrollConfig ?? const VirtualScrollConfig(),
      );
    }

    if (widget.enableMemoryOptimization) {
      _memoryManager = MemoryManager<Widget>();
    }

    _searchDebouncer = DebouncedOperation();
    _scrollThrottler = ThrottledOperation();
  }

  @override
  void dispose() {
    if (widget.enableVirtualScrolling) {
      _virtualController.dispose();
    }
    _searchDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (widget.enableVirtualScrolling && widget.items.length > 100) {
      content = _buildVirtualizedTable();
    } else {
      content = _buildRegularTable();
    }

    if (widget.enablePerformanceMonitoring) {
      content = _wrapWithPerformanceMonitoring(content);
    }

    return content;
  }

  Widget _buildVirtualizedTable() {
    return VirtualListView<T>(
      items: widget.items,
      controller: _virtualController,
      config: widget.virtualScrollConfig ?? const VirtualScrollConfig(),
      itemBuilder: (context, index, item) {
        return widget.rowBuilder?.call(context, index, item) ??
            _buildDefaultRow(context, index, item);
      },
    );
  }

  Widget _buildRegularTable() {
    return ListView.builder(
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return widget.rowBuilder?.call(context, index, item) ??
            _buildDefaultRow(context, index, item);
      },
    );
  }

  Widget _buildDefaultRow(BuildContext context, int index, T item) {
    if (widget.enableMemoryOptimization) {
      final cacheKey = 'row_$index';
      final cached = _memoryManager.get(cacheKey);

      if (cached != null) {
        return cached;
      }

      final row = _createRowWidget(context, index, item);
      _memoryManager.put(cacheKey, row);
      return row;
    }

    return _createRowWidget(context, index, item);
  }

  Widget _createRowWidget(BuildContext context, int index, T item) {
    return Container(
      height: widget.virtualScrollConfig?.itemHeight ?? 52.0,
      child: Row(
        children: widget.columns.map((column) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: column.cellBuilder?.call(item) ??
                  Text(
                    column.valueGetter(item).toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _wrapWithPerformanceMonitoring(Widget child) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          _scrollThrottler.run(() {
            PerformanceMonitor.measureOperation('scroll_update', () {
              // Lógica de scroll otimizada
            });
          });
        }
        return false;
      },
      child: child,
    );
  }
}