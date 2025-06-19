import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:innovare_data_table/src/data_column_config.dart';
import 'package:innovare_data_table/src/data_table_filters.dart';
import 'package:innovare_data_table/src/data_table_responsive.dart';
import 'package:innovare_data_table/src/data_table_theme.dart';

class DragDropColumnState<T> {
  final List<DataColumnConfig<T>> orderedColumns;
  final int? draggingIndex;
  final int? hoverIndex;
  final bool isDragging;

  const DragDropColumnState({
    required this.orderedColumns,
    this.draggingIndex,
    this.hoverIndex,
    this.isDragging = false,
  });

  DragDropColumnState<T> copyWith({
    List<DataColumnConfig<T>>? orderedColumns,
    int? draggingIndex,
    int? hoverIndex,
    bool? isDragging,
  }) {
    return DragDropColumnState<T>(
      orderedColumns: orderedColumns ?? this.orderedColumns,
      draggingIndex: draggingIndex ?? this.draggingIndex,
      hoverIndex: hoverIndex ?? this.hoverIndex,
      isDragging: isDragging ?? this.isDragging,
    );
  }
}

class DraggableHeaderCell<T> extends StatefulWidget {
  final DataColumnConfig<T> column;
  final int index;
  final InnovareDataTableThemeData theme;
  final DataTableColorScheme colors;
  final DensityConfig density;
  final List<ColumnFilterOption<T>> columnFilters;
  final Map<String, dynamic> columnFiltersState;
  final Function(String, dynamic) onColumnFilterChanged;
  final Function(int fromIndex, int toIndex) onColumnReorder;
  final bool isDragging;
  final bool isHovering;
  final bool enableDragDrop;

  // Parâmetros para sort
  final String? currentSortField;
  final bool isAscending;
  final Function(String field, bool ascending)? onSort;

  const DraggableHeaderCell({
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
    this.isDragging = false,
    this.isHovering = false,
    this.enableDragDrop = true,
    this.currentSortField,
    this.isAscending = true,
    this.onSort,
  });

  @override
  State<DraggableHeaderCell<T>> createState() => _DraggableHeaderCellState<T>();
}

class _DraggableHeaderCellState<T> extends State<DraggableHeaderCell<T>> {

  void _handleSort() {
    if (!widget.column.sortable || widget.onSort == null) return;

    final isSorted = widget.currentSortField == widget.column.field;
    final newAscending = isSorted ? !widget.isAscending : true;

    widget.onSort!(widget.column.field, newAscending);
  }

  @override
  Widget build(BuildContext context) {
    final responsiveWidth = ResponsiveTableManager.getColumnWidth(
      context,
      customWidth: widget.theme.columnWidth,
    );

    final filterOption = widget.columnFilters
        .where((f) => f.field == widget.column.field)
        .firstOrNull;

    // GARANTIR ALTURA MÍNIMA SEMPRE
    return SizedBox(
      width: responsiveWidth,
      height: widget.density.headerHeight, // ← ALTURA FIXA GARANTIDA
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: widget.enableDragDrop
            ? _buildDraggableWrapper(filterOption, responsiveWidth)
            : _buildSimpleHeader(filterOption),
      ),
    );
  }

  Widget _buildDraggableWrapper(ColumnFilterOption<T>? filterOption, double width) {
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
          feedback: _buildDragFeedback(width),
          childWhenDragging: _buildPlaceholder(),
          onDragStarted: () => HapticFeedback.lightImpact(),
          onDragEnd: (details) => HapticFeedback.selectionClick(),
          child: _buildHeaderContainer(filterOption, isHovering),
        );
      },
    );
  }

  Widget _buildSimpleHeader(ColumnFilterOption<T>? filterOption) {
    return _buildHeaderContainer(filterOption, false);
  }

  // CONTAINER PRINCIPAL DO HEADER - COM ALTURA GARANTIDA
  Widget _buildHeaderContainer(ColumnFilterOption<T>? filterOption, bool isHovering) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: widget.density.headerHeight, // ← ALTURA EXPLÍCITA
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

  // CONTEÚDO DO HEADER - CENTRALIZADO VERTICALMENTE
  Widget _buildHeaderContent(ColumnFilterOption<T>? filterOption) {
    final isSorted = widget.currentSortField == widget.column.field;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // ← CENTRALIZAR VERTICALMENTE
      children: [
        // 1. ÍCONE DE DRAG (se habilitado)
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

        // 2. CONTEÚDO PRINCIPAL - TEXTO + SORT
        Expanded(
          child: GestureDetector(
            onTap: widget.column.sortable ? _handleSort : null,
            child: MouseRegion(
              cursor: widget.column.sortable
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              child: Container(
                height: double.infinity, // ← OCUPAR TODA ALTURA DISPONÍVEL
                alignment: widget.column.alignment, // ← USAR ALINHAMENTO DA COLUNA
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // TEXTO DO LABEL - SEMPRE VISÍVEL
                    Expanded(
                      child: Text(
                        widget.column.label,
                        style: TextStyle(
                          fontSize: widget.density.headerFontSize,
                          fontWeight: FontWeight.w600,
                          color: isSorted ? widget.colors.primary : widget.colors.onSurface,
                          height: 1.2, // ← ALTURA DE LINHA CONTROLADA
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: _getTextAlign(),
                      ),
                    ),

                    // ÍCONE DE SORT (se sortable)
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

        // 3. FILTRO (se disponível)
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

  // HELPER PARA ALINHAMENTO DE TEXTO
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

  Widget _buildDragFeedback(double width) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: widget.density.headerHeight + 4, // ← ALTURA CONSISTENTE
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
        child: Center( // ← CENTRALIZAR CONTEÚDO
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
    return Container(
      height: widget.density.headerHeight, // ← ALTURA CONSISTENTE
      width: double.infinity,
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

// Classe DashBorder simplificada (mantida para compatibilidade)
class DashBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double dashLength;

  const DashBorder({
    super.key,
    required this.child,
    required this.color,
    this.strokeWidth = 1,
    this.dashLength = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: strokeWidth),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}

class DashBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;

  DashBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ));

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0;
      while (distance < pathMetric.length) {
        final nextDistance = distance + dashLength;
        final isGap = ((distance / dashLength) % 2).round() == 1;
        if (!isGap) {
          canvas.drawPath(
            pathMetric.extractPath(distance, nextDistance.clamp(0, pathMetric.length)),
            paint,
          );
        }
        distance = nextDistance;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}