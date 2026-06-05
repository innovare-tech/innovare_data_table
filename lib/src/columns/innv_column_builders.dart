import 'package:flutter/material.dart';
import 'package:innovare_design/innovare_design.dart';

import '../data_column_config.dart';

/// Per-row action used by [InnvColumns.actions]. A typical row exposes
/// 1-3 of these (edit / archive / delete). All callbacks are evaluated
/// against the row's item, so the same column definition reacts to the
/// current state of each row (e.g. disable "archive" once a row is
/// already archived).
class InnvRowAction<T> {
  final IconData icon;
  final String tooltip;
  final void Function(T item) onPressed;

  /// `true` paints the icon with the danger color (used for destructive
  /// actions like delete). Doesn't change the rest of the behaviour.
  final bool danger;

  /// Optional per-row visibility flag. Hidden actions don't render at
  /// all (they don't even reserve space). Defaults to "always visible".
  final bool Function(T item)? isVisible;

  /// Optional per-row enabled flag. A disabled action renders greyed
  /// out and ignores taps. Defaults to "always enabled".
  final bool Function(T item)? isEnabled;

  const InnvRowAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.danger = false,
    this.isVisible,
    this.isEnabled,
  });
}

/// Factory namespace for `DataColumnConfig`s that render design-system
/// primitives. Keeps the helpers out of `DataColumnConfig` itself so
/// the core file stays free of design-system imports — apps that only
/// build plain text columns don't pull in extra symbols.
///
/// Usage:
/// ```dart
/// columns: [
///   DataColumnConfig(field: 'name', label: 'Name', ...),
///
///   InnvColumns.badge<Order>(
///     field: 'status',
///     label: 'Status',
///     labelOf: (o) => o.status.displayName,
///     kindOf: (o) => switch (o.status) {
///       OrderStatus.paid => InnvStatusKind.success,
///       OrderStatus.pending => InnvStatusKind.warning,
///       OrderStatus.canceled => InnvStatusKind.danger,
///     },
///   ),
///
///   InnvColumns.actions<Order>(
///     actions: [
///       InnvRowAction(icon: Icons.edit, tooltip: 'Edit', onPressed: _edit),
///       InnvRowAction(
///         icon: Icons.delete_outline,
///         tooltip: 'Delete',
///         danger: true,
///         onPressed: _delete,
///       ),
///     ],
///   ),
/// ]
/// ```
abstract final class InnvColumns {
  /// A status column backed by [InnvBadge]. The badge picks tinted
  /// surface / border / content from the host theme automatically, so
  /// every preset (aurora / vibe / slate / lumen) and brightness mode
  /// look correct without any per-status colour wiring.
  ///
  /// - [labelOf] returns the display text. Also used as the value for
  ///   sorting/filtering, so badge columns work with `sortable: true`
  ///   without extra plumbing.
  /// - [kindOf] returns the semantic intent — the only mapping the
  ///   caller has to maintain.
  /// - [iconOf] is optional; when provided, the badge renders the icon
  ///   to the left of the label.
  static DataColumnConfig<T> badge<T>({
    required String field,
    required String label,
    required String Function(T item) labelOf,
    required InnvStatusKind Function(T item) kindOf,
    IconData? Function(T item)? iconOf,
    bool sortable = false,
    bool filterable = false,
    bool dense = true,
    Alignment alignment = Alignment.centerLeft,
    ColumnResizeConfig? resizeConfig,
    StickyConfig? stickyConfig,
    int priority = 0,
  }) {
    return DataColumnConfig<T>(
      field: field,
      label: label,
      sortable: sortable,
      filterable: filterable,
      alignment: alignment,
      resizeConfig: resizeConfig,
      stickyConfig: stickyConfig,
      priority: priority,
      // Sorting/filtering uses the display label — that's almost
      // always the intuitive comparison key for status badges.
      valueGetter: labelOf,
      cellBuilder: (item) => Align(
        alignment: alignment,
        child: InnvBadge(
          label: labelOf(item),
          kind: kindOf(item),
          icon: iconOf?.call(item),
          dense: dense,
        ),
      ),
    );
  }

  /// A trailing actions column. Renders up to N icon buttons per row,
  /// each driven by an [InnvRowAction]. Defaults to right-aligned and
  /// not resizable — apps usually want the actions pinned to the edge.
  ///
  /// The default `field` is `__actions` (double-underscore prefix so
  /// it doesn't collide with backend field names). The default width
  /// scales with the number of actions; override [resizeConfig] if you
  /// need a different size.
  static DataColumnConfig<T> actions<T>({
    required List<InnvRowAction<T>> actions,
    String field = '__actions',
    String label = '',
    Alignment alignment = Alignment.centerRight,
    ColumnResizeConfig? resizeConfig,
    StickyConfig? stickyConfig,
  }) {
    final defaultWidth = 36.0 + (actions.length * 44.0);
    final effectiveResize = resizeConfig ??
        ColumnResizeConfig.fixed(defaultWidth);

    return DataColumnConfig<T>(
      field: field,
      label: label,
      sortable: false,
      filterable: false,
      alignment: alignment,
      resizeConfig: effectiveResize,
      stickyConfig: stickyConfig,
      valueGetter: (_) => '',
      cellBuilder: (item) => _ActionsCell<T>(
        item: item,
        actions: actions,
        alignment: alignment,
      ),
    );
  }
}

class _ActionsCell<T> extends StatelessWidget {
  final T item;
  final List<InnvRowAction<T>> actions;
  final Alignment alignment;

  const _ActionsCell({
    required this.item,
    required this.actions,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final design = InnovareDesignTheme.maybeOf(context);
    final dangerColor =
        design?.colors.danger.content ?? theme.colorScheme.error;

    final visibleActions =
        actions.where((a) => a.isVisible?.call(item) ?? true).toList();
    if (visibleActions.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final a in visibleActions)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Icon(a.icon, size: 18),
              color: a.danger ? dangerColor : null,
              tooltip: a.tooltip,
              onPressed: (a.isEnabled?.call(item) ?? true)
                  ? () => a.onPressed(item)
                  : null,
            ),
        ],
      ),
    );
  }
}
