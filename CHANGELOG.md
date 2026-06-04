# Changelog

All notable changes to `innovare_data_table` are documented in this file.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/),
and the package follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- `ROADMAP.md` documenting north star, current state and a 7-wave plan to
  promote the package to "Oscar-worthy" craft (see `feat/adopt-innovare-design`).
- `innovare_design` integration (optional): when an `InnovareDesignTheme` is
  present in the widget tree, the table picks its colors from the host's
  `InnvColorScheme` (including semantic `success`/`warning`/`danger`/`info`
  families). Falls back to Material `ColorScheme` when absent.
- `publish_to: none` declared in `pubspec.yaml` to remove the
  `invalid_dependency` analyzer warning that fired for downstream packages
  consuming this one via `git`.
- `lib/src/theme/innovare_design_adapter.dart`:
  - `InnovareDesignToDataTableColorScheme.toDataTableColorScheme()` extension
    projecting an `InnovareDesignTheme` onto a `DataTableColorScheme`.
  - `DataTableDensityFromInnv.toInnvDensityConfig({typography})` extension
    that returns a tokenized `DensityConfig` (paddings via `InnvSpacing.md/
    lg/xl`, row/header heights via `InnvDensity` scale factors, font sizes
    via `InnvTypography.bodyMedium`/`labelMedium`).
  - `resolveDataTableColorSchemeFromInnv(context)` and
    `resolveDataTableDensityConfigFromInnv(context, density)` helpers.

### Changed
- `innovare_core` git ref re-pinned to `release/2026-05-19_001` (the ref the
  consumer apps `app-innv-bolao` and `app-innv-franchise-finance` already
  use). The previous ref `feature/ajustes-connect` had been deleted, forcing
  every consumer to ship a `dependency_overrides` block.
- `InnovareDataTableTheme.of(context)` now auto-injects a tokenized
  `DensityConfig` (via the adapter above) when the host installs an
  `InnovareDesignTheme` and the consumer did not provide a `customDensity`.
  Fully backward compatible — apps without the design system keep the
  legacy `DensityConfig.compact/normal/comfortable` statics.
- `SkeletonLoader` reworked from a `StatefulWidget` (with its own
  `AnimationController`) into a `StatelessWidget` that delegates to
  `InnvSkeleton` when an `InnovareDesignTheme` is present. The original
  Material shimmer is preserved as a private `_MaterialSkeletonShimmer`
  fallback for pre-design-system consumers — visual output is unchanged
  for them.

## [0.0.18] — 2026-06 (state on `main @ 314770e`)

> Snapshot of the package right before the design-system adoption work
> started. Frozen as git tag `v0.0.18`.

### Added
- `DataTableController.notifyDataChanged()` and `updateItemWhere(predicate,
  updater)` for fine-grained updates without HTTP refetch (commit `7493d1f`).
- `UnifiedFiltersController` honours `isDefault` on initialization
  (commit `0e7af81`).

### Fixed
- Multiple color and layout tweaks across the merged `feature/nova` branch
  (PR #1, commits `2b35503` and earlier).

## Earlier history

Per-commit history before `0.0.18` was a long sequence of squash-style
"ajustes" commits on `feature/nova`; not summarised here. See `git log`
for archeology.
