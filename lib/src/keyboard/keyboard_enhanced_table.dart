import 'package:flutter/material.dart';
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_data_table/src/accessibility/accessibility_config.dart';
import 'package:innovare_data_table/src/accessibility/high_contrast_theme.dart';
import 'package:innovare_data_table/src/keyboard/focus_manager.dart';
import 'package:innovare_data_table/src/keyboard/keyboard_help_dialog.dart';
import 'package:innovare_data_table/src/keyboard/keyboard_shortcuts.dart';

class KeyboardEnhancedDataTable<T> extends StatefulWidget {
  final List<DataColumnConfig<T>> columns;
  final List<T> rows;
  final InnovareDataTableConfig<T> config;
  final String? title;
  final Function(T item)? onItemActivated;
  final Function(List<T> items)? onItemsSelected;
  final Function(String field, bool ascending)? onSort;
  final Function()? onRefresh;

  const KeyboardEnhancedDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.config,
    this.title,
    this.onItemActivated,
    this.onItemsSelected,
    this.onSort,
    this.onRefresh,
  });

  @override
  State<KeyboardEnhancedDataTable<T>> createState() => _KeyboardEnhancedDataTableState<T>();
}

class _KeyboardEnhancedDataTableState<T> extends State<KeyboardEnhancedDataTable<T>> {
  late DataTableFocusManager _focusManager;
  late AccessibilityAnnouncer _announcer;

  final Set<T> _selectedItems = {};
  String? _sortField;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _initializeAccessibility();
  }

  void _initializeAccessibility() {
    final accessibilityConfig = widget.config.searchConfig?.enableSuggestions == true
        ? const DataTableAccessibilityConfig()
        : const DataTableAccessibilityConfig(enableKeyboardNavigation: true);

    _focusManager = DataTableFocusManager(accessibilityConfig: accessibilityConfig);
    _announcer = AccessibilityAnnouncer();

    // Initialize focus on first cell
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.rows.isNotEmpty && widget.columns.isNotEmpty) {
        _focusManager.moveFocusToCell(0, 0,
            totalRows: widget.rows.length,
            totalColumns: widget.columns.length);
      }
    });
  }

  @override
  void dispose() {
    _focusManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AccessibilityProvider(
      config: const DataTableAccessibilityConfig(),
      announcer: _announcer,
      keyboardController: null,
      child: Shortcuts(
        shortcuts: DataTableShortcuts.shortcuts,
        child: Actions(
          actions: DataTableShortcuts.createActions(
            onNavigateUp: () => _focusManager.moveUp(
              totalRows: widget.rows.length,
              totalColumns: widget.columns.length,
            ),
            onNavigateDown: () => _focusManager.moveDown(
              totalRows: widget.rows.length,
              totalColumns: widget.columns.length,
            ),
            onNavigateLeft: () => _focusManager.moveLeft(
              totalRows: widget.rows.length,
              totalColumns: widget.columns.length,
            ),
            onNavigateRight: () => _focusManager.moveRight(
              totalRows: widget.rows.length,
              totalColumns: widget.columns.length,
            ),
            onSelectItem: _selectCurrentItem,
            onActivateItem: _activateCurrentItem,
            onSelectAll: _selectAllItems,
            onClearSelection: _clearSelection,
            onPreviousPage: () => _announcer.announce('pageChanged',
                parameters: {'page': 'anterior'}),
            onNextPage: () => _announcer.announce('pageChanged',
                parameters: {'page': 'próxima'}),
            onFirstPage: () => _focusManager.moveToFirstPage(
              totalRows: widget.rows.length,
              totalColumns: widget.columns.length,
            ),
            onLastPage: () => _focusManager.moveToLastPage(
              totalRows: widget.rows.length,
              totalColumns: widget.columns.length,
            ),
            onSortColumn: _sortCurrentColumn,
            onFilterColumn: () => _focusManager.focusFilters(),
            onRefreshData: widget.onRefresh,
            onDeleteSelected: _deleteSelectedItems,
            onEditSelected: _editSelectedItems,
            onCopySelected: _copySelectedItems,
            onToggleColumnManager: () => _showColumnManager(),
            onToggleDensity: () => _toggleDensity(),
            onShowHelp: _showKeyboardHelp,
          ),
          child: Focus(
            autofocus: true,
            child: _buildTable(),
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    return InnovareDataTable<T>(
      columns: widget.columns,
      rows: widget.rows,
      config: widget.config,
      title: widget.title,
    );
  }

  void _selectCurrentItem() {
    if (_focusManager.isHeaderFocused ||
        _focusManager.focusedRow < 0 ||
        _focusManager.focusedRow >= widget.rows.length) {
      return;
    }

    final item = widget.rows[_focusManager.focusedRow];
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });

    _announcer.announce('selected',
        parameters: {'count': _selectedItems.length});
    widget.onItemsSelected?.call(_selectedItems.toList());
  }

  void _activateCurrentItem() {
    if (_focusManager.isHeaderFocused ||
        _focusManager.focusedRow < 0 ||
        _focusManager.focusedRow >= widget.rows.length) {
      return;
    }

    final item = widget.rows[_focusManager.focusedRow];
    widget.onItemActivated?.call(item);
  }

  void _selectAllItems() {
    setState(() {
      _selectedItems.clear();
      _selectedItems.addAll(widget.rows);
    });

    _announcer.announce('selected',
        parameters: {'count': _selectedItems.length});
    widget.onItemsSelected?.call(_selectedItems.toList());
  }

  void _clearSelection() {
    setState(() {
      _selectedItems.clear();
    });

    _announcer.announce('selected', parameters: {'count': 0});
    widget.onItemsSelected?.call([]);
  }

  void _sortCurrentColumn() {
    if (!_focusManager.isHeaderFocused ||
        _focusManager.focusedColumn < 0 ||
        _focusManager.focusedColumn >= widget.columns.length) {
      return;
    }

    final column = widget.columns[_focusManager.focusedColumn];
    if (!column.sortable) {
      _announcer.announceCustom('Esta coluna não pode ser ordenada');
      return;
    }

    setState(() {
      if (_sortField == column.field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = column.field;
        _sortAscending = true;
      }
    });

    _announcer.announce('sorted', parameters: {
      'column': column.label,
      'direction': _sortAscending ? 'crescente' : 'decrescente',
    });

    widget.onSort?.call(column.field, _sortAscending);
  }

  void _deleteSelectedItems() {
    if (_selectedItems.isEmpty) {
      _announcer.announceCustom('Nenhum item selecionado para excluir');
      return;
    }

    _announcer.announceCustom('${_selectedItems.length} itens marcados para exclusão');
    // Implementar lógica de exclusão
  }

  void _editSelectedItems() {
    if (_selectedItems.isEmpty) {
      _announcer.announceCustom('Nenhum item selecionado para editar');
      return;
    }

    if (_selectedItems.length > 1) {
      _announcer.announceCustom('Múltiplos itens selecionados para edição em lote');
    } else {
      _announcer.announceCustom('Abrindo editor para item selecionado');
    }
    // Implementar lógica de edição
  }

  void _copySelectedItems() {
    if (_selectedItems.isEmpty) {
      _announcer.announceCustom('Nenhum item selecionado para copiar');
      return;
    }

    _announcer.announceCustom('${_selectedItems.length} itens copiados para a área de transferência');
    // Implementar lógica de cópia
  }

  void _showColumnManager() {
    _announcer.announceCustom('Abrindo gerenciador de colunas');
    // Implementar abertura do gerenciador de colunas
  }

  void _toggleDensity() {
    _announcer.announceCustom('Alternando densidade da tabela');
    // Implementar alternância de densidade
  }

  void _showKeyboardHelp() {
    showDialog(
      context: context,
      builder: (context) => KeyboardHelpDialog(
        shortcuts: KeyboardHelpDialog.getDefaultShortcuts(),
      ),
    );
  }
}
