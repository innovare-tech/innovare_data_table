import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:innovare_data_table/src/data_column_config.dart';
import 'package:innovare_data_table/src/data_sources/data_table_models.dart';
import 'package:innovare_data_table/src/data_table_filters.dart';
import 'package:innovare_data_table/src/data_table_theme.dart';
import 'package:innovare_data_table/src/resizable_header_cell.dart';

/// Signal emitted by a header cell when the user requests a sort change.
///
/// [additive] is `true` when the click came with Shift held — meaning the
/// user wants this column added to the existing sort stack instead of
/// replacing it. Parents typically translate that into
/// `DataTableController.sortMulti(...)` calls.
typedef OnSortRequested = void Function({
  required String field,
  required bool ascending,
  required bool additive,
});

// COMPONENTE PURO DE HEADER COM RESIZE (SEM DRAG & DROP)
class PureResizableHeaderCell<T> extends StatefulWidget {
  final DataColumnConfig<T> column;
  final int index;
  final InnovareDataTableThemeData theme;
  final DataTableColorScheme colors;
  final DensityConfig density;
  final List<ColumnFilterOption<T>> columnFilters;
  final Map<String, dynamic> columnFiltersState;
  final Function(String, dynamic) onColumnFilterChanged;
  final ColumnResizeController resizeController;
  final bool enableResize;

  // Parâmetros para sort (single-column — legacy API mantida).
  final String? currentSortField;
  final bool isAscending;
  final Function(String field, bool ascending)? onSort;

  /// Multi-column sort stack (priority order). When non-empty, takes
  /// precedence over [currentSortField]/[isAscending] for both the active
  /// state and the priority badge (1, 2, 3 …).
  final List<DataTableSort> activeSorts;

  /// Sort intent callback that exposes the Shift modifier (additive flag).
  /// When provided, takes precedence over [onSort].
  final OnSortRequested? onSortRequested;

  const PureResizableHeaderCell({
    super.key,
    required this.column,
    required this.index,
    required this.theme,
    required this.colors,
    required this.density,
    required this.columnFilters,
    required this.columnFiltersState,
    required this.onColumnFilterChanged,
    required this.resizeController,
    this.enableResize = true,
    this.currentSortField,
    this.isAscending = true,
    this.onSort,
    this.activeSorts = const [],
    this.onSortRequested,
  });

  @override
  State<PureResizableHeaderCell<T>> createState() => _PureResizableHeaderCellState<T>();
}

class _PureResizableHeaderCellState<T> extends State<PureResizableHeaderCell<T>>
    with TickerProviderStateMixin {

  bool _isResizing = false;
  bool _isHoveringResize = false;
  bool _isHoveringCell = false;
  double _startX = 0;
  double _startWidth = 0;

  // Animações
  late AnimationController _resizeAnimationController;
  late AnimationController _hoverAnimationController;
  late Animation<double> _resizeLineOpacity;
  late Animation<double> _hoverScale;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupColumnInController();
  }

  void _initializeAnimations() {
    _resizeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _hoverAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _resizeLineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resizeAnimationController, curve: Curves.easeOut),
    );

    _hoverScale = Tween<double>(begin: 1.0, end: 1.01).animate(
      CurvedAnimation(parent: _hoverAnimationController, curve: Curves.easeOut),
    );
  }

  void _setupColumnInController() {
    // ✨ CORREÇÃO: Usar addPostFrameCallback para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Configurar a coluna no controller usando as configurações do DataColumnConfig
      if (widget.column.resizeConfig != null) {
        final config = widget.column.resizeConfig!;

        // Definir largura inicial se especificada
        if (config.initialWidth != null) {
          widget.resizeController.setColumnWidth(widget.column.field, config.initialWidth!);
        }

        // Definir limites
        widget.resizeController.setColumnLimits(
          widget.column.field,
          minWidth: config.minWidth,
          maxWidth: config.maxWidth,
        );
      } else {
        // Fallback para sistema antigo (compatibilidade)
        widget.resizeController.setColumnLimits(
          widget.column.field,
          minWidth: widget.column.effectiveMinWidth,
          maxWidth: widget.column.effectiveMaxWidth,
        );

        if (widget.column.effectiveWidth != 200.0) {
          widget.resizeController.setColumnWidth(widget.column.field, widget.column.effectiveWidth);
        }
      }
    });
  }


  @override
  void dispose() {
    _resizeAnimationController.dispose();
    _hoverAnimationController.dispose();
    super.dispose();
  }

  /// Returns the current sort direction for [widget.column], or `null` if
  /// the column isn't currently sorted. Reads from [activeSorts] first
  /// (multi-sort path) and falls back to [currentSortField]/[isAscending]
  /// (legacy single-sort path).
  bool? get _currentSortDirection {
    if (widget.activeSorts.isNotEmpty) {
      for (final s in widget.activeSorts) {
        if (s.field == widget.column.field) return s.ascending;
      }
      return null;
    }
    if (widget.currentSortField == widget.column.field) {
      return widget.isAscending;
    }
    return null;
  }

  /// 1-indexed position of this column in [activeSorts], or `null` when the
  /// column isn't part of a multi-sort stack. Used to render the priority
  /// badge (1, 2, 3 …) next to the direction icon.
  int? get _sortPriority {
    if (widget.activeSorts.length < 2) return null;
    final idx =
        widget.activeSorts.indexWhere((s) => s.field == widget.column.field);
    return idx < 0 ? null : idx + 1;
  }

  void _handleSort() {
    if (!widget.column.sortable) return;
    if (widget.onSort == null && widget.onSortRequested == null) return;

    final currentAscending = _currentSortDirection;
    final newAscending =
        currentAscending == null ? true : !currentAscending;

    // Shift+click → additive multi-sort. Read directly from
    // HardwareKeyboard since GestureDetector doesn't expose modifiers.
    final additive = HardwareKeyboard.instance.logicalKeysPressed.any(
      (k) => k == LogicalKeyboardKey.shiftLeft ||
          k == LogicalKeyboardKey.shiftRight,
    );

    if (widget.onSortRequested != null) {
      widget.onSortRequested!(
        field: widget.column.field,
        ascending: newAscending,
        additive: additive,
      );
      return;
    }
    // Legacy single-sort callback — no Shift information forwarded.
    widget.onSort!(widget.column.field, newAscending);
  }

  void _onResizeStart(DragStartDetails details) {
    if (!widget.enableResize || !widget.column.isResizable) return;

    setState(() {
      _isResizing = true;
      _startX = details.globalPosition.dx;
      _startWidth = widget.resizeController.getColumnWidth(
        widget.column.field,
        defaultWidth: widget.column.effectiveWidth,
      );
    });

    _resizeAnimationController.forward();
    HapticFeedback.selectionClick();
  }

  void _onResizeUpdate(DragUpdateDetails details) {
    if (!_isResizing) return;

    final deltaX = details.globalPosition.dx - _startX;
    final newWidth = _startWidth + deltaX;

    widget.resizeController.setColumnWidth(widget.column.field, newWidth);
  }

  void _onResizeEnd(DragEndDetails details) {
    if (!_isResizing) return;

    setState(() {
      _isResizing = false;
    });

    _resizeAnimationController.reverse();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.resizeController,
      builder: (context, child) {
        final currentWidth = widget.resizeController.getColumnWidth(
          widget.column.field,
          defaultWidth: widget.column.effectiveWidth,
        );

        return AnimatedBuilder(
          animation: Listenable.merge([_resizeLineOpacity, _hoverScale]),
          builder: (context, child) {
            return Transform.scale(
              scale: _hoverScale.value,
              child: SizedBox(
                width: currentWidth,
                height: widget.density.headerHeight,
                child: Stack(
                  children: [
                    // Conteúdo principal da célula
                    Positioned.fill(
                      right: (widget.enableResize && widget.column.isResizable) ? 8 : 0,
                      child: _buildMainContent(),
                    ),

                    // Resize handle (só se resizable)
                    if (widget.enableResize && widget.column.isResizable)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: 8,
                        child: _buildResizeHandle(),
                      ),

                    // Linha de preview durante resize
                    if (_isResizing)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: 2,
                        child: AnimatedBuilder(
                          animation: _resizeLineOpacity,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _resizeLineOpacity.value,
                              child: Container(
                                color: widget.colors.primary,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: widget.colors.primary,
                                    borderRadius: BorderRadius.circular(1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.colors.primary.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMainContent() {
    final filterOption = widget.columnFilters
        .where((f) => f.field == widget.column.field)
        .firstOrNull;

    return _buildHeaderContainer(filterOption);
  }

  Widget _buildHeaderContainer(ColumnFilterOption<T>? filterOption) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHoveringCell = true;
        });
        if (!_isResizing) _hoverAnimationController.forward();
      },
      onExit: (_) {
        setState(() {
          _isHoveringCell = false;
        });
        if (!_isResizing) _hoverAnimationController.reverse();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: widget.density.headerHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _isHoveringCell
              ? widget.colors.surfaceVariant.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: _isHoveringCell
              ? Border.all(color: widget.colors.outline.withValues(alpha: 0.5), width: 1)
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: _buildHeaderContent(filterOption),
      ),
    );
  }

  Widget _buildHeaderContent(ColumnFilterOption<T>? filterOption) {
    final sortDirection = _currentSortDirection;
    final isSorted = sortDirection != null;
    final priority = _sortPriority;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Conteúdo principal - Texto + Sort
        Expanded(
          child: GestureDetector(
            onTap: widget.column.sortable ? _handleSort : null,
            child: MouseRegion(
              cursor: widget.column.sortable
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              child: Container(
                height: double.infinity,
                alignment: widget.column.alignment,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Texto do label
                    Expanded(
                      child: Text(
                        widget.column.label,
                        style: TextStyle(
                          fontSize: widget.density.headerFontSize,
                          fontWeight: FontWeight.w600,
                          color: isSorted ? widget.colors.primary : widget.colors.onSurface,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: _getTextAlign(),
                      ),
                    ),

                    // Ícone de sort
                    if (widget.column.sortable) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        child: Icon(
                          isSorted
                              ? (sortDirection
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward)
                              : Icons.unfold_more,
                          size: 14,
                          color: isSorted ? widget.colors.primary : widget.colors.onSurfaceVariant,
                        ),
                      ),
                      // Badge de prioridade quando a coluna participa de um
                      // multi-sort (≥ 2 colunas ativas).
                      if (priority != null) ...[
                        const SizedBox(width: 2),
                        _SortPriorityBadge(
                          priority: priority,
                          colors: widget.colors,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // Filtro (se disponível)
        if (filterOption != null) ...[
          const SizedBox(width: 4),
          SizedBox(
            width: 20,
            height: 20,
            child: HeaderColumnFilter(
              filterOption: filterOption,
              currentValue: widget.columnFiltersState[widget.column.field],
              onFilterChanged: widget.onColumnFilterChanged,
              colors: widget.colors,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResizeHandle() {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) {
        setState(() {
          _isHoveringResize = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHoveringResize = false;
        });
      },
      child: GestureDetector(
        onPanStart: _onResizeStart,
        onPanUpdate: _onResizeUpdate,
        onPanEnd: _onResizeEnd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 8,
          height: double.infinity,
          decoration: BoxDecoration(
            color: _isHoveringResize || _isResizing
                ? widget.colors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 2,
              height: _isHoveringResize || _isResizing ? 24 : 16,
              decoration: BoxDecoration(
                color: _isHoveringResize || _isResizing
                    ? widget.colors.primary
                    : widget.colors.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextAlign _getTextAlign() {
    switch (widget.column.alignment) {
      case Alignment.centerLeft:
        return TextAlign.left;
      case Alignment.center:
        return TextAlign.center;
      case Alignment.centerRight:
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }
}

/// Small numeric badge rendered next to a sorted column's direction icon
/// when the table is being sorted by ≥ 2 columns at once. Tells the user
/// the priority of this column inside the sort stack (1 = primary,
/// 2 = tie-breaker, etc.).
class _SortPriorityBadge extends StatelessWidget {
  final int priority;
  final DataTableColorScheme colors;

  const _SortPriorityBadge({
    required this.priority,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 14),
      height: 14,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.toString(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: colors.onPrimary,
          height: 1,
        ),
      ),
    );
  }
}