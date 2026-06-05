import 'package:flutter/material.dart';
import 'package:innovare_design/innovare_design.dart';

import '../data_table_theme.dart';

/// Base row height for the [DataTableDensity.normal] preset. Other densities
/// scale around this anchor by the same factors [InnvDensity] uses.
const double _kBaseRowHeight = 52;
const double _kBaseHeaderHeight = 56;

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

/// Projects a [DataTableDensity] onto a [DensityConfig] built from
/// `innovare_design` tokens (`InnvSpacing` for paddings, `InnvTypography`
/// for font sizes, `InnvDensity` scale factors for row/header heights).
///
/// Paddings map to the spacing scale:
///
/// | Density       | Horizontal     | Vertical (cell) | Vertical (header) |
/// | ------------- | -------------- | --------------- | ----------------- |
/// | `compact`     | `InnvSpacing.md` (12) | `InnvSpacing.sm` (8)  | `InnvSpacing.md` (12) |
/// | `normal`      | `InnvSpacing.lg` (16) | `InnvSpacing.md` (12) | `InnvSpacing.lg` (16) |
/// | `comfortable` | `InnvSpacing.xl` (20) | `InnvSpacing.lg` (16) | `InnvSpacing.xl` (20) |
///
/// These numbers were chosen to be **identical** to the legacy
/// [DensityConfig.compact]/`normal`/`comfortable` statics, so the visual
/// rhythm of existing tables doesn't shift when the host adopts the design
/// system — only the source of the values changes. The real gain is font
/// sizes (now driven by `InnvTypography.bodyMedium`, which respects
/// `typography.scale`) and the fact that any future tweak to the spacing
/// scale propagates automatically.
extension DataTableDensityFromInnv on DataTableDensity {
  /// Returns a [DensityConfig] derived from `innovare_design` tokens.
  ///
  /// [typography] defaults to [InnvTypography.standard]. When the host
  /// installs a custom typography (e.g. via `InnvPresets.vibe()`), pass
  /// `context.innv.typography` to inherit the size scale.
  DensityConfig toInnvDensityConfig({InnvTypography? typography}) {
    final t = typography ?? InnvTypography.standard();
    final fontSize = t.bodyMedium.fontSize ?? 14;
    final labelFontSize = t.labelMedium.fontSize ?? 12;

    switch (this) {
      case DataTableDensity.compact:
        return DensityConfig(
          rowHeight: _kBaseRowHeight * InnvDensity.compact.scale,
          headerHeight: _kBaseHeaderHeight * InnvDensity.compact.scale,
          cellPadding: const EdgeInsets.symmetric(
            horizontal: InnvSpacing.md,
            vertical: InnvSpacing.sm,
          ),
          headerPadding: const EdgeInsets.symmetric(
            horizontal: InnvSpacing.md,
            vertical: InnvSpacing.md,
          ),
          fontSize: fontSize * InnvDensity.compact.scale,
          headerFontSize: labelFontSize,
        );
      case DataTableDensity.comfortable:
        return DensityConfig(
          rowHeight: _kBaseRowHeight * InnvDensity.comfortable.scale,
          headerHeight: _kBaseHeaderHeight * InnvDensity.comfortable.scale,
          cellPadding: const EdgeInsets.symmetric(
            horizontal: InnvSpacing.xl,
            vertical: InnvSpacing.lg,
          ),
          headerPadding: const EdgeInsets.symmetric(
            horizontal: InnvSpacing.xl,
            vertical: InnvSpacing.xl,
          ),
          fontSize: fontSize * InnvDensity.comfortable.scale,
          headerFontSize: labelFontSize,
        );
      case DataTableDensity.normal:
      case DataTableDensity.custom:
        // `custom` is conceptually opaque — fall back to the `normal` anchor.
        return DensityConfig(
          rowHeight: _kBaseRowHeight,
          headerHeight: _kBaseHeaderHeight,
          cellPadding: const EdgeInsets.symmetric(
            horizontal: InnvSpacing.lg,
            vertical: InnvSpacing.md,
          ),
          headerPadding: const EdgeInsets.symmetric(
            horizontal: InnvSpacing.lg,
            vertical: InnvSpacing.lg,
          ),
          fontSize: fontSize,
          headerFontSize: labelFontSize,
        );
    }
  }
}

/// Resolves a [DensityConfig] from the nearest [InnovareDesignTheme] for a
/// given [DataTableDensity]. Returns `null` when no design theme is installed,
/// signalling callers to fall back to the legacy [DensityConfig] statics.
DensityConfig? resolveDataTableDensityConfigFromInnv(
  BuildContext context,
  DataTableDensity density,
) {
  final theme = InnovareDesignTheme.maybeOf(context);
  if (theme == null) return null;
  return density.toInnvDensityConfig(typography: theme.typography);
}
