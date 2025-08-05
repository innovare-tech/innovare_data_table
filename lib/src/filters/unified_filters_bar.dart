import 'package:flutter/material.dart';
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_data_table/src/data_table_responsive.dart';
import 'package:innovare_data_table/src/data_table_theme.dart';
import 'package:innovare_data_table/src/filters/filter_models.dart';
import 'package:innovare_data_table/src/filters/modern_filters_dialog.dart';
import 'package:innovare_data_table/src/filters/quick_filters.dart';
import 'package:innovare_data_table/src/filters/smart_filter_pills.dart';
import 'package:innovare_data_table/src/filters/unified_filters_controller.dart';

// =============================================================================
// INTERFACE HÍBRIDA: BOTÃO EXPANDÍVEL + PILLS UNIFICADOS
// =============================================================================

class UnifiedFiltersBar<T> extends StatefulWidget {
  final UnifiedFiltersController<T> controller;
  final List<T> data;
  final DataTableColorScheme colors;
  final bool showQuickActions;
  final List<Widget> quickActions;

  const UnifiedFiltersBar({
    super.key,
    required this.controller,
    required this.data,
    required this.colors,
    this.showQuickActions = true,
    this.quickActions = const [],
  });

  @override
  State<UnifiedFiltersBar<T>> createState() => _UnifiedFiltersBarState<T>();
}

class _UnifiedFiltersBarState<T> extends State<UnifiedFiltersBar<T>>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late TextEditingController _searchController;

  bool _isQuickFiltersExpanded = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSearch();
    widget.controller.addListener(_onFiltersChanged);
  }

  void _initializeAnimations() {
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

  void _initializeSearch() {
    _searchController = TextEditingController(
      text: widget.controller.searchTerm ?? '',
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onFiltersChanged);
    _slideController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFiltersChanged() {
    if (mounted) {
      setState(() {});

      // Atualizar search controller se necessário
      final currentSearch = widget.controller.searchTerm ?? '';
      if (_searchController.text != currentSearch) {
        _searchController.text = currentSearch;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveTableManager.isMobile(context);

    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: [
          // ✅ BARRA PRINCIPAL COM BOTÃO DE QUICK FILTERS
          _buildMainBar(isMobile),

          // ✅ SEÇÃO EXPANDÍVEL DE QUICK FILTERS
          if (widget.controller.config.enableQuickFilters)
            _buildExpandableQuickFilters(),

          // ✅ PILLS UNIFICADOS (TODOS OS TIPOS DE FILTROS ATIVOS)
          if (widget.controller.config.showFilterPills && widget.controller.hasActiveFilters)
            SmartFilterPills<T>(
              controller: widget.controller,
              colors: widget.colors,
              maxHeight: 50,
              maxVisible: 6,
              autoCollapse: true,
              excludeQuickFilters: false, // ✅ INCLUIR TODOS OS FILTROS NOS PILLS
            ),
        ],
      ),
    );
  }

  Widget _buildMainBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 20,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: widget.colors.surface,
        border: Border(
          bottom: BorderSide(
            color: widget.colors.outline.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // ✅ BOTÃO DE QUICK FILTERS (SEMPRE VISÍVEL)
        if (widget.controller.config.enableQuickFilters)
          _buildQuickFiltersToggleButton(),

        const Spacer(),

        // ✅ SEARCH FIELD
        if (widget.controller.config.enableSearch)
          SizedBox(
            width: ResponsiveTableManager.getSearchFieldWidth(context),
            child: _buildEnhancedSearchField(),
          ),

        const SizedBox(width: 12),

        // Quick actions
        if (widget.showQuickActions && widget.quickActions.isNotEmpty)
          ...widget.quickActions.map((action) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: action,
          )),

        // ✅ ADVANCED FILTERS BUTTON
        if (widget.controller.config.enableAdvancedFilters)
          _buildAdvancedFiltersButton(),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row principal
        Row(
          children: [
            // Quick filters toggle
            if (widget.controller.config.enableQuickFilters)
              _buildQuickFiltersToggleButton(),

            const Spacer(),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.controller.config.enableAdvancedFilters)
                  _buildMobileAdvancedFiltersButton(),
                if (widget.showQuickActions && widget.quickActions.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ...widget.quickActions,
                ],
              ],
            ),
          ],
        ),

        // Search field (mobile)
        if (widget.controller.config.enableSearch) ...[
          const SizedBox(height: 12),
          _buildEnhancedSearchField(),
        ],
      ],
    );
  }

  // ✅ BOTÃO TOGGLE PARA QUICK FILTERS
  Widget _buildQuickFiltersToggleButton() {
    final hasActiveQuickFilters = widget.controller.quickFilters.isNotEmpty;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _isQuickFiltersExpanded = !_isQuickFiltersExpanded;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isQuickFiltersExpanded || hasActiveQuickFilters
                ? widget.colors.primary.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isQuickFiltersExpanded || hasActiveQuickFilters
                  ? widget.colors.primary.withOpacity(0.2)
                  : widget.colors.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Icon(
                    Icons.speed_rounded,
                    size: 18,
                    color: _isQuickFiltersExpanded || hasActiveQuickFilters
                        ? widget.colors.primary
                        : widget.colors.onSurfaceVariant,
                  ),
                  // ✅ BADGE COM NÚMERO DE FILTROS ATIVOS
                  if (hasActiveQuickFilters)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: widget.colors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.colors.surface,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${widget.controller.quickFilters.length}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Text(
                'Filtros Rápidos',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _isQuickFiltersExpanded || hasActiveQuickFilters
                      ? widget.colors.primary
                      : widget.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: _isQuickFiltersExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 16,
                  color: _isQuickFiltersExpanded || hasActiveQuickFilters
                      ? widget.colors.primary
                      : widget.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ SEÇÃO EXPANDÍVEL DOS QUICK FILTERS
  Widget _buildExpandableQuickFilters() {
    if (widget.controller.config.quickFiltersConfigs.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: _isQuickFiltersExpanded
          ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: widget.colors.surfaceVariant.withOpacity(0.3),
          border: Border(
            bottom: BorderSide(
              color: widget.colors.outline.withOpacity(0.08),
              width: 1,
            ),
          ),
        ),
        child: _buildQuickFiltersContent(),
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildQuickFiltersContent() {
    final activeQuickFilterIds = widget.controller.getActiveQuickFilterIds();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.speed_rounded,
              size: 16,
              color: widget.colors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Selecione os filtros rápidos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.colors.onSurface,
              ),
            ),
            const Spacer(),
            if (activeQuickFilterIds.isNotEmpty)
              TextButton(
                onPressed: () => widget.controller.clearFiltersByType(UnifiedFilterType.quick),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Limpar Todos',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.colors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // ✅ GRUPOS DE QUICK FILTERS (SEM MOSTRAR OS JÁ SELECIONADOS)
        ...widget.controller.config.quickFiltersConfigs.asMap().entries.map((entry) {
          final index = entry.key;
          final config = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group label
              if (config.groupLabel != null) ...[
                Text(
                  config.groupLabel!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.colors.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // ✅ FILTROS DISPONÍVEIS (HIGHLIGHTING DOS ATIVOS)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: config.filters.map((filter) {
                  return _buildSelectableQuickFilterChip(filter, config, activeQuickFilterIds);
                }).toList(),
              ),

              if (index < widget.controller.config.quickFiltersConfigs.length - 1)
                const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSelectableQuickFilterChip(
      QuickFilter<T> filter,
      QuickFiltersConfig<T> config,
      Set<String> activeIds,
      ) {
    final isActive = activeIds.contains(filter.id);
    final count = config.showCounts ? _getFilterCount(filter) : null;

    final baseColor = filter.color ?? config.groupColor ?? widget.colors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.controller.toggleQuickFilter(filter.id),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? baseColor
                : baseColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: baseColor.withOpacity(isActive ? 1.0 : 0.3),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: baseColor.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (filter.icon != null) ...[
                Icon(
                  filter.icon,
                  size: 14,
                  color: isActive ? Colors.white : baseColor,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                filter.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? Colors.white : baseColor,
                ),
              ),
              if (count != null && count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withOpacity(0.25)
                        : baseColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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

  Widget _buildEnhancedSearchField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (value) => widget.controller.search(value),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _searchFocusNode.hasFocus
                ? widget.colors.primary
                : widget.colors.onSurfaceVariant,
            size: 20,
          ),
          hintText: widget.controller.config.searchPlaceholder,
          hintStyle: TextStyle(
            color: widget.colors.onSurfaceVariant.withOpacity(0.7),
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: widget.colors.outline.withOpacity(0.5),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: widget.colors.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: widget.colors.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: widget.colors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.clear_rounded,
              color: widget.colors.onSurfaceVariant,
              size: 18,
            ),
            onPressed: () {
              _searchController.clear();
              widget.controller.clearSearch();
            },
          )
              : null,
        ),
        style: TextStyle(
          fontSize: 14,
          color: widget.colors.onSurface,
        ),
      ),
    );
  }

  Widget _buildAdvancedFiltersButton() {
    final hasAdvancedFilters = widget.controller.advancedFilters.isNotEmpty;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _showAdvancedFiltersDialog,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: hasAdvancedFilters
                ? widget.colors.primary.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasAdvancedFilters
                  ? widget.colors.primary.withOpacity(0.2)
                  : widget.colors.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 20,
                color: hasAdvancedFilters
                    ? widget.colors.primary
                    : widget.colors.onSurfaceVariant,
              ),
              if (hasAdvancedFilters)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: widget.colors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.colors.surface,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.controller.advancedFilters.length}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileAdvancedFiltersButton() {
    final hasAdvancedFilters = widget.controller.advancedFilters.isNotEmpty;

    return OutlinedButton.icon(
      onPressed: _showAdvancedFiltersDialog,
      icon: Stack(
        children: [
          Icon(
            Icons.tune_rounded,
            size: 18,
            color: widget.colors.primary,
          ),
          if (hasAdvancedFilters)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: widget.colors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${widget.controller.advancedFilters.length}',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      label: Text(
        'Avançados',
        style: TextStyle(
          color: widget.colors.primary,
          fontSize: 12,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: widget.colors.primary.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  int _getFilterCount(QuickFilter<T> filter) {
    if (filter.countGetter != null) {
      return filter.countGetter!(widget.data);
    }

    return widget.data.where((item) {
      if (widget.controller.fieldGetter != null) {
        final value = widget.controller.fieldGetter!(item, filter.field);
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

  void _showAdvancedFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => ModernFiltersDialog<T>(
        controller: widget.controller,
        colors: widget.colors,
      ),
    );
  }
}