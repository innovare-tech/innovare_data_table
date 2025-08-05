import 'package:flutter/material.dart';
import 'package:innovare_data_table/src/data_table_filters.dart';
import 'package:innovare_data_table/src/data_table_theme.dart';

// =============================================================================
// QUICK FILTERS - VERSÃO OTIMIZADA PARA INTEGRAÇÃO
// =============================================================================

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
      color: color ?? _getSmartStatusColor(value.toString()),
    );
  }

  factory QuickFilter.category({
    required String id,
    required String label,
    required dynamic value,
    IconData? icon,
    Color? color,
  }) {
    return QuickFilter<T>(
      id: id,
      label: label,
      icon: icon ?? Icons.category_outlined,
      field: 'category',
      value: value,
      operator: FilterOperator.equals,
      color: color ?? _getSmartCategoryColor(label),
    );
  }

  factory QuickFilter.dateRange({
    required String id,
    required String label,
    required DateTime startDate,
    required DateTime endDate,
    IconData? icon,
    Color? color,
  }) {
    return QuickFilter<T>(
      id: id,
      label: label,
      icon: icon ?? Icons.date_range,
      field: 'createdAt',
      value: {'start': startDate, 'end': endDate},
      operator: FilterOperator.between,
      color: color ?? const Color(0xFFF59E0B),
    );
  }

  factory QuickFilter.search({
    required String id,
    required String label,
    required String searchTerm,
    IconData? icon,
  }) {
    return QuickFilter<T>(
      id: id,
      label: label,
      icon: icon ?? Icons.search,
      field: 'search',
      value: searchTerm,
      operator: FilterOperator.contains,
      color: const Color(0xFF6366F1),
    );
  }

  factory QuickFilter.number({
    required String id,
    required String label,
    required String field,
    required num value,
    FilterOperator operator = FilterOperator.equals,
    IconData? icon,
  }) {
    return QuickFilter<T>(
      id: id,
      label: label,
      icon: icon ?? Icons.numbers,
      field: field,
      value: value,
      operator: operator,
      color: const Color(0xFF06B6D4),
    );
  }

  // Cores inteligentes
  static Color _getSmartStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('ativ') || statusLower.contains('succes') || statusLower.contains('complet')) {
      return const Color(0xFF10B981); // Verde
    }
    if (statusLower.contains('inativ') || statusLower.contains('error') || statusLower.contains('fail')) {
      return const Color(0xFFEF4444); // Vermelho
    }
    if (statusLower.contains('pend') || statusLower.contains('wait') || statusLower.contains('process')) {
      return const Color(0xFFF59E0B); // Laranja
    }
    return const Color(0xFF3B82F6); // Azul padrão
  }

  static Color _getSmartCategoryColor(String category) {
    final hash = category.hashCode;
    final colors = [
      const Color(0xFF8B5CF6), // Roxo
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFF59E0B), // Laranja
      const Color(0xFF10B981), // Verde
      const Color(0xFFEF4444), // Vermelho
      const Color(0xFF6366F1), // Indigo
    ];
    return colors[hash.abs() % colors.length];
  }
}

class QuickFiltersConfig<T> {
  final List<QuickFilter<T>> filters;
  final bool showCounts;
  final bool allowMultiple;
  final int maxVisible;
  final String? groupLabel;
  final Color? groupColor;
  final bool showSelectedGroup;
  final bool enableSmartColors;

  const QuickFiltersConfig({
    required this.filters,
    this.showCounts = true,
    this.allowMultiple = true,
    this.maxVisible = 6,
    this.groupLabel,
    this.groupColor,
    this.showSelectedGroup = true,
    this.enableSmartColors = true,
  });

  factory QuickFiltersConfig.status({
    List<String> statusList = const ['active', 'inactive', 'pending'],
    bool showCounts = true,
    bool allowMultiple = false,
  }) {
    return QuickFiltersConfig<T>(
      groupLabel: "Status",
      showCounts: showCounts,
      allowMultiple: allowMultiple,
      filters: statusList.map((status) => QuickFilter<T>.status(
        id: 'status_$status',
        label: _formatStatusLabel(status),
        value: status,
      )).toList(),
    );
  }

  factory QuickFiltersConfig.categories({
    required List<String> categories,
    bool showCounts = true,
    bool allowMultiple = true,
  }) {
    return QuickFiltersConfig<T>(
      groupLabel: "Categorias",
      showCounts: showCounts,
      allowMultiple: allowMultiple,
      filters: categories.map((category) => QuickFilter<T>.category(
        id: 'category_$category',
        label: category,
        value: category,
      )).toList(),
    );
  }

  factory QuickFiltersConfig.dateRanges({
    bool includeFuture = false,
  }) {
    final now = DateTime.now();
    final filters = <QuickFilter<T>>[];

    // Períodos passados
    filters.addAll([
      QuickFilter<T>.dateRange(
        id: 'today',
        label: 'Hoje',
        startDate: DateTime(now.year, now.month, now.day),
        endDate: now,
      ),
      QuickFilter<T>.dateRange(
        id: 'yesterday',
        label: 'Ontem',
        startDate: DateTime(now.year, now.month, now.day - 1),
        endDate: DateTime(now.year, now.month, now.day),
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
      QuickFilter<T>.dateRange(
        id: 'quarter',
        label: 'Último trimestre',
        startDate: DateTime(now.year, now.month - 3, now.day),
        endDate: now,
      ),
    ]);

    // Períodos futuros (se habilitado)
    if (includeFuture) {
      filters.addAll([
        QuickFilter<T>.dateRange(
          id: 'next_week',
          label: 'Próxima semana',
          startDate: now,
          endDate: now.add(const Duration(days: 7)),
        ),
        QuickFilter<T>.dateRange(
          id: 'next_month',
          label: 'Próximo mês',
          startDate: now,
          endDate: DateTime(now.year, now.month + 1, now.day),
        ),
      ]);
    }

    return QuickFiltersConfig<T>(
      groupLabel: "Período",
      allowMultiple: false,
      filters: filters,
    );
  }

  static String _formatStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Ativo';
      case 'inactive':
        return 'Inativo';
      case 'pending':
        return 'Pendente';
      case 'completed':
        return 'Concluído';
      case 'cancelled':
        return 'Cancelado';
      case 'draft':
        return 'Rascunho';
      default:
        return status.toUpperCase();
    }
  }
}

// =============================================================================
// WIDGET STANDALONE PARA COMPATIBILIDADE
// =============================================================================

class QuickFiltersBar<T> extends StatefulWidget {
  final List<QuickFiltersConfig<T>> configs;
  final List<T> data;
  final Set<String> activeFilterIds;
  final Function(Set<String> activeIds) onFiltersChanged;
  final DataTableColorScheme colors;
  final String Function(T item, String field)? fieldGetter;
  final bool showHeader;
  final bool compact;

  const QuickFiltersBar({
    super.key,
    required this.configs,
    required this.data,
    required this.activeFilterIds,
    required this.onFiltersChanged,
    required this.colors,
    this.fieldGetter,
    this.showHeader = true,
    this.compact = false,
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

  @override
  Widget build(BuildContext context) {
    if (widget.configs.isEmpty) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: widget.compact ? 8 : 16,
        ),
        decoration: BoxDecoration(
          color: widget.colors.surface,
          border: Border(
            bottom: BorderSide(
              color: widget.colors.outline.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            if (widget.showHeader && widget.activeFilterIds.isNotEmpty && !widget.compact) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${widget.activeFilterIds.length} filtro${widget.activeFilterIds.length > 1 ? 's' : ''} aplicado${widget.activeFilterIds.length > 1 ? 's' : ''}",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.colors.primary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onFiltersChanged({}),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "Limpar todos",
                      style: TextStyle(
                        color: widget.colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: widget.compact ? 8 : 12),
            ],

            // Grupos de filtros
            ...widget.configs.asMap().entries.map((entry) {
              final index = entry.key;
              final config = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (config.groupLabel != null && !widget.compact) ...[
                    Text(
                      config.groupLabel!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: config.filters.take(config.maxVisible).map((filter) {
                      return _buildFilterChip(filter, config);
                    }).toList(),
                  ),

                  if (index < widget.configs.length - 1)
                    SizedBox(height: widget.compact ? 8 : 16),
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

    final baseColor = filter.color ??
        config.groupColor ??
        widget.colors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleFilter(filter, config),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 12,
            vertical: widget.compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: isActive ? baseColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: baseColor,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (filter.icon != null) ...[
                Icon(
                  filter.icon,
                  size: widget.compact ? 12 : 14,
                  color: isActive ? Colors.white : baseColor,
                ),
                SizedBox(width: widget.compact ? 4 : 6),
              ],
              Text(
                filter.label,
                style: TextStyle(
                  fontSize: widget.compact ? 12 : 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? Colors.white : widget.colors.onSurface,
                ),
              ),
              if (count != null && count > 0) ...[
                SizedBox(width: widget.compact ? 4 : 6),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.compact ? 4 : 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withOpacity(0.25)
                        : baseColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: widget.compact ? 9 : 10,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : baseColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFilter(QuickFilter<T> filter, QuickFiltersConfig<T> config) {
    final newActiveIds = Set<String>.from(widget.activeFilterIds);

    if (!config.allowMultiple) {
      // Remove outros filtros do mesmo grupo
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
      case FilterOperator.contains:
        return itemValue?.toString().toLowerCase()
            .contains(filter.value?.toString().toLowerCase() ?? '') ?? false;
      case FilterOperator.between:
        if (filter.value is Map<String, DateTime>) {
          final range = filter.value as Map<String, DateTime>;
          final start = range['start'];
          final end = range['end'];
          if (itemValue is DateTime && start != null && end != null) {
            return itemValue.isAfter(start.subtract(const Duration(days: 1))) &&
                itemValue.isBefore(end.add(const Duration(days: 1)));
          }
        }
        return false;
      default:
        return itemValue?.toString().toLowerCase() ==
            filter.value?.toString().toLowerCase();
    }
  }
}