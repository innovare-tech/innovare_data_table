import 'package:flutter/material.dart';
import 'package:innovare_data_table/src/data_table_responsive.dart';
import 'package:innovare_data_table/src/data_table_theme.dart';
import 'package:innovare_data_table/src/filters/filter_models.dart';
import 'package:innovare_data_table/src/filters/unified_filters_controller.dart';

// =============================================================================
// PILLS INTELIGENTES SEM REDUNDÂNCIA DE QUICK FILTERS
// =============================================================================

class SmartFilterPills<T> extends StatefulWidget {
  final UnifiedFiltersController<T> controller;
  final DataTableColorScheme colors;
  final double maxHeight;
  final int maxVisible;
  final bool autoCollapse;
  final bool showClearAll;
  final bool excludeQuickFilters; // ✅ NOVA OPÇÃO

  const SmartFilterPills({
    super.key,
    required this.controller,
    required this.colors,
    this.maxHeight = 60,
    this.maxVisible = 5,
    this.autoCollapse = true,
    this.showClearAll = true,
    this.excludeQuickFilters = true, // ✅ PADRÃO: EXCLUIR QUICK FILTERS
  });

  @override
  State<SmartFilterPills<T>> createState() => _SmartFilterPillsState<T>();
}

class _SmartFilterPillsState<T> extends State<SmartFilterPills<T>>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _expandController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _expandAnimation;

  bool _isExpanded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    widget.controller.addListener(_onFiltersChanged);
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));

    _expandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeOutCubic),
    );

    if (_hasRelevantFilters()) {
      _slideController.forward();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onFiltersChanged);
    _slideController.dispose();
    _expandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFiltersChanged() {
    if (mounted) {
      setState(() {});

      if (_hasRelevantFilters() && _slideController.isDismissed) {
        _slideController.forward();
      } else if (!_hasRelevantFilters() && _slideController.isCompleted) {
        _slideController.reverse();
      }
    }
  }

  // ✅ VERIFICA SE HÁ FILTROS RELEVANTES (EXCLUINDO QUICK FILTERS SE NECESSÁRIO)
  bool _hasRelevantFilters() {
    final relevantFilters = _getRelevantFilters();
    return relevantFilters.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasRelevantFilters()) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: _buildModernFilterBar(),
    );
  }

  Widget _buildModernFilterBar() {
    final isMobile = ResponsiveTableManager.isMobile(context);
    final relevantFilters = _getRelevantFilters();
    final totalCount = relevantFilters.length;
    final hasMore = relevantFilters.length > widget.maxVisible;

    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      decoration: BoxDecoration(
        color: widget.colors.surface,
        border: Border(
          bottom: BorderSide(
            color: widget.colors.outline.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 20,
          vertical: 8,
        ),
        child: Row(
          children: [
            // ✅ INDICADOR COMPACTO
            _buildCompactIndicator(totalCount),

            const SizedBox(width: 12),

            // ✅ FILTROS EM LINHA HORIZONTAL
            Expanded(
              child: _buildHorizontalFilters(relevantFilters, hasMore),
            ),

            const SizedBox(width: 12),

            // ✅ BOTÃO LIMPAR COMPACTO (APENAS FILTROS RELEVANTES)
            _buildCompactClearButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactIndicator(int totalFilters) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.colors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.colors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_alt_rounded,
            size: 14,
            color: widget.colors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '$totalFilters',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: widget.colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalFilters(List<UnifiedFilter<T>> relevantFilters, bool hasMore) {
    final displayFilters = _isExpanded ? relevantFilters : relevantFilters.take(widget.maxVisible).toList();

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            // Filtros visíveis
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: displayFilters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  return _buildModernFilterPill(displayFilters[index], index);
                },
              ),
            ),

            // Botão "mais" se necessário
            if (hasMore && !_isExpanded) ...[
              const SizedBox(width: 8),
              _buildMoreButton(relevantFilters.length - widget.maxVisible),
            ],

            // Botão "menos" se expandido
            if (_isExpanded && hasMore) ...[
              const SizedBox(width: 8),
              _buildCollapseButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernFilterPill(UnifiedFilter<T> filter, int index) {
    final pillColor = filter.color ?? _getCategoryColor(filter.category);
    final isSearchFilter = filter.type == UnifiedFilterType.search;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 150 + (index * 30)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * animation),
          child: Opacity(
            opacity: animation,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => widget.controller.removeFilter(filter.id),
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSearchFilter
                        ? widget.colors.primary.withOpacity(0.1)
                        : pillColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSearchFilter
                          ? widget.colors.primary.withOpacity(0.3)
                          : pillColor.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ ÍCONE MENOR E MAIS SUTIL
                      Icon(
                        _getFilterTypeIcon(filter.type),
                        size: 12,
                        color: isSearchFilter ? widget.colors.primary : pillColor,
                      ),
                      const SizedBox(width: 4),

                      // ✅ TEXTO COMPACTO
                      Flexible(
                        child: Text(
                          _getCompactDisplayText(filter),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSearchFilter ? widget.colors.primary : pillColor,
                            height: 1,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),

                      const SizedBox(width: 2),

                      // ✅ ÍCONE DE REMOVER MENOR
                      Icon(
                        Icons.close_rounded,
                        size: 12,
                        color: (isSearchFilter ? widget.colors.primary : pillColor).withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoreButton(int hiddenCount) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _toggleExpanded,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.colors.surfaceVariant.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.colors.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 12,
                color: widget.colors.onSurfaceVariant,
              ),
              const SizedBox(width: 2),
              Text(
                '+$hiddenCount',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _toggleExpanded,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.colors.surfaceVariant.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.colors.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.remove_rounded,
            size: 14,
            color: widget.colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactClearButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _clearRelevantFilters,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.colors.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.colors.error.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.clear_all_rounded,
                size: 12,
                color: widget.colors.error,
              ),
              const SizedBox(width: 4),
              Text(
                'Limpar',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.colors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ MÉTODOS AUXILIARES OTIMIZADOS

  IconData _getFilterTypeIcon(UnifiedFilterType type) {
    switch (type) {
      case UnifiedFilterType.search:
        return Icons.search_rounded;
      case UnifiedFilterType.advanced:
        return Icons.tune_rounded;
      case UnifiedFilterType.column:
        return Icons.view_column_rounded;
      case UnifiedFilterType.dateRange:
        return Icons.date_range_rounded;
      case UnifiedFilterType.multiSelect:
        return Icons.checklist_rounded;
      case UnifiedFilterType.quick:
        return Icons.speed_rounded; // Embora não seja mostrado por padrão
    }
  }

  String _getCompactDisplayText(UnifiedFilter<T> filter) {
    switch (filter.type) {
      case UnifiedFilterType.search:
        final value = filter.value.toString();
        return value.length > 15 ? '"${value.substring(0, 12)}..."' : '"$value"';

      case UnifiedFilterType.advanced:
        final text = '${filter.label}: ${filter.value}';
        return text.length > 20 ? '${text.substring(0, 17)}...' : text;

      default:
        final text = filter.displayText;
        return text.length > 18 ? '${text.substring(0, 15)}...' : text;
    }
  }

  // ✅ OBTÉM APENAS FILTROS RELEVANTES (EXCLUINDO QUICK FILTERS SE NECESSÁRIO)
  List<UnifiedFilter<T>> _getRelevantFilters() {
    final allFilters = <UnifiedFilter<T>>[];

    // Adicionar search se ativo
    if (widget.controller.searchTerm?.isNotEmpty == true) {
      allFilters.add(UnifiedFilter<T>.search(widget.controller.searchTerm!));
    }

    // Adicionar filtros ativos (excluindo quick filters se solicitado)
    for (final filter in widget.controller.activeFilters) {
      if (widget.excludeQuickFilters && filter.type == UnifiedFilterType.quick) {
        continue; // ✅ PULAR QUICK FILTERS
      }
      allFilters.add(filter);
    }

    return allFilters;
  }

  Color _getCategoryColor(FilterCategory category) {
    switch (category) {
      case FilterCategory.text:
        return widget.colors.primary;
      case FilterCategory.status:
        return const Color(0xFF10B981); // Verde
      case FilterCategory.category:
        return const Color(0xFF8B5CF6); // Roxo
      case FilterCategory.date:
        return const Color(0xFFF59E0B); // Laranja
      case FilterCategory.number:
        return const Color(0xFF06B6D4); // Cyan
      case FilterCategory.custom:
        return widget.colors.onSurfaceVariant;
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  // ✅ LIMPAR APENAS OS FILTROS RELEVANTES (NÃO QUICK FILTERS)
  void _clearRelevantFilters() {
    if (widget.excludeQuickFilters) {
      // Limpar apenas search e advanced filters
      widget.controller.clearSearch();
      widget.controller.clearFiltersByType(UnifiedFilterType.advanced);
      widget.controller.clearFiltersByType(UnifiedFilterType.column);
      widget.controller.clearFiltersByType(UnifiedFilterType.dateRange);
      widget.controller.clearFiltersByType(UnifiedFilterType.multiSelect);
    } else {
      // Limpar todos os filtros
      widget.controller.clearAllFilters();
    }
  }
}