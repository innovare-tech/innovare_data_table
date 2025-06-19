import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:innovare_data_table/src/accessibility/accessibility_config.dart';

class KeyboardNavigationController extends ChangeNotifier {
  final DataTableAccessibilityConfig config;

  // Navigation state
  int _focusedRow = -1;
  int _focusedColumn = -1;
  bool _isHeaderFocused = false;
  bool _isPaginationFocused = false;
  String _currentFocusScope = 'table';

  // Focus nodes
  final Map<String, FocusNode> _focusNodes = {};
  final List<List<FocusNode>> _cellFocusNodes = [];
  final List<FocusNode> _headerFocusNodes = [];

  KeyboardNavigationController({required this.config});

  // Getters
  int get focusedRow => _focusedRow;
  int get focusedColumn => _focusedColumn;
  bool get isHeaderFocused => _isHeaderFocused;
  String get currentFocusScope => _currentFocusScope;

  void initializeGrid(int rowCount, int columnCount) {
    _clearFocusNodes();

    // Initialize header focus nodes
    _headerFocusNodes.clear();
    for (int col = 0; col < columnCount; col++) {
      _headerFocusNodes.add(FocusNode());
    }

    // Initialize cell focus nodes
    _cellFocusNodes.clear();
    for (int row = 0; row < rowCount; row++) {
      final rowNodes = <FocusNode>[];
      for (int col = 0; col < columnCount; col++) {
        rowNodes.add(FocusNode());
      }
      _cellFocusNodes.add(rowNodes);
    }

    notifyListeners();
  }

  FocusNode? getFocusNode(int row, int column) {
    if (row == -1) {
      // Header
      return column < _headerFocusNodes.length ? _headerFocusNodes[column] : null;
    }

    if (row < _cellFocusNodes.length && column < _cellFocusNodes[row].length) {
      return _cellFocusNodes[row][column];
    }

    return null;
  }

  bool handleKeyEvent(KeyEvent event, {
    required int totalRows,
    required int totalColumns,
    Function(int row, int column)? onCellSelected,
    Function(int column)? onHeaderSelected,
    Function()? onSelectAll,
    Function()? onNextPage,
    Function()? onPreviousPage,
  }) {
    if (event is! KeyDownEvent) return false;

    final key = event.logicalKey;
    final isShiftPressed = event.logicalKey == LogicalKeyboardKey.shift;
    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
    final isAltPressed = HardwareKeyboard.instance.isAltPressed;

    // Handle different key combinations
    if (key == LogicalKeyboardKey.arrowUp) {
      return _handleArrowUp(totalRows, totalColumns, onHeaderSelected, onCellSelected);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      return _handleArrowDown(totalRows, totalColumns, onCellSelected);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      return _handleArrowLeft(totalColumns, onHeaderSelected, onCellSelected);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      return _handleArrowRight(totalColumns, onHeaderSelected, onCellSelected);
    } else if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) {
      return _handleSelection(onCellSelected, onHeaderSelected);
    } else if (key == LogicalKeyboardKey.home) {
      return _handleHome(totalColumns, onHeaderSelected, onCellSelected);
    } else if (key == LogicalKeyboardKey.end) {
      return _handleEnd(totalColumns, onHeaderSelected, onCellSelected);
    } else if (key == LogicalKeyboardKey.pageUp) {
      onPreviousPage?.call();
      return true;
    } else if (key == LogicalKeyboardKey.pageDown) {
      onNextPage?.call();
      return true;
    } else if (isCtrlPressed && key == LogicalKeyboardKey.keyA) {
      onSelectAll?.call();
      return true;
    }

    return false;
  }

  bool _handleArrowUp(
      int totalRows,
      int totalColumns,
      Function(int column)? onHeaderSelected,
      Function(int row, int column)? onCellSelected,
      ) {
    if (_isHeaderFocused) {
      return false; // Can't go up from header
    }

    if (_focusedRow > 0) {
      _focusedRow--;
      _focusCell(_focusedRow, _focusedColumn);
      onCellSelected?.call(_focusedRow, _focusedColumn);
    } else if (_focusedRow == 0) {
      // Move to header
      _isHeaderFocused = true;
      _focusedRow = -1;
      _focusHeader(_focusedColumn);
      onHeaderSelected?.call(_focusedColumn);
    }

    notifyListeners();
    return true;
  }

  bool _handleArrowDown(
      int totalRows,
      int totalColumns,
      Function(int row, int column)? onCellSelected,
      ) {
    if (_isHeaderFocused) {
      // Move from header to first row
      _isHeaderFocused = false;
      _focusedRow = 0;
      _focusCell(_focusedRow, _focusedColumn);
      onCellSelected?.call(_focusedRow, _focusedColumn);
    } else if (_focusedRow < totalRows - 1) {
      _focusedRow++;
      _focusCell(_focusedRow, _focusedColumn);
      onCellSelected?.call(_focusedRow, _focusedColumn);
    }

    notifyListeners();
    return true;
  }

  bool _handleArrowLeft(
      int totalColumns,
      Function(int column)? onHeaderSelected,
      Function(int row, int column)? onCellSelected,
      ) {
    if (_focusedColumn > 0) {
      _focusedColumn--;

      if (_isHeaderFocused) {
        _focusHeader(_focusedColumn);
        onHeaderSelected?.call(_focusedColumn);
      } else {
        _focusCell(_focusedRow, _focusedColumn);
        onCellSelected?.call(_focusedRow, _focusedColumn);
      }
    }

    notifyListeners();
    return true;
  }

  bool _handleArrowRight(
      int totalColumns,
      Function(int column)? onHeaderSelected,
      Function(int row, int column)? onCellSelected,
      ) {
    if (_focusedColumn < totalColumns - 1) {
      _focusedColumn++;

      if (_isHeaderFocused) {
        _focusHeader(_focusedColumn);
        onHeaderSelected?.call(_focusedColumn);
      } else {
        _focusCell(_focusedRow, _focusedColumn);
        onCellSelected?.call(_focusedRow, _focusedColumn);
      }
    }

    notifyListeners();
    return true;
  }

  bool _handleSelection(
      Function(int row, int column)? onCellSelected,
      Function(int column)? onHeaderSelected,
      ) {
    if (_isHeaderFocused) {
      onHeaderSelected?.call(_focusedColumn);
    } else {
      onCellSelected?.call(_focusedRow, _focusedColumn);
    }
    return true;
  }

  bool _handleHome(
      int totalColumns,
      Function(int column)? onHeaderSelected,
      Function(int row, int column)? onCellSelected,
      ) {
    _focusedColumn = 0;

    if (_isHeaderFocused) {
      _focusHeader(_focusedColumn);
      onHeaderSelected?.call(_focusedColumn);
    } else {
      _focusCell(_focusedRow, _focusedColumn);
      onCellSelected?.call(_focusedRow, _focusedColumn);
    }

    notifyListeners();
    return true;
  }

  bool _handleEnd(
      int totalColumns,
      Function(int column)? onHeaderSelected,
      Function(int row, int column)? onCellSelected,
      ) {
    _focusedColumn = totalColumns - 1;

    if (_isHeaderFocused) {
      _focusHeader(_focusedColumn);
      onHeaderSelected?.call(_focusedColumn);
    } else {
      _focusCell(_focusedRow, _focusedColumn);
      onCellSelected?.call(_focusedRow, _focusedColumn);
    }

    notifyListeners();
    return true;
  }

  void _focusHeader(int column) {
    if (column < _headerFocusNodes.length) {
      _headerFocusNodes[column].requestFocus();
    }
  }

  void _focusCell(int row, int column) {
    if (row < _cellFocusNodes.length && column < _cellFocusNodes[row].length) {
      _cellFocusNodes[row][column].requestFocus();
    }
  }

  void focusFirstCell() {
    _focusedRow = 0;
    _focusedColumn = 0;
    _isHeaderFocused = false;
    _focusCell(_focusedRow, _focusedColumn);
    notifyListeners();
  }

  void focusHeader(int column) {
    _focusedColumn = column.clamp(0, _headerFocusNodes.length - 1);
    _isHeaderFocused = true;
    _focusedRow = -1;
    _focusHeader(_focusedColumn);
    notifyListeners();
  }

  void _clearFocusNodes() {
    _headerFocusNodes.forEach((node) => node.dispose());
    _headerFocusNodes.clear();

    _cellFocusNodes.forEach((row) {
      row.forEach((node) => node.dispose());
    });
    _cellFocusNodes.clear();
  }

  @override
  void dispose() {
    _clearFocusNodes();
    super.dispose();
  }
}