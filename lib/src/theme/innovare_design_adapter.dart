import 'package:flutter/material.dart';
import 'package:innovare_design/innovare_design.dart';

import '../data_table_theme.dart';

/// Bridges `innovare_design`'s [InnovareDesignTheme] into the
/// `innovare_data_table`'s [DataTableColorScheme] vocabulary.
///
/// When an app installs an `InnovareDesignTheme` in its `ThemeData.extensions`
/// (via `InnvPresets.aurora()`, `vibe()`, `slate()`, `lumen()` or a custom
/// scheme), the table can pick up those tokens automatically — no hex literal,
/// no per-app retheming.
///
/// Mapping rationale:
///
/// - `primary` / `onPrimary` → brand / onBrand (the identity color).
/// - `primaryLight` → brandContainer (used for hover / selected backgrounds).
/// - `surface` / `surfaceVariant` / `surfaceContainer` → matching tiers of
///   the design scheme; `surfaceVariant` maps to `surfaceContainerHigh` so
///   the header row sits one elevation step above the rows.
/// - `onSurface` / `onSurfaceVariant` → onSurface / onSurfaceVariant.
/// - `outline` → outlineVariant (hairlines, dividers — never the strong
///   `outline` token which is reserved for borders that need to read).
/// - `success` / `warning` / `error` → the `content` slot of each semantic
///   status family (the text/icon color, not the surface tint, since
///   `DataTableColorScheme` exposes a single color per status).
/// - `shadow` → shadow.
extension InnovareDesignToDataTableColorScheme on InnovareDesignTheme {
  /// Projects this design theme onto a [DataTableColorScheme].
  DataTableColorScheme toDataTableColorScheme() => DataTableColorScheme(
        primary: colors.brand,
        primaryLight: colors.brandContainer,
        surface: colors.surface,
        surfaceVariant: colors.surfaceContainerHigh,
        surfaceContainer: colors.surfaceContainer,
        outline: colors.outlineVariant,
        onSurface: colors.onSurface,
        onSurfaceVariant: colors.onSurfaceVariant,
        onPrimary: colors.onBrand,
        shadow: colors.shadow,
        success: colors.success.content,
        warning: colors.warning.content,
        error: colors.danger.content,
      );
}

/// Convenience: resolves a [DataTableColorScheme] from the nearest
/// [InnovareDesignTheme] in the widget tree, returning `null` if none is
/// installed. Callers fall back to [DataTableColorScheme.fromTheme] in that
/// case.
DataTableColorScheme? resolveDataTableColorSchemeFromInnv(
  BuildContext context,
) {
  final theme = InnovareDesignTheme.maybeOf(context);
  return theme?.toDataTableColorScheme();
}
