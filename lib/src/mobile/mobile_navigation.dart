import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:innovare_data_table/src/data_table_theme.dart';
import 'package:innovare_data_table/src/data_table_filters.dart';

class MobileBottomActionBar extends StatefulWidget {
  final int totalItems;
  final int currentPage;
  final int totalPages;
  final Function(int page)? onPageChanged;
  final VoidCallback? onSort;
  final VoidCallback? onFilter;
  final VoidCallback? onExport;
  final VoidCallback? onRefresh;
  final bool isLoading;
  final DataTableColorScheme colors;

  const MobileBottomActionBar({
    super.key,
    required this.totalItems,
    required this.currentPage,
    required this.totalPages,
    this.onPageChanged,
    this.onSort,
    this.onFilter,
    this.onExport,
    this.onRefresh,
    this.isLoading = false,
    required this.colors,
  });

  @override
  State<MobileBottomActionBar> createState() => _MobileBottomActionBarState();
}

class _MobileBottomActionBarState extends State<MobileBottomActionBar>
    with TickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabRotation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabRotation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _toggleActions() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }

    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: widget.colors.surface,
        border: Border(top: BorderSide(color: widget.colors.outline)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Info de páginas
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${widget.totalItems} itens',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.colors.onSurface,
                      ),
                    ),
                    if (widget.totalPages > 1)
                      Text(
                        'Página ${widget.currentPage + 1} de ${widget.totalPages}',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),

              // Navegação de páginas
              if (widget.totalPages > 1) ...[
                _buildPageButton(
                  icon: Icons.chevron_left,
                  enabled: widget.currentPage > 0,
                  onPressed: () => widget.onPageChanged?.call(widget.currentPage - 1),
                ),
                const SizedBox(width: 8),
                _buildPageButton(
                  icon: Icons.chevron_right,
                  enabled: widget.currentPage < widget.totalPages - 1,
                  onPressed: () => widget.onPageChanged?.call(widget.currentPage + 1),
                ),
                const SizedBox(width: 16),
              ],

              // FAB com ações
              _buildActionsFab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required bool enabled,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: enabled ? widget.colors.surface : widget.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: enabled ? widget.colors.outline : widget.colors.outline.withOpacity(0.5),
        ),
      ),
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(
          icon,
          color: enabled ? widget.colors.onSurface : widget.colors.onSurfaceVariant.withOpacity(0.5),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildActionsFab() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Expanded actions
        if (_isExpanded) ...[
          _buildExpandedAction(
            icon: Icons.sort,
            label: 'Ordenar',
            offset: const Offset(-70, -70),
            onTap: () {
              _toggleActions();
              widget.onSort?.call();
            },
          ),
          _buildExpandedAction(
            icon: Icons.filter_list,
            label: 'Filtrar',
            offset: const Offset(-70, -35),
            onTap: () {
              _toggleActions();
              widget.onFilter?.call();
            },
          ),
          if (widget.onExport != null)
            _buildExpandedAction(
              icon: Icons.download,
              label: 'Exportar',
              offset: const Offset(-35, -70),
              onTap: () {
                _toggleActions();
                widget.onExport?.call();
              },
            ),
          if (widget.onRefresh != null)
            _buildExpandedAction(
              icon: Icons.refresh,
              label: 'Atualizar',
              offset: const Offset(0, -70),
              onTap: () {
                _toggleActions();
                widget.onRefresh?.call();
              },
            ),
        ],

        // Main FAB
        AnimatedBuilder(
          animation: _fabRotation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _fabRotation.value * 2 * 3.14159,
              child: FloatingActionButton(
                onPressed: _toggleActions,
                backgroundColor: widget.colors.primary,
                child: widget.isLoading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                    : Icon(
                  _isExpanded ? Icons.close : Icons.more_vert,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExpandedAction({
    required IconData icon,
    required String label,
    required Offset offset,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return Transform.translate(
          offset: offset * animation,
          child: Opacity(
            opacity: animation,
            child: Transform.scale(
              scale: 0.5 + (0.5 * animation),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: widget.colors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.colors.outline),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: widget.colors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Material(
                    color: widget.colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    elevation: 4,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: widget.colors.outline),
                        ),
                        child: Icon(
                          icon,
                          color: widget.colors.onSurface,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Bottom Sheet para Filtros
// =============================================================================

class FilterBottomSheet<T> extends StatefulWidget {
  final List<AdvancedFilterConfig<T>> filterConfigs;
  final List<ActiveFilter> currentFilters;
  final Function(List<ActiveFilter>) onFiltersChanged;
  final DataTableColorScheme colors;

  const FilterBottomSheet({
    super.key,
    required this.filterConfigs,
    required this.currentFilters,
    required this.onFiltersChanged,
    required this.colors,
  });

  @override
  State<FilterBottomSheet<T>> createState() => _FilterBottomSheetState<T>();
}

class _FilterBottomSheetState<T> extends State<FilterBottomSheet<T>>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late List<ActiveFilter> _workingFilters;

  @override
  void initState() {
    super.initState();
    _workingFilters = List.from(widget.currentFilters);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
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

  Future<void> _close() async {
    await _slideController.reverse();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: widget.colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(),
              Expanded(child: _buildContent()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: widget.colors.onSurfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: widget.colors.outline)),
      ),
      child: Row(
        children: [
          Icon(Icons.tune_rounded, color: widget.colors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Filtros',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: widget.colors.onSurface,
              ),
            ),
          ),
          if (_workingFilters.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _workingFilters.clear();
                });
              },
              child: Text(
                'Limpar',
                style: TextStyle(color: widget.colors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Quick filters
        if (widget.filterConfigs.isNotEmpty) ...[
          Text(
            'Filtros Rápidos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.filterConfigs.take(5).map((config) => _buildQuickFilter(config)),
          const SizedBox(height: 24),
        ],

        // Active filters
        if (_workingFilters.isNotEmpty) ...[
          Text(
            'Filtros Ativos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ..._workingFilters.asMap().entries.map((entry) {
            final index = entry.key;
            final filter = entry.value;
            return _buildActiveFilter(filter, index);
          }),
        ],
      ],
    );
  }

  Widget _buildQuickFilter(AdvancedFilterConfig<T> config) {
    if (config.type == SimpleFilterType.select && config.options != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.colors.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.colors.outline.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: config.options!.map((option) {
                final isActive = _workingFilters.any(
                      (f) => f.field == config.field && f.value == option,
                );

                return FilterChip(
                  selected: isActive,
                  onSelected: (selected) => _toggleQuickFilter(config, option, selected),
                  label: Text(
                    option.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? Colors.white : widget.colors.onSurface,
                    ),
                  ),
                  backgroundColor: widget.colors.surface,
                  selectedColor: widget.colors.primary,
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActiveFilter(ActiveFilter filter, int index) {
    final config = widget.filterConfigs.firstWhere(
          (c) => c.field == filter.field,
      orElse: () => AdvancedFilterConfig<T>(
        field: filter.field,
        label: filter.field,
        type: SimpleFilterType.text,
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.colors.primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.colors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filter.getDisplayText(config.label),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.colors.onSurface,
                  ),
                ),
                if (config.field != config.label)
                  Text(
                    'Campo: ${config.field}',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: filter.isActive,
            onChanged: (value) {
              setState(() {
                _workingFilters[index] = filter.copyWith(isActive: value);
              });
            },
            activeColor: widget.colors.primary,
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _workingFilters.removeAt(index);
              });
            },
            icon: Icon(
              Icons.close,
              color: widget.colors.error,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: widget.colors.outline)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _close,
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  widget.onFiltersChanged(_workingFilters);
                  _close();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.colors.primary,
                ),
                child: const Text('Aplicar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleQuickFilter(AdvancedFilterConfig<T> config, dynamic value, bool selected) {
    setState(() {
      if (selected) {
        _workingFilters.add(ActiveFilter(
          field: config.field,
          operator: FilterOperator.equals,
          value: value,
        ));
      } else {
        _workingFilters.removeWhere(
              (f) => f.field == config.field && f.value == value,
        );
      }
    });
  }
}

// =============================================================================
// Bottom Sheet para Ordenação
// =============================================================================

class SortBottomSheet extends StatefulWidget {
  final List<SortOption> sortOptions;
  final String? currentSortField;
  final bool isAscending;
  final Function(String? field, bool ascending) onSortChanged;
  final DataTableColorScheme colors;

  const SortBottomSheet({
    super.key,
    required this.sortOptions,
    this.currentSortField,
    required this.isAscending,
    required this.onSortChanged,
    required this.colors,
  });

  @override
  State<SortBottomSheet> createState() => _SortBottomSheetState();
}

class SortOption {
  final String field;
  final String label;
  final IconData? icon;

  const SortOption({
    required this.field,
    required this.label,
    this.icon,
  });
}

class _SortBottomSheetState extends State<SortBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  String? _selectedField;
  bool _selectedAscending = true;

  @override
  void initState() {
    super.initState();
    _selectedField = widget.currentSortField;
    _selectedAscending = widget.isAscending;

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
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

  Future<void> _close() async {
    await _slideController.reverse();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: widget.colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(),
              Expanded(child: _buildContent()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: widget.colors.onSurfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: widget.colors.outline)),
      ),
      child: Row(
        children: [
          Icon(Icons.sort, color: widget.colors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ordenar por',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: widget.colors.onSurface,
              ),
            ),
          ),
          if (_selectedField != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedField = null;
                });
              },
              child: Text(
                'Remover',
                style: TextStyle(color: widget.colors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Direção da ordenação
        if (_selectedField != null) ...[
          Text(
            'Direção',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDirectionButton(
                  label: 'Crescente',
                  icon: Icons.arrow_upward,
                  isSelected: _selectedAscending,
                  onTap: () => setState(() => _selectedAscending = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDirectionButton(
                  label: 'Decrescente',
                  icon: Icons.arrow_downward,
                  isSelected: !_selectedAscending,
                  onTap: () => setState(() => _selectedAscending = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],

        // Campos disponíveis
        Text(
          'Campo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.colors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.sortOptions.map((option) => _buildSortOption(option)),
      ],
    );
  }

  Widget _buildDirectionButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? widget.colors.primary : widget.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? widget.colors.primary : widget.colors.outline,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : widget.colors.onSurface,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : widget.colors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(SortOption option) {
    final isSelected = _selectedField == option.field;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<String>(
        value: option.field,
        groupValue: _selectedField,
        onChanged: (value) {
          setState(() {
            _selectedField = value;
          });
        },
        title: Text(
          option.label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: widget.colors.onSurface,
          ),
        ),
        subtitle: Text(
          'Campo: ${option.field}',
          style: TextStyle(
            fontSize: 12,
            color: widget.colors.onSurfaceVariant,
          ),
        ),
        secondary: option.icon != null
            ? Icon(
          option.icon,
          color: isSelected ? widget.colors.primary : widget.colors.onSurfaceVariant,
        )
            : null,
        activeColor: widget.colors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: isSelected ? widget.colors.primaryLight.withOpacity(0.1) : null,
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: widget.colors.outline)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _close,
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  widget.onSortChanged(_selectedField, _selectedAscending);
                  _close();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.colors.primary,
                ),
                child: const Text('Aplicar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
