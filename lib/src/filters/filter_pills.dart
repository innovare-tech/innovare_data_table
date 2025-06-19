import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:innovare_data_table/src/data_table_filters.dart';
import 'package:innovare_data_table/src/data_table_theme.dart';
import 'package:innovare_data_table/src/filters/quick_filters.dart';

class FilterPill {
  final String id;
  final String field;
  final String label;
  final String displayText;
  final dynamic value;
  final FilterOperator operator;
  final Color? color;

  const FilterPill({
    required this.id,
    required this.field,
    required this.label,
    required this.displayText,
    required this.value,
    required this.operator,
    this.color,
  });

  static FilterPill fromActiveFilter(ActiveFilter filter, String fieldLabel) {
    return FilterPill(
      id: '${filter.field}_${filter.value}',
      field: filter.field,
      label: fieldLabel,
      displayText: filter.getDisplayText(fieldLabel),
      value: filter.value,
      operator: filter.operator,
    );
  }

  static FilterPill fromQuickFilter(QuickFilter quickFilter) {
    return FilterPill(
      id: quickFilter.id,
      field: quickFilter.field,
      label: quickFilter.label,
      displayText: quickFilter.label,
      value: quickFilter.value,
      operator: quickFilter.operator,
      color: quickFilter.color,
    );
  }
}

class FilterPillsBar extends StatefulWidget {
  final List<FilterPill> pills;
  final Function(String pillId) onRemovePill;
  final VoidCallback? onClearAll;
  final DataTableColorScheme colors;
  final Widget? leading;
  final Widget? trailing;

  const FilterPillsBar({
    super.key,
    required this.pills,
    required this.onRemovePill,
    this.onClearAll,
    required this.colors,
    this.leading,
    this.trailing,
  });

  @override
  State<FilterPillsBar> createState() => _FilterPillsBarState();
}

class _FilterPillsBarState extends State<FilterPillsBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    if (widget.pills.isNotEmpty) {
      _slideController.forward();
    }
  }

  @override
  void didUpdateWidget(FilterPillsBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.pills.isNotEmpty && oldWidget.pills.isEmpty) {
      _slideController.forward();
    } else if (widget.pills.isEmpty && oldWidget.pills.isNotEmpty) {
      _slideController.reverse();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pills.isEmpty) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: widget.colors.surfaceVariant.withOpacity(0.3),
            border: Border(
              bottom: BorderSide(
                color: widget.colors.outline.withOpacity(0.2),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 12),
              ],

              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...widget.pills.asMap().entries.map((entry) {
                        final index = entry.key;
                        final pill = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < widget.pills.length - 1 ? 8 : 0,
                          ),
                          child: _buildFilterPill(pill, index),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              if (widget.trailing != null || widget.onClearAll != null) ...[
                const SizedBox(width: 12),
                if (widget.trailing != null)
                  widget.trailing!
                else if (widget.onClearAll != null)
                  _buildClearAllButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(FilterPill pill, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 50)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return Transform.scale(
          scale: 0.7 + (0.3 * animation),
          child: Opacity(
            opacity: animation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: pill.color?.withOpacity(0.1) ?? widget.colors.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: pill.color ?? widget.colors.primary,
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => widget.onRemovePill(pill.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            pill.displayText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: pill.color ?? widget.colors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.close,
                          size: 14,
                          color: pill.color ?? widget.colors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildClearAllButton() {
    return Material(
      color: widget.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onClearAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.clear_all,
                size: 14,
                color: widget.colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                "Limpar",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: widget.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}