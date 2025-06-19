import 'package:flutter/material.dart';
import 'package:innovare_data_table/src/data_column_config.dart';
import 'package:innovare_data_table/src/data_table_filters.dart';
import 'package:innovare_data_table/src/data_table_theme.dart';
import 'package:innovare_data_table/src/pure_resizable_header_cell.dart';
import 'package:innovare_data_table/src/resizable_header_cell.dart';

// GERENCIADOR DE COLUNAS STICKY (MELHORADO)
class StickyColumnManager<T> {
  static StickyColumnSplit<T> splitColumns<T>(List<DataColumnConfig<T>> columns) {
    final leftSticky = <DataColumnConfig<T>>[];
    final center = <DataColumnConfig<T>>[];
    final rightSticky = <DataColumnConfig<T>>[];

    for (final column in columns) {
      switch (column.stickyPosition) {
        case StickyPosition.left:
          leftSticky.add(column);
          break;
        case StickyPosition.right:
          rightSticky.add(column);
          break;
        case StickyPosition.none:
        default:
          center.add(column);
          break;
      }
    }

    // Ordenar por zIndex
    leftSticky.sort((a, b) => a.stickyZIndex.compareTo(b.stickyZIndex));
    rightSticky.sort((a, b) => a.stickyZIndex.compareTo(b.stickyZIndex));

    return StickyColumnSplit(
      leftSticky: leftSticky,
      center: center,
      rightSticky: rightSticky,
    );
  }

  static double calculateTotalWidth<T>(
      List<DataColumnConfig<T>> columns,
      ColumnResizeController resizeController,
      ) {
    double total = 0;
    for (final column in columns) {
      total += resizeController.getColumnWidth(
        column.field,
        defaultWidth: column.effectiveWidth,
      );
    }
    return total;
  }

  // ✨ NOVO: Calcular largura das áreas sticky
  static double calculateStickyWidth<T>(
      List<DataColumnConfig<T>> columns,
      ColumnResizeController resizeController,
      ) {
    double total = 0;
    for (final column in columns) {
      total += resizeController.getColumnWidth(
        column.field,
        defaultWidth: column.effectiveWidth,
      );
    }
    return total;
  }
}

// CLASSE PARA DIVISÃO DAS COLUNAS
class StickyColumnSplit<T> {
  final List<DataColumnConfig<T>> leftSticky;
  final List<DataColumnConfig<T>> center;
  final List<DataColumnConfig<T>> rightSticky;

  const StickyColumnSplit({
    required this.leftSticky,
    required this.center,
    required this.rightSticky,
  });

  bool get hasLeftSticky => leftSticky.isNotEmpty;
  bool get hasRightSticky => rightSticky.isNotEmpty;
  bool get hasCenter => center.isNotEmpty;
}

// WIDGET PRINCIPAL DA TABELA STICKY (CORRIGIDO)
class StickyDataTable<T> extends StatefulWidget {
  final List<DataColumnConfig<T>> columns;
  final List<T> rows;
  final InnovareDataTableThemeData theme;
  final DataTableColorScheme colors;
  final DensityConfig density;
  final ColumnResizeController resizeController;
  final bool enableSelection;
  final Set<T> selectedItems;
  final Function(T item)? onSelectionChanged;
  final Function(List<T> items)? onSelectAll;
  final bool enableColumnResize;
  final bool enableColumnDragDrop;
  final Function(int fromIndex, int toIndex)? onColumnReorder;

  // Parâmetros para sort e filtros
  final String? currentSortField;
  final bool isAscending;
  final Function(String field, bool ascending)? onSort;
  final List<ColumnFilterOption<T>> columnFilters;
  final Map<String, dynamic> columnFiltersState;
  final Function(String, dynamic) onColumnFilterChanged;

  const StickyDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.theme,
    required this.colors,
    required this.density,
    required this.resizeController,
    this.enableSelection = false,
    this.selectedItems = const {},
    this.onSelectionChanged,
    this.onSelectAll,
    this.enableColumnResize = true,
    this.enableColumnDragDrop = false,
    this.onColumnReorder,
    this.currentSortField,
    this.isAscending = true,
    this.onSort,
    this.columnFilters = const [],
    this.columnFiltersState = const {},
    required this.onColumnFilterChanged,
  });

  @override
  State<StickyDataTable<T>> createState() => _StickyDataTableState<T>();
}

// SUBSTITUIR COMPLETAMENTE A CLASSE _StickyDataTableState NO innovare_stick_data_table.dart

// SUBSTITUIR COMPLETAMENTE A CLASSE _StickyDataTableState NO innovare_stick_data_table.dart

class _StickyDataTableState<T> extends State<StickyDataTable<T>> {
  // ✨ CONTROLLERS DE SCROLL
  late ScrollController _horizontalHeaderController;
  late ScrollController _horizontalBodyController;
  late ScrollController _verticalScrollController;

  // ✨ NOVOS: Controllers de scroll vertical para cada seção
  late ScrollController _leftStickyScrollController;
  late ScrollController _rightStickyScrollController;
  late ScrollController _selectionScrollController;

  bool _showLeftShadow = false;
  bool _showRightShadow = false;

  // ✨ CACHE PARA LARGURAS (PERFORMANCE)
  double? _cachedLeftStickyWidth;
  double? _cachedRightStickyWidth;
  double? _cachedCenterWidth;
  double? _cachedSelectionWidth;

  // ✨ DECISÃO DE UX: O scrollbar vertical só aparece:
  // - Na área central (sempre)
  // - No sticky right (onde o usuário interage frequentemente)
  // - Não aparece no sticky left nem na seleção (para design mais limpo)

  // ✨ CONFIGURAÇÃO DE VISIBILIDADE DOS SCROLLBARS (pode ser customizada no futuro)
  final bool _showScrollbarInSelection = false;
  final bool _showScrollbarInLeftSticky = false;
  final bool _showScrollbarInRightSticky = true;
  final bool _showScrollbarInCenter = true;

  @override
  void initState() {
    super.initState();

    // ✨ INICIALIZAR TODOS OS CONTROLLERS
    _horizontalHeaderController = ScrollController();
    _horizontalBodyController = ScrollController();
    _verticalScrollController = ScrollController();

    // ✨ NOVOS CONTROLLERS PARA SINCRONIZAÇÃO VERTICAL
    _leftStickyScrollController = ScrollController();
    _rightStickyScrollController = ScrollController();
    _selectionScrollController = ScrollController();

    // ✨ SINCRONIZAR SCROLL HORIZONTAL
    _horizontalHeaderController.addListener(_onHeaderScroll);
    _horizontalBodyController.addListener(_onBodyScroll);

    // ✨ SINCRONIZAR SCROLL VERTICAL ENTRE TODAS AS SEÇÕES
    _verticalScrollController.addListener(_syncVerticalScroll);

    // ✨ ESCUTAR MUDANÇAS NO RESIZE CONTROLLER
    widget.resizeController.addListener(_onResizeChanged);

    // ✨ VERIFICAR STATUS DO SCROLL APÓS BUILD INICIAL
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollStatus();
    });
  }

  @override
  void dispose() {
    // ✨ REMOVER TODOS OS LISTENERS
    _horizontalHeaderController.removeListener(_onHeaderScroll);
    _horizontalBodyController.removeListener(_onBodyScroll);
    _verticalScrollController.removeListener(_syncVerticalScroll);
    widget.resizeController.removeListener(_onResizeChanged);

    // ✨ DISPOSE DE TODOS OS CONTROLLERS
    _horizontalHeaderController.dispose();
    _horizontalBodyController.dispose();
    _verticalScrollController.dispose();
    _leftStickyScrollController.dispose();
    _rightStickyScrollController.dispose();
    _selectionScrollController.dispose();

    super.dispose();
  }

  // ✨ NOVO: SINCRONIZAR SCROLL VERTICAL ENTRE TODAS AS SEÇÕES
  void _syncVerticalScroll() {
    if (!mounted) return;

    final offset = _verticalScrollController.offset;

    // Sincronizar com seção de seleção
    if (_selectionScrollController.hasClients &&
        (_selectionScrollController.offset - offset).abs() > 0.5) {
      _selectionScrollController.jumpTo(offset);
    }

    // Sincronizar com sticky left
    if (_leftStickyScrollController.hasClients &&
        (_leftStickyScrollController.offset - offset).abs() > 0.5) {
      _leftStickyScrollController.jumpTo(offset);
    }

    // Sincronizar com sticky right
    if (_rightStickyScrollController.hasClients &&
        (_rightStickyScrollController.offset - offset).abs() > 0.5) {
      _rightStickyScrollController.jumpTo(offset);
    }
  }

  // ✨ LISTENERS PARA SINCRONIZAR DE VOLTA AO CONTROLLER PRINCIPAL
  void _onSelectionScroll() {
    if (!mounted || !_selectionScrollController.hasClients) return;

    final offset = _selectionScrollController.offset;
    if (_verticalScrollController.hasClients &&
        (_verticalScrollController.offset - offset).abs() > 0.5) {
      _verticalScrollController.jumpTo(offset);
    }
  }

  void _onLeftStickyScroll() {
    if (!mounted || !_leftStickyScrollController.hasClients) return;

    final offset = _leftStickyScrollController.offset;
    if (_verticalScrollController.hasClients &&
        (_verticalScrollController.offset - offset).abs() > 0.5) {
      _verticalScrollController.jumpTo(offset);
    }
  }

  void _onRightStickyScroll() {
    if (!mounted || !_rightStickyScrollController.hasClients) return;

    final offset = _rightStickyScrollController.offset;
    if (_verticalScrollController.hasClients &&
        (_verticalScrollController.offset - offset).abs() > 0.5) {
      _verticalScrollController.jumpTo(offset);
    }
  }

  // ✨ SINCRONIZAÇÃO: HEADER -> BODY
  void _onHeaderScroll() {
    if (!mounted) return;

    if (_horizontalBodyController.hasClients &&
        _horizontalHeaderController.hasClients) {

      final headerOffset = _horizontalHeaderController.offset;
      if (_horizontalBodyController.offset != headerOffset) {
        _horizontalBodyController.jumpTo(headerOffset);
      }
    }

    _updateShadows();
  }

  // ✨ SINCRONIZAÇÃO: BODY -> HEADER
  void _onBodyScroll() {
    if (!mounted) return;

    if (_horizontalHeaderController.hasClients &&
        _horizontalBodyController.hasClients) {

      final bodyOffset = _horizontalBodyController.offset;
      if (_horizontalHeaderController.offset != bodyOffset) {
        _horizontalHeaderController.jumpTo(bodyOffset);
      }
    }

    _updateShadows();
  }

  // ✨ ATUALIZAR SOMBRAS BASEADO NO SCROLL
  void _updateShadows() {
    if (!_horizontalBodyController.hasClients) return;

    final position = _horizontalBodyController.position;
    final needsScroll = position.maxScrollExtent > 0;

    if (!needsScroll) {
      if (_showLeftShadow || _showRightShadow) {
        setState(() {
          _showLeftShadow = false;
          _showRightShadow = false;
        });
      }
      return;
    }

    final newShowLeftShadow = position.pixels > 10;
    final newShowRightShadow = position.pixels < (position.maxScrollExtent - 10);

    if (newShowLeftShadow != _showLeftShadow || newShowRightShadow != _showRightShadow) {
      setState(() {
        _showLeftShadow = newShowLeftShadow;
        _showRightShadow = newShowRightShadow;
      });
    }
  }

  // ✨ CALLBACK PARA MUDANÇAS DE RESIZE
  void _onResizeChanged() {
    setState(() {
      // Limpar cache das larguras
      _cachedLeftStickyWidth = null;
      _cachedRightStickyWidth = null;
      _cachedCenterWidth = null;
    });

    // Verificar scroll após mudança de tamanho
    _checkScrollStatus();
  }

  // ✨ ATUALIZAR O didUpdateWidget
  @override
  void didUpdateWidget(StickyDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Se as colunas mudaram, limpar cache e forçar atualização
    if (oldWidget.columns != widget.columns) {
      _cachedLeftStickyWidth = null;
      _cachedRightStickyWidth = null;
      _cachedCenterWidth = null;
      _cachedSelectionWidth = null;

      // Forçar atualização do scroll
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkScrollStatus();
        }
      });
    }
  }

  // ✨ MÉTODOS PARA CALCULAR LARGURAS COM CACHE
  double _getSelectionWidth() {
    return _cachedSelectionWidth ??= widget.enableSelection ? 60.0 : 0.0;
  }

  double _getLeftStickyWidth(StickyColumnSplit<T> columnSplit) {
    return _cachedLeftStickyWidth ??= columnSplit.hasLeftSticky
        ? StickyColumnManager.calculateStickyWidth(columnSplit.leftSticky, widget.resizeController)
        : 0.0;
  }

  double _getRightStickyWidth(StickyColumnSplit<T> columnSplit) {
    return _cachedRightStickyWidth ??= columnSplit.hasRightSticky
        ? StickyColumnManager.calculateStickyWidth(columnSplit.rightSticky, widget.resizeController)
        : 0.0;
  }

  double _getCenterWidth(StickyColumnSplit<T> columnSplit) {
    return _cachedCenterWidth ??= columnSplit.hasCenter
        ? StickyColumnManager.calculateTotalWidth(columnSplit.center, widget.resizeController)
        : 0.0;
  }

  // ✨ MÉTODO PARA VERIFICAR SE O SCROLL ESTÁ FUNCIONANDO
  void _checkScrollStatus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Adicionar listeners de sincronização após build
      if (_selectionScrollController.hasClients && !_selectionScrollController.hasListeners) {
        _selectionScrollController.addListener(_onSelectionScroll);
      }

      if (_leftStickyScrollController.hasClients && !_leftStickyScrollController.hasListeners) {
        _leftStickyScrollController.addListener(_onLeftStickyScroll);
      }

      if (_rightStickyScrollController.hasClients && !_rightStickyScrollController.hasListeners) {
        _rightStickyScrollController.addListener(_onRightStickyScroll);
      }

      // Debug logs
      if (_horizontalHeaderController.hasClients) {
        final headerPosition = _horizontalHeaderController.position;
        print('🔍 HEADER SCROLL: maxScrollExtent: ${headerPosition.maxScrollExtent}');
      }

      if (_horizontalBodyController.hasClients) {
        final bodyPosition = _horizontalBodyController.position;
        print('🔍 BODY SCROLL: maxScrollExtent: ${bodyPosition.maxScrollExtent}');

        if (bodyPosition.maxScrollExtent > 0) {
          print('✅ SCROLL ATIVO: Scroll horizontal disponível!');
          _updateShadows();
        } else {
          print('❌ SCROLL INATIVO: Sem scroll horizontal necessário');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final columnSplit = StickyColumnManager.splitColumns(widget.columns);

    return AnimatedBuilder(
      animation: widget.resizeController,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // ✨ CALCULAR LARGURAS NECESSÁRIAS
            final availableWidth = constraints.maxWidth;
            final selectionWidth = _getSelectionWidth();
            final leftStickyWidth = _getLeftStickyWidth(columnSplit);
            final rightStickyWidth = _getRightStickyWidth(columnSplit);
            final centerWidth = _getCenterWidth(columnSplit);

            // ✨ CALCULAR LARGURA DISPONÍVEL PARA A ÁREA CENTRAL
            final usedWidth = selectionWidth + leftStickyWidth + rightStickyWidth;
            final availableCenterWidth = (availableWidth - usedWidth).clamp(100.0, double.infinity);

            // ✨ VERIFICAR SE SCROLL É NECESSÁRIO
            final needsHorizontalScroll = centerWidth > availableCenterWidth;

            // ✨ DEBUG DETALHADO
            print('🔍 STICKY BUILD (Controllers Separados):');
            print('   Largura total: $availableWidth');
            print('   Seleção: $selectionWidth, Left: $leftStickyWidth, Right: $rightStickyWidth');
            print('   Centro precisa: $centerWidth, disponível: $availableCenterWidth');
            print('   Precisa scroll: $needsHorizontalScroll');

            // ✨ FORÇAR ATUALIZAÇÃO DO SCROLL APÓS RENDER
            if (needsHorizontalScroll) {
              _checkScrollStatus();
            }

            return Column(
              children: [
                _buildHeader(columnSplit, availableCenterWidth, needsHorizontalScroll),
                Expanded(
                  child: _buildBody(columnSplit, availableCenterWidth, needsHorizontalScroll),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(StickyColumnSplit<T> columnSplit, double availableCenterWidth, bool needsScroll) {
    return Container(
      height: widget.density.headerHeight,
      decoration: BoxDecoration(
        color: widget.colors.surfaceVariant,
        border: Border(bottom: BorderSide(color: widget.colors.outline, width: 0.5)),
      ),
      child: Row(
        children: [
          // SELEÇÃO (se habilitada)
          if (widget.enableSelection)
            _buildSelectionHeader(),

          // COLUNAS STICKY LEFT
          if (columnSplit.hasLeftSticky)
            _buildStickyHeaderSection(
              columnSplit.leftSticky,
              StickyPosition.left,
            ),

          // ✨ ÁREA CENTRAL COM SCROLL - LARGURA CONTROLADA
          if (columnSplit.hasCenter)
            SizedBox(
              width: availableCenterWidth,
              child: _buildScrollableHeaderSection(columnSplit.center, needsScroll),
            ),

          // COLUNAS STICKY RIGHT
          if (columnSplit.hasRightSticky)
            _buildStickyHeaderSection(
              columnSplit.rightSticky,
              StickyPosition.right,
            ),
        ],
      ),
    );
  }

  Widget _buildBody(StickyColumnSplit<T> columnSplit, double availableCenterWidth, bool needsScroll) {
    return Row(
      children: [
        // SELEÇÃO (se habilitada)
        if (widget.enableSelection)
          _buildSelectionBody(),

        // COLUNAS STICKY LEFT
        if (columnSplit.hasLeftSticky)
          _buildStickyBodySection(
            columnSplit.leftSticky,
            StickyPosition.left,
          ),

        // ✨ ÁREA CENTRAL COM SCROLL - LARGURA CONTROLADA
        if (columnSplit.hasCenter)
          SizedBox(
            width: availableCenterWidth,
            child: _buildScrollableBodySection(columnSplit.center, needsScroll),
          ),

        // COLUNAS STICKY RIGHT
        if (columnSplit.hasRightSticky)
          _buildStickyBodySection(
            columnSplit.rightSticky,
            StickyPosition.right,
          ),
      ],
    );
  }

  Widget _buildSelectionHeader() {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: widget.colors.surfaceVariant,
        boxShadow: _showLeftShadow ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ] : null,
      ),
      child: Center(
        child: Checkbox(
          value: widget.rows.every(widget.selectedItems.contains) && widget.rows.isNotEmpty,
          onChanged: (_) => widget.onSelectAll?.call(widget.rows),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildSelectionBody() {
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: widget.colors.surface,
        boxShadow: _showLeftShadow ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ] : null,
      ),
      child: ScrollConfiguration(
        // ✨ CONFIGURAÇÃO CONDICIONAL DO SCROLLBAR
        behavior: _showScrollbarInSelection
            ? const ScrollBehavior()
            : const ScrollBehavior().copyWith(scrollbars: false),
        child: ListView.builder(
          controller: _selectionScrollController, // ✨ USAR CONTROLLER ESPECÍFICO
          itemCount: widget.rows.length,
          itemBuilder: (context, index) {
            final item = widget.rows[index];
            final isSelected = widget.selectedItems.contains(item);

            return Container(
              height: widget.density.rowHeight,
              decoration: BoxDecoration(
                color: isSelected
                    ? widget.colors.primaryLight
                    : index.isEven
                    ? widget.colors.surface
                    : widget.colors.surfaceVariant.withOpacity(0.3),
                border: Border(bottom: BorderSide(
                  color: widget.colors.outline.withOpacity(0.3),
                  width: 0.5,
                )),
              ),
              child: Center(
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => widget.onSelectionChanged?.call(item),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStickyHeaderSection(
      List<DataColumnConfig<T>> columns,
      StickyPosition position,
      ) {
    final width = StickyColumnManager.calculateTotalWidth(columns, widget.resizeController);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: widget.colors.surfaceVariant,
        boxShadow: _getStickyHeaderShadow(position),
      ),
      child: Row(
        children: columns.asMap().entries.map((entry) {
          final index = entry.key;
          final column = entry.value;

          return _buildHeaderCell(column, index, true);
        }).toList(),
      ),
    );
  }

  Widget _buildStickyBodySection(
      List<DataColumnConfig<T>> columns,
      StickyPosition position,
      ) {
    final width = StickyColumnManager.calculateTotalWidth(columns, widget.resizeController);

    // ✨ USAR CONTROLLER ESPECÍFICO BASEADO NA POSIÇÃO
    final scrollController = position == StickyPosition.left
        ? _leftStickyScrollController
        : _rightStickyScrollController;

    // ✨ DETERMINAR SE DEVE MOSTRAR SCROLLBAR
    final showScrollbar = position == StickyPosition.left
        ? _showScrollbarInLeftSticky
        : _showScrollbarInRightSticky;

    return Container(
      width: width,
      decoration: BoxDecoration(
        boxShadow: _getStickyBodyShadow(position),
      ),
      child: ScrollConfiguration(
        // ✨ CONFIGURAÇÃO CONDICIONAL DO SCROLLBAR
        behavior: showScrollbar
            ? const ScrollBehavior()
            : const ScrollBehavior().copyWith(scrollbars: false),
        child: ListView.builder(
          controller: scrollController, // ✨ USAR CONTROLLER ESPECÍFICO
          itemCount: widget.rows.length,
          itemBuilder: (context, index) {
            final item = widget.rows[index];
            final isSelected = widget.selectedItems.contains(item);

            return Container(
              height: widget.density.rowHeight,
              decoration: BoxDecoration(
                color: isSelected
                    ? widget.colors.primaryLight
                    : index.isEven
                    ? widget.colors.surface
                    : widget.colors.surfaceVariant.withOpacity(0.3),
                border: Border(bottom: BorderSide(
                  color: widget.colors.outline.withOpacity(0.3),
                  width: 0.5,
                )),
              ),
              child: Row(
                children: columns.map((column) {
                  final columnWidth = widget.resizeController.getColumnWidth(
                    column.field,
                    defaultWidth: column.effectiveWidth,
                  );

                  return _buildBodyCell(column, item, columnWidth);
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  // ✨ ATUALIZAR _buildScrollableHeaderSection PARA USAR CONTROLLER ESPECÍFICO
  Widget _buildScrollableHeaderSection(List<DataColumnConfig<T>> columns, bool forceScroll) {
    final totalCenterWidth = StickyColumnManager.calculateTotalWidth(columns, widget.resizeController);

    return Container(
      height: widget.density.headerHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;

          print('🔍 HEADER SECTION: Total: $totalCenterWidth, Available: $availableWidth, Force: $forceScroll');

          return ClipRect(
            child: Stack(
              children: [
                // ✨ USAR CONTROLLER ESPECÍFICO DO HEADER
                Scrollbar(
                  controller: _horizontalHeaderController, // ← CONTROLLER ESPECÍFICO
                  thumbVisibility: forceScroll,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  child: SingleChildScrollView(
                    controller: _horizontalHeaderController, // ← CONTROLLER ESPECÍFICO
                    scrollDirection: Axis.horizontal,
                    physics: forceScroll
                        ? const AlwaysScrollableScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: availableWidth,
                        maxWidth: forceScroll ? totalCenterWidth : availableWidth,
                      ),
                      child: Container(
                        width: forceScroll ? totalCenterWidth : availableWidth,
                        height: widget.density.headerHeight,
                        child: Row(
                          children: columns.asMap().entries.map((entry) {
                            final index = entry.key;
                            final column = entry.value;

                            return _buildHeaderCell(column, index, false);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),

                // Sombras (mantidas iguais)
                if (forceScroll && _showLeftShadow)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                if (forceScroll && _showRightShadow)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✨ ATUALIZAR _buildScrollableBodySection PARA USAR CONTROLLER ESPECÍFICO
  Widget _buildScrollableBodySection(List<DataColumnConfig<T>> columns, bool forceScroll) {
    final totalCenterWidth = StickyColumnManager.calculateTotalWidth(columns, widget.resizeController);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        print('🔍 BODY SECTION: Total: $totalCenterWidth, Available: $availableWidth, Force: $forceScroll');

        return ClipRect(
          child: Scrollbar(
            controller: _horizontalBodyController, // ← CONTROLLER ESPECÍFICO
            thumbVisibility: forceScroll,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: _horizontalBodyController, // ← CONTROLLER ESPECÍFICO
              scrollDirection: Axis.horizontal,
              physics: forceScroll
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: availableWidth,
                  maxWidth: forceScroll ? totalCenterWidth : availableWidth,
                ),
                child: Container(
                  width: forceScroll ? totalCenterWidth : availableWidth,
                  child: ListView.builder(
                    controller: _verticalScrollController, // ✨ USAR O CONTROLLER PRINCIPAL
                    itemCount: widget.rows.length,
                    itemBuilder: (context, index) {
                      final item = widget.rows[index];
                      final isSelected = widget.selectedItems.contains(item);

                      return Container(
                        height: widget.density.rowHeight,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.colors.primaryLight
                              : index.isEven
                              ? widget.colors.surface
                              : widget.colors.surfaceVariant.withOpacity(0.3),
                          border: Border(bottom: BorderSide(
                            color: widget.colors.outline.withOpacity(0.3),
                            width: 0.5,
                          )),
                        ),
                        child: Row(
                          children: columns.map((column) {
                            final columnWidth = widget.resizeController.getColumnWidth(
                              column.field,
                              defaultWidth: column.effectiveWidth,
                            );

                            return _buildBodyCell(column, item, columnWidth);
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // MANTER TODOS OS OUTROS MÉTODOS IGUAIS (_buildHeaderCell, _buildBodyCell, etc.)
  Widget _buildHeaderCell(DataColumnConfig<T> column, int index, bool isSticky) {
    final currentWidth = widget.resizeController.getColumnWidth(
      column.field,
      defaultWidth: column.effectiveWidth,
    );

    // Escolher componente baseado nas configurações
    if (widget.enableColumnDragDrop && widget.enableColumnResize) {
      return SizedBox(
        width: currentWidth,
        child: ResizableHeaderCell<T>(
          key: ValueKey('sticky_resizable_${column.field}'),
          column: column,
          index: index,
          theme: widget.theme,
          colors: widget.colors,
          density: widget.density,
          columnFilters: widget.columnFilters,
          columnFiltersState: widget.columnFiltersState,
          onColumnFilterChanged: widget.onColumnFilterChanged,
          onColumnReorder: widget.onColumnReorder ?? (_, __) {},
          resizeController: widget.resizeController,
          enableDragDrop: !isSticky, // Desabilitar drag em colunas sticky
          enableResize: widget.enableColumnResize,
          currentSortField: widget.currentSortField,
          isAscending: widget.isAscending,
          onSort: widget.onSort,
        ),
      );
    } else if (widget.enableColumnResize) {
      return SizedBox(
        width: currentWidth,
        child: PureResizableHeaderCell<T>(
          key: ValueKey('sticky_pure_resizable_${column.field}'),
          column: column,
          index: index,
          theme: widget.theme,
          colors: widget.colors,
          density: widget.density,
          columnFilters: widget.columnFilters,
          columnFiltersState: widget.columnFiltersState,
          onColumnFilterChanged: widget.onColumnFilterChanged,
          resizeController: widget.resizeController,
          enableResize: widget.enableColumnResize,
          currentSortField: widget.currentSortField,
          isAscending: widget.isAscending,
          onSort: widget.onSort,
        ),
      );
    } else {
      return _buildStaticHeaderCell(column, currentWidth);
    }
  }

  Widget _buildStaticHeaderCell(DataColumnConfig<T> column, double width) {
    final isSorted = widget.currentSortField == column.field;
    final filterOption = widget.columnFilters
        .where((f) => f.field == column.field)
        .firstOrNull;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      alignment: column.alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: column.sortable && widget.onSort != null ? () {
                final newAscending = widget.currentSortField == column.field
                    ? !widget.isAscending
                    : true;
                widget.onSort!(column.field, newAscending);
              } : null,
              child: MouseRegion(
                cursor: column.sortable ? SystemMouseCursors.click : SystemMouseCursors.basic,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          column.label,
                          style: TextStyle(
                            fontSize: widget.density.headerFontSize,
                            fontWeight: FontWeight.w600,
                            color: isSorted ? widget.colors.primary : widget.colors.onSurface,
                            height: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (column.sortable) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isSorted
                              ? (widget.isAscending ? Icons.arrow_upward : Icons.arrow_downward)
                              : Icons.unfold_more,
                          size: 14,
                          color: isSorted ? widget.colors.primary : widget.colors.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (filterOption != null) ...[
            const SizedBox(width: 4),
            SizedBox(
              width: 20,
              height: 20,
              child: HeaderColumnFilter(
                filterOption: filterOption,
                currentValue: widget.columnFiltersState[column.field],
                onFilterChanged: widget.onColumnFilterChanged,
                colors: widget.colors,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBodyCell(DataColumnConfig<T> column, T item, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      alignment: column.alignment,
      child: column.cellBuilder != null
          ? column.cellBuilder!(item)
          : Text(
        column.valueGetter(item).toString(),
        style: TextStyle(
          fontSize: widget.density.fontSize,
          color: widget.colors.onSurface,
          fontWeight: FontWeight.w400,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  List<BoxShadow>? _getStickyHeaderShadow(StickyPosition position) {
    switch (position) {
      case StickyPosition.left:
        return _showLeftShadow ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ] : null;
      case StickyPosition.right:
        return _showRightShadow ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(-2, 0),
          ),
        ] : null;
      case StickyPosition.none:
      default:
        return null;
    }
  }

  List<BoxShadow>? _getStickyBodyShadow(StickyPosition position) {
    switch (position) {
      case StickyPosition.left:
        return _showLeftShadow ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ] : null;
      case StickyPosition.right:
        return _showRightShadow ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(-2, 0),
          ),
        ] : null;
      case StickyPosition.none:
        return null;
    }
  }
}
