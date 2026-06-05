# Changelog

All notable changes to `innovare_data_table` are documented in this file.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/),
and the package follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### BREAKING CHANGES

- **Page indexing is now 1-indexed everywhere.** `DataTableRequest.page`,
  `DataTableResult.page`, `DataTableController.goToPage(page)` and every
  built-in factory (`HttpDataTableSource.laravel`/`.django`/`.custom`),
  helper (`ApiHelpers.parseStandardPagination`) and widget
  (`InnovareDataTable`, `MobileBottomActionBar`) treat `1` as the first
  page — never `0`. `DataTableRequest` now asserts `page >= 1`.
  - **Bug fixed**: `LocalDataTableSource.fetch` used to skip `pageSize`
    items on the first page when called with the new default `page = 1`,
    because `startIndex = page * pageSize`. Now `(page - 1) * pageSize`.
  - **Apps that previously passed `page: 0`** to `goToPage`, the request
    constructor, or read `currentResult.page` as 0-indexed must add `+1`
    on read sites. UI text that hardcoded `'Página ${currentPage + 1}'`
    must drop the `+1`.
  - The Laravel/Django factories no longer add `+1` to the outgoing
    query param — `request.page` is forwarded as-is. The Laravel
    response parser no longer subtracts `-1` from `current_page`.
  - `MobileBottomActionBar` (public widget): the `currentPage` argument
    is now expected 1-indexed.

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
- `DataTableResult` helpers: `isFirstPage`, `isLastPage`,
  `totalPages` returns `0` for empty data sets.
- `test/page_indexing_test.dart`: 20 tests locking the 1-indexed
  convention end-to-end (request defaults, result boundary getters,
  `LocalDataTableSource` slicing, controller pagination/sort/filter
  resets, Laravel/Django factory parsers and URL builders).
- `DataTableController.realtimeKeyExtractor` (optional, named) — when
  provided, the controller applies `insert`/`update`/`delete` realtime
  events in place on `_currentResult` (mutating the current page and
  bumping `totalCount`) instead of issuing a full refetch. Falls back
  to the legacy `refresh()` path when (a) the extractor is `null`,
  (b) an `update` arrives for a row that's not on the current page,
  (c) a `delete` arrives for a row that's not on the current page, or
  (d) an `insert` event arrives with no payload.
- `test/realtime_updates_test.dart`: 12 tests covering the new
  realtime path — insert (single + batch), update in-place, update
  off-page falling back to refresh, delete by `itemId` and by `item`,
  delete off-page falling back, `refresh` event always refetching,
  `notifyListeners` firing, and the legacy fallback when no
  `realtimeKeyExtractor` is supplied.

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
