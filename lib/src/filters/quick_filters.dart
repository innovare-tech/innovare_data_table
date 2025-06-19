import 'package:flutter/material.dart';
import 'package:innovare_data_table/src/data_table_filters.dart';
import 'package:innovare_data_table/src/data_table_theme.dart';

class QuickFilter<T> {
  final String id;
  final String label;
  final IconData? icon;
  final String field;
  final dynamic value;
  final FilterOperator operator;
  final Color? color;
  final bool isDefault;
  final int Function(List<T> data)? countGetter;

  const QuickFilter({
    required this.id,
    required this.label,
    this.icon,
    required this.field,
    required this.value,
    this.operator = FilterOperator.equals,
    this.color,
    this.isDefault = false,
    this.countGetter,
  });

  factory QuickFilter.status({
    required String id,
    required String label,
    required dynamic value,
    IconData? icon,
    Color? color,
  }) {
    return QuickFilter<T>(
      id: id,
      label: label,
      icon: icon ?? Icons.radio_button_checked,
      field: 'status',
      value: value,
      operator: FilterOperator.equals,
      color: color,
    );
  }

  factory QuickFilter.category({
    required String id,
    required String label,
    required dynamic value,
    IconData? icon,
  }) {
    return QuickFilter<T>(
      id: id,
      label: label,
      icon: icon ?? Icons.category_outlined,
      field: 'category',
      value: value,
      operator: FilterOperator.equals,
    );
  }

  factory QuickFilter.dateRange({
    required String id,
    required String label,
    required DateTime startDate,
    required DateTime endDate,
    IconData? icon,
  }) {
    return QuickFilter<T>(
      id: id,
      label: label,
      icon: icon ?? Icons.date_range,
      field: 'createdAt',
      value: {'start': startDate, 'end': endDate},
      operator: FilterOperator.between,
    );
  }
}

class QuickFiltersConfig<T> {
  final List<QuickFilter<T>> filters;
  final bool showCounts;
  final bool allowMultiple;
  final int maxVisible;
  final String? groupLabel;

  const QuickFiltersConfig({
    required this.filters,
    this.showCounts = true,
    this.allowMultiple = true,
    this.maxVisible = 6,
    this.groupLabel,
  });

  factory QuickFiltersConfig.status({
    List<String> statusList = const ['active', 'inactive', 'pending'],
    bool showCounts = true,
  }) {
    return QuickFiltersConfig<T>(
      groupLabel: "Status",
      showCounts: showCounts,
      filters: statusList.map((status) => QuickFilter<T>.status(
        id: 'status_$status',
        label: status.toUpperCase(),
        value: status,
        color: _getStatusColor(status),
      )).toList(),
    );
  }

  factory QuickFiltersConfig.dateRanges() {
    final now = DateTime.now();
    return QuickFiltersConfig<T>(
      groupLabel: "Período",
      allowMultiple: false,
      filters: [
        QuickFilter<T>.dateRange(
          id: 'today',
          label: 'Hoje',
          startDate: DateTime(now.year, now.month, now.day),
          endDate: now,
        ),
        QuickFilter<T>.dateRange(
          id: 'week',
          label: 'Última semana',
          startDate: now.subtract(const Duration(days: 7)),
          endDate: now,
        ),
        QuickFilter<T>.dateRange(
          id: 'month',
          label: 'Último mês',
          startDate: DateTime(now.year, now.month - 1, now.day),
          endDate: now,
        ),
      ],
    );
  }

  static Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'ativo':
        return Colors.green;
      case 'inactive':
      case 'inativo':
        return Colors.red;
      case 'pending':
      case 'pendente':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

class QuickFiltersBar<T> extends StatefulWidget {
  final List<QuickFiltersConfig<T>> configs;
  final List<T> data;
  final Set<String> activeFilterIds;
  final Function(Set<String> activeIds) onFiltersChanged;
  final DataTableColorScheme colors;
  final String Function(T item, String field)? fieldGetter;

  const QuickFiltersBar({
    super.key,
    required this.configs,
    required this.data,
    required this.activeFilterIds,
    required this.onFiltersChanged,
    required this.colors,
    this.fieldGetter,
  });

  @override
  State<QuickFiltersBar<T>> createState() => _QuickFiltersBarState<T>();
}

class _QuickFiltersBarState<T> extends State<QuickFiltersBar<T>>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  int _getFilterCount(QuickFilter<T> filter) {
    if (filter.countGetter != null) {
      return filter.countGetter!(widget.data);
    }

    return widget.data.where((item) {
      if (widget.fieldGetter != null) {
        final value = widget.fieldGetter!(item, filter.field);
        return _matchesFilter(value, filter);
      }
      return false;
    }).length;
  }

  bool _matchesFilter(dynamic itemValue, QuickFilter<T> filter) {
    switch (filter.operator) {
      case FilterOperator.equals:
        return itemValue?.toString().toLowerCase() ==
            filter.value?.toString().toLowerCase();
      case FilterOperator.between:
        if (filter.value is Map<String, DateTime>) {
          final range = filter.value as Map<String, DateTime>;
          final start = range['start'];
          final end = range['end'];
          if (itemValue is DateTime && start != null && end != null) {
            return itemValue.isAfter(start) && itemValue.isBefore(end);
          }
        }
        return false;
      default:
        return false;
    }
  }

  void _toggleFilter(QuickFilter<T> filter, QuickFiltersConfig<T> config) {
    final newActiveIds = Set<String>.from(widget.activeFilterIds);

    if (!config.allowMultiple) {
      // Remover outros filtros do mesmo grupo
      for (final otherFilter in config.filters) {
        newActiveIds.remove(otherFilter.id);
      }
    }

    if (widget.activeFilterIds.contains(filter.id)) {
      newActiveIds.remove(filter.id);
    } else {
      newActiveIds.add(filter.id);
    }

    widget.onFiltersChanged(newActiveIds);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.configs.isEmpty) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: widget.colors.surface,
          border: Border(
            bottom: BorderSide(
              color: widget.colors.outline.withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com clear all
            if (widget.activeFilterIds.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    "Filtros ativos",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.colors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => widget.onFiltersChanged({}),
                    icon: Icon(
                      Icons.clear_all,
                      size: 16,
                      color: widget.colors.onSurfaceVariant,
                    ),
                    label: Text(
                      "Limpar todos",
                      style: TextStyle(
                        color: widget.colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Grupos de filtros
            ...widget.configs.asMap().entries.map((entry) {
              final index = entry.key;
              final config = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (config.groupLabel != null) ...[
                    Text(
                      config.groupLabel!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: widget.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: config.filters.take(config.maxVisible).map((filter) {
                      return _buildFilterChip(filter, config);
                    }).toList(),
                  ),

                  if (index < widget.configs.length - 1)
                    const SizedBox(height: 12),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(QuickFilter<T> filter, QuickFiltersConfig<T> config) {
    final isActive = widget.activeFilterIds.contains(filter.id);
    final count = config.showCounts ? _getFilterCount(filter) : null;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animation),
          child: Opacity(
            opacity: animation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilterChip(
                selected: isActive,
                onSelected: (_) => _toggleFilter(filter, config),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (filter.icon != null) ...[
                      Icon(
                        filter.icon,
                        size: 14,
                        color: isActive
                            ? Colors.white
                            : filter.color ?? widget.colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isActive ? Colors.white : widget.colors.onSurface,
                      ),
                    ),
                    if (count != null && count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white.withOpacity(0.2)
                              : widget.colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.white
                                : widget.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                backgroundColor: widget.colors.surface,
                selectedColor: filter.color ?? widget.colors.primary,
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isActive
                      ? (filter.color ?? widget.colors.primary)
                      : widget.colors.outline,
                  width: 1,
                ),
                elevation: isActive ? 2 : 0,
                pressElevation: 4,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        );
      },
    );
  }
}
