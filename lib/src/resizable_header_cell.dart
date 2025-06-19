import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:innovare_data_table/src/data_column_config.dart';
import 'package:innovare_data_table/src/data_table_filters.dart';
import 'package:innovare_data_table/src/data_table_theme.dart';

// Controller para gerenciar larguras das colunas
class ColumnResizeController extends ChangeNotifier {
  final Map<String, double> _columnWidths = {};
  final Map<String, double> _minWidths = {};
  final Map<String, double> _maxWidths = {};

  // Configurar largura de uma coluna
  void setColumnWidth(String field, double width) {
    final minWidth = _minWidths[field] ?? 80.0;
    final maxWidth = _maxWidths[field] ?? 500.0;

    _columnWidths[field] = width.clamp(minWidth, maxWidth);
    notifyListeners();
  }

  // Obter largura atual de uma coluna
  double getColumnWidth(String field, {double defaultWidth = 200.0}) {
    return _columnWidths[field] ?? defaultWidth;
  }

  // Configurar limites de uma coluna
  void setColumnLimits(String field, {double? minWidth, double? maxWidth}) {
    if (minWidth != null) _minWidths[field] = minWidth;
    if (maxWidth != null) _maxWidths[field] = maxWidth;
  }

  // Resetar largura de uma coluna
  void resetColumnWidth(String field) {
    _columnWidths.remove(field);
    notifyListeners();
  }

  // Resetar todas as larguras
  void resetAllWidths() {
    _columnWidths.clear();
    notifyListeners();
  }

  // Obter todas as larguras (para persistência)
  Map<String, double> getAllWidths() => Map.from(_columnWidths);

  // Restaurar larguras (de persistência)
  void restoreWidths(Map<String, double> widths) {
    _columnWidths.clear();
    _columnWidths.addAll(widths);
    notifyListeners();
  }
}

// Componente principal com redimensionamento
class ResizableHeaderCell<T> extends StatefulWidget {
  final DataColumnConfig<T> column;
  final int index;
  final InnovareDataTableThemeData theme;
  final DataTableColorScheme colors;
  final DensityConfig density;
  final List<ColumnFilterOption<T>> columnFilters;
  final Map<String, dynamic> columnFiltersState;
  final Function(String, dynamic) onColumnFilterChanged;
  final Function(int fromIndex, int toIndex) onColumnReorder;
  final ColumnResizeController resizeController;
  final bool enableDragDrop;
  final bool enableResize;

  // Parâmetros para sort
  final String? currentSortField;
  final bool isAscending;
  final Function(String field, bool ascending)? onSort;

  const ResizableHeaderCell({
    super.key,
    required this.column,
    required this.index,
    required this.theme,
    required this.colors,
    required this.density,
    required this.columnFilters,
    required this.columnFiltersState,
    required this.onColumnFilterChanged,
    required this.onColumnReorder,
    required this.resizeController,
    this.enableDragDrop = true,
    this.enableResize = true,
    this.currentSortField,
    this.isAscending = true,
    this.onSort,
  });

  @override
  State<ResizableHeaderCell<T>> createState() => _ResizableHeaderCellState<T>();
}

class _ResizableHeaderCellState<T> extends State<ResizableHeaderCell<T>>
    with TickerProviderStateMixin {

  bool _isResizing = false;
  bool _isHoveringResize = false;
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
    _setupColumnLimits();
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

    _hoverScale = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverAnimationController, curve: Curves.easeOut),
    );
  }

  void _setupColumnLimits() {
    // Configurar limites baseados no tipo de dados
    final minWidth = widget.column.width != null ? widget.column.width! * 0.5 : 80.0;
    final maxWidth = widget.column.width != null ? widget.column.width! * 2.0 : 500.0;

    widget.resizeController.setColumnLimits(
      widget.column.field,
      minWidth: minWidth,
      maxWidth: maxWidth,
    );
  }

  @override
  void dispose() {
    _resizeAnimationController.dispose();
    _hoverAnimationController.dispose();
    super.dispose();
  }

  void _handleSort() {
    if (!widget.column.sortable || widget.onSort == null) return;

    final isSorted = widget.currentSortField == widget.column.field;
    final newAscending = isSorted ? !widget.isAscending : true;

    widget.onSort!(widget.column.field, newAscending);
  }

  void _onResizeStart(DragStartDetails details) {
    if (!widget.enableResize) return;

    setState(() {
      _isResizing = true;
      _startX = details.globalPosition.dx;
      _startWidth = widget.resizeController.getColumnWidth(
        widget.column.field,
        defaultWidth: widget.theme.columnWidth ?? 200.0,
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
          defaultWidth: widget.theme.columnWidth ?? 200.0,
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
                      right: widget.enableResize ? 8 : 0, // Espaço para resize handle
                      child: _buildMainContent(),
                    ),

                    // Resize handle
                    if (widget.enableResize)
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
                                        color: widget.colors.primary.withOpacity(0.3),
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

    return widget.enableDragDrop
        ? _buildDraggableContent(filterOption)
        : _buildStaticContent(filterOption);
  }

  Widget _buildDraggableContent(ColumnFilterOption<T>? filterOption) {
    return DragTarget<int>(
      onWillAccept: (fromIndex) => fromIndex != null && fromIndex != widget.index,
      onAccept: (fromIndex) {
        widget.onColumnReorder(fromIndex, widget.index);
        HapticFeedback.mediumImpact();
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Draggable<int>(
          data: widget.index,
          feedback: _buildDragFeedback(),
          childWhenDragging: _buildPlaceholder(),
          onDragStarted: () => HapticFeedback.lightImpact(),
          onDragEnd: (details) => HapticFeedback.selectionClick(),
          child: _buildHeaderContainer(filterOption, isHovering),
        );
      },
    );
  }

  Widget _buildStaticContent(ColumnFilterOption<T>? filterOption) {
    return _buildHeaderContainer(filterOption, false);
  }

  Widget _buildHeaderContainer(ColumnFilterOption<T>? filterOption, bool isHovering) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: widget.density.headerHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isHovering
            ? widget.colors.primaryLight.withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isHovering
            ? Border.all(color: widget.colors.primary.withOpacity(0.5), width: 2)
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: _buildHeaderContent(filterOption),
    );
  }

  Widget _buildHeaderContent(ColumnFilterOption<T>? filterOption) {
    final isSorted = widget.currentSortField == widget.column.field;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Ícone de drag (se habilitado)
        if (widget.enableDragDrop) ...[
          MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              child: Icon(
                Icons.drag_indicator,
                size: 16,
                color: widget.colors.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],

        // Conteúdo principal - Texto + Sort
        Expanded(
          child: GestureDetector(
            onTap: widget.column.sortable ? _handleSort : null,
            child: MouseRegion(
              cursor: widget.column.sortable
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              onEnter: (_) {
                if (!_isResizing) _hoverAnimationController.forward();
              },
              onExit: (_) {
                if (!_isResizing) _hoverAnimationController.reverse();
              },
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
                              ? (widget.isAscending ? Icons.arrow_upward : Icons.arrow_downward)
                              : Icons.unfold_more,
                          size: 14,
                          color: isSorted ? widget.colors.primary : widget.colors.onSurfaceVariant,
                        ),
                      ),
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
                ? widget.colors.primary.withOpacity(0.1)
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
                    : widget.colors.onSurfaceVariant.withOpacity(0.3),
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

  Widget _buildDragFeedback() {
    final currentWidth = widget.resizeController.getColumnWidth(
      widget.column.field,
      defaultWidth: widget.theme.columnWidth ?? 200.0,
    );

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: currentWidth,
        height: widget.density.headerHeight + 4,
        decoration: BoxDecoration(
          color: widget.colors.primary,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: widget.colors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.open_with,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.column.label,
                    style: TextStyle(
                      fontSize: widget.density.headerFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final currentWidth = widget.resizeController.getColumnWidth(
      widget.column.field,
      defaultWidth: widget.theme.columnWidth ?? 200.0,
    );

    return Container(
      height: widget.density.headerHeight,
      width: currentWidth,
      decoration: BoxDecoration(
        color: widget.colors.surface,
        border: Border.all(
          color: widget.colors.primary.withOpacity(0.5),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.drag_handle,
          color: widget.colors.primary.withOpacity(0.7),
          size: 20,
        ),
      ),
    );
  }
}