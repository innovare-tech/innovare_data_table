import 'package:flutter/material.dart';
import 'package:innovare_data_table/src/accessibility/accessibility_config.dart';

class DataTableFocusManager extends ChangeNotifier {
  final DataTableAccessibilityConfig accessibilityConfig;

  // Focus state
  FocusNode? _currentFocus;
  String _currentScope = 'table';
  final Map<String, FocusNode> _scopeFocusNodes = {};

  // Navigation state
  int _focusedRow = -1;
  int _focusedColumn = -1;
  bool _isHeaderFocused = false;

  // Focus history for restoration
  final List<FocusState> _focusHistory = [];

  DataTableFocusManager({required this.accessibilityConfig});

  // Getters
  FocusNode? get currentFocus => _currentFocus;
  String get currentScope => _currentScope;
  int get focusedRow => _focusedRow;
  int get focusedColumn => _focusedColumn;
  bool get isHeaderFocused => _isHeaderFocused;

  void registerScope(String scope, FocusNode focusNode) {
    _scopeFocusNodes[scope] = focusNode;
  }

  void setFocus(String scope, {FocusNode? specificNode}) {
    final targetNode = specificNode ?? _scopeFocusNodes[scope];
    if (targetNode != null) {
      _saveFocusState();
      _currentFocus = targetNode;
      _currentScope = scope;
      targetNode.requestFocus();
      notifyListeners();
    }
  }

  void moveFocusToCell(int row, int column, {required int totalRows, required int totalColumns}) {
    // Validate bounds
    if (row < -1 || row >= totalRows || column < 0 || column >= totalColumns) {
      return;
    }

    _saveFocusState();
    _focusedRow = row;
    _focusedColumn = column;
    _isHeaderFocused = row == -1;

    if (accessibilityConfig.enableAnnouncements) {
      _announceFocusChange();
    }

    notifyListeners();
  }

  void moveUp({required int totalRows, required int totalColumns}) {
    if (_isHeaderFocused) {
      return; // Can't go up from header
    }

    if (_focusedRow > 0) {
      moveFocusToCell(_focusedRow - 1, _focusedColumn,
          totalRows: totalRows, totalColumns: totalColumns);
    } else if (_focusedRow == 0) {
      // Move to header
      moveFocusToCell(-1, _focusedColumn,
          totalRows: totalRows, totalColumns: totalColumns);
    }
  }

  void moveDown({required int totalRows, required int totalColumns}) {
    if (_isHeaderFocused) {
      // Move from header to first row
      moveFocusToCell(0, _focusedColumn,
          totalRows: totalRows, totalColumns: totalColumns);
    } else if (_focusedRow < totalRows - 1) {
      moveFocusToCell(_focusedRow + 1, _focusedColumn,
          totalRows: totalRows, totalColumns: totalColumns);
    }
  }

  void moveLeft({required int totalRows, required int totalColumns}) {
    if (_focusedColumn > 0) {
      moveFocusToCell(_focusedRow, _focusedColumn - 1,
          totalRows: totalRows, totalColumns: totalColumns);
    }
  }

  void moveRight({required int totalRows, required int totalColumns}) {
    if (_focusedColumn < totalColumns - 1) {
      moveFocusToCell(_focusedRow, _focusedColumn + 1,
          totalRows: totalRows, totalColumns: totalColumns);
    }
  }

  void moveToHome({required int totalRows, required int totalColumns}) {
    moveFocusToCell(_focusedRow, 0,
        totalRows: totalRows, totalColumns: totalColumns);
  }

  void moveToEnd({required int totalRows, required int totalColumns}) {
    moveFocusToCell(_focusedRow, totalColumns - 1,
        totalRows: totalRows, totalColumns: totalColumns);
  }

  void moveToFirstPage({required int totalRows, required int totalColumns}) {
    moveFocusToCell(0, _focusedColumn,
        totalRows: totalRows, totalColumns: totalColumns);
  }

  void moveToLastPage({required int totalRows, required int totalColumns}) {
    moveFocusToCell(totalRows - 1, _focusedColumn,
        totalRows: totalRows, totalColumns: totalColumns);
  }

  void focusSearch() {
    setFocus('search');
  }

  void focusFilters() {
    setFocus('filters');
  }

  void focusPagination() {
    setFocus('pagination');
  }

  void restorePreviousFocus() {
    if (_focusHistory.isNotEmpty) {
      final previousState = _focusHistory.removeLast();
      _focusedRow = previousState.row;
      _focusedColumn = previousState.column;
      _isHeaderFocused = previousState.isHeader;
      _currentScope = previousState.scope;
      notifyListeners();
    }
  }

  void _saveFocusState() {
    _focusHistory.add(FocusState(
      row: _focusedRow,
      column: _focusedColumn,
      isHeader: _isHeaderFocused,
      scope: _currentScope,
    ));

    // Limit history size
    if (_focusHistory.length > 10) {
      _focusHistory.removeAt(0);
    }
  }

  void _announceFocusChange() {
    if (!accessibilityConfig.enableAnnouncements) return;

    String announcement;

    if (_isHeaderFocused) {
      announcement = 'Cabeçalho da coluna ${_focusedColumn + 1}';
    } else {
      announcement = 'Linha ${_focusedRow + 1}, coluna ${_focusedColumn + 1}';
    }

    AccessibilityAnnouncer().announceCustom(announcement);
  }

  @override
  void dispose() {
    _scopeFocusNodes.values.forEach((node) => node.dispose());
    super.dispose();
  }
}

class FocusState {
  final int row;
  final int column;
  final bool isHeader;
  final String scope;

  const FocusState({
    required this.row,
    required this.column,
    required this.isHeader,
    required this.scope,
  });
}