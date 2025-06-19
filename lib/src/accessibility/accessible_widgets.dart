import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_data_table/src/accessibility/accessibility_config.dart';

class AccessibleDataCell<T> extends StatefulWidget {
  final T item;
  final DataColumnConfig<T> column;
  final int rowIndex;
  final int columnIndex;
  final bool isSelected;
  final bool isFocused;
  final VoidCallback? onTap;
  final VoidCallback? onFocus;
  final DataTableAccessibilityConfig accessibilityConfig;
  final FocusNode? focusNode;

  const AccessibleDataCell({
    super.key,
    required this.item,
    required this.column,
    required this.rowIndex,
    required this.columnIndex,
    required this.isSelected,
    required this.isFocused,
    this.onTap,
    this.onFocus,
    required this.accessibilityConfig,
    this.focusNode,
  });

  @override
  State<AccessibleDataCell<T>> createState() => _AccessibleDataCellState<T>();
}

class _AccessibleDataCellState<T> extends State<AccessibleDataCell<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<double> _focusAnimation;

  @override
  void initState() {
    super.initState();
    _initializeFocusAnimation();
  }

  void _initializeFocusAnimation() {
    _focusController = AnimationController(
      duration: widget.accessibilityConfig.focusAnimationDuration,
      vsync: this,
    );
    _focusAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeInOut),
    );

    if (widget.isFocused) {
      _focusController.forward();
    }
  }

  @override
  void didUpdateWidget(AccessibleDataCell<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isFocused != oldWidget.isFocused) {
      if (widget.isFocused) {
        _focusController.forward();
      } else {
        _focusController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.column.valueGetter(widget.item);
    final cellContent = widget.column.cellBuilder?.call(widget.item) ??
        Text(value.toString());

    Widget cell = AnimatedBuilder(
      animation: _focusAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _focusAnimation.value,
          child: Container(
            constraints: BoxConstraints(
              minHeight: widget.accessibilityConfig.minimumTouchTargetSize,
            ),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : null,
              border: widget.isFocused && widget.accessibilityConfig.enableFocusIndicators
                  ? Border.all(
                color: Theme.of(context).focusColor,
                width: 2,
              )
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(8),
            child: cellContent,
          ),
        );
      },
    );

    if (widget.accessibilityConfig.enableSemanticLabels) {
      cell = Semantics(
        label: _buildSemanticLabel(),
        hint: _buildSemanticHint(),
        value: value.toString(),
        selected: widget.isSelected,
        focused: widget.isFocused,
        button: widget.onTap != null,
        onTap: widget.onTap,
        child: cell,
      );
    }

    if (widget.focusNode != null) {
      cell = Focus(
        focusNode: widget.focusNode,
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            widget.onFocus?.call();
          }
        },
        child: cell,
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: cell,
    );
  }

  String _buildSemanticLabel() {
    final customLabel = widget.accessibilityConfig.customLabels['cell_${widget.column.field}'];
    if (customLabel != null) return customLabel;

    return '${widget.column.label}, linha ${widget.rowIndex + 1}';
  }

  String _buildSemanticHint() {
    final customHint = widget.accessibilityConfig.customHints['cell_${widget.column.field}'];
    if (customHint != null) return customHint;

    return widget.column.sortable
        ? 'Toque para selecionar, navegue com as setas'
        : 'Toque para selecionar';
  }
}

class AccessibleHeaderCell<T> extends StatefulWidget {
  final DataColumnConfig<T> column;
  final int columnIndex;
  final bool isSorted;
  final bool isAscending;
  final bool isFocused;
  final VoidCallback? onSort;
  final VoidCallback? onFilter;
  final VoidCallback? onFocus;
  final DataTableAccessibilityConfig accessibilityConfig;
  final FocusNode? focusNode;

  const AccessibleHeaderCell({
    super.key,
    required this.column,
    required this.columnIndex,
    required this.isSorted,
    required this.isAscending,
    required this.isFocused,
    this.onSort,
    this.onFilter,
    this.onFocus,
    required this.accessibilityConfig,
    this.focusNode,
  });

  @override
  State<AccessibleHeaderCell<T>> createState() => _AccessibleHeaderCellState<T>();
}

class _AccessibleHeaderCellState<T> extends State<AccessibleHeaderCell<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<double> _focusAnimation;

  @override
  void initState() {
    super.initState();
    _initializeFocusAnimation();
  }

  void _initializeFocusAnimation() {
    _focusController = AnimationController(
      duration: widget.accessibilityConfig.focusAnimationDuration,
      vsync: this,
    );
    _focusAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeInOut),
    );

    if (widget.isFocused) {
      _focusController.forward();
    }
  }

  @override
  void didUpdateWidget(AccessibleHeaderCell<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isFocused != oldWidget.isFocused) {
      if (widget.isFocused) {
        _focusController.forward();
      } else {
        _focusController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget header = AnimatedBuilder(
      animation: _focusAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _focusAnimation.value,
          child: Container(
            constraints: BoxConstraints(
              minHeight: widget.accessibilityConfig.minimumTouchTargetSize,
            ),
            decoration: BoxDecoration(
              color: widget.isSorted
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : null,
              border: widget.isFocused && widget.accessibilityConfig.enableFocusIndicators
                  ? Border.all(
                color: Theme.of(context).focusColor,
                width: 2,
              )
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.column.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: widget.isSorted
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                  ),
                ),
                if (widget.column.sortable) ...[
                  const SizedBox(width: 4),
                  Icon(
                    widget.isSorted
                        ? (widget.isAscending ? Icons.arrow_upward : Icons.arrow_downward)
                        : Icons.unfold_more,
                    size: 16,
                    color: widget.isSorted
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                ],
                if (widget.column.filterable) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.filter_list,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (widget.accessibilityConfig.enableSemanticLabels) {
      header = Semantics(
        label: _buildSemanticLabel(),
        hint: _buildSemanticHint(),
        header: true,
        sortKey: widget.isSorted ? OrdinalSortKey(widget.columnIndex.toDouble()) : null,
        button: widget.column.sortable,
        focused: widget.isFocused,
        onTap: widget.onSort,
        customSemanticsActions: _buildCustomActions(),
        child: header,
      );
    }

    if (widget.focusNode != null) {
      header = Focus(
        focusNode: widget.focusNode,
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            widget.onFocus?.call();
          }
        },
        child: header,
      );
    }

    return GestureDetector(
      onTap: widget.onSort,
      child: header,
    );
  }

  String _buildSemanticLabel() {
    final customLabel = widget.accessibilityConfig.customLabels['header_${widget.column.field}'];
    if (customLabel != null) return customLabel;

    String label = 'Coluna ${widget.column.label}';

    if (widget.isSorted) {
      label += ', ordenada em ordem ${widget.isAscending ? "crescente" : "decrescente"}';
    }

    return label;
  }

  String _buildSemanticHint() {
    final customHint = widget.accessibilityConfig.customHints['header_${widget.column.field}'];
    if (customHint != null) return customHint;

    final hints = <String>[];

    if (widget.column.sortable) {
      hints.add('Toque para ordenar');
    }

    if (widget.column.filterable) {
      hints.add('Toque duas vezes para filtrar');
    }

    return hints.join(', ');
  }

  Map<CustomSemanticsAction, VoidCallback> _buildCustomActions() {
    final actions = <CustomSemanticsAction, VoidCallback>{};

    if (widget.column.sortable && widget.onSort != null) {
      actions[const CustomSemanticsAction(label: 'Ordenar')] = widget.onSort!;
    }

    if (widget.column.filterable && widget.onFilter != null) {
      actions[const CustomSemanticsAction(label: 'Filtrar')] = widget.onFilter!;
    }

    return actions;
  }
}