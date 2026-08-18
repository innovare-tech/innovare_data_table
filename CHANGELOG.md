# Changelog

All notable changes to `innovare_data_table` are documented in this file.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/),
and the package follows [Semantic Versioning](https://semver.org/).

## [0.1.2] — 2026-08-18

Patch release. Corrige o toque nos cards do modo mobile.

### Fixed

- **O card do modo mobile não abria o detalhe.** `_buildMobileCards` entregava
  `onRowTap` — um `Widget Function(T)`, builder de célula que nenhum consumidor
  do workspace preenche — onde `MobileCardsView` espera o manipulador de toque.
  O campo certo é `onRowTapCallback`, o `void Function(T)` que todas as listas
  já passam. O `InkWell` do card recebia `onTap: null`: em telefone a lista
  inteira ficava inclicável, sem erro e sem aviso, em todos os produtos.

  O erro não aparecia porque `MobileCardsView.onItemTap` estava tipado como
  `Function(T item)?` — sem tipo de retorno —, e um `Widget Function(T)`
  type-checa nessa assinatura. O tipo passou a ser `void Function(T item)?`,
  que rejeita o builder em tempo de compilação.

  Sem mudança de API: `onRowTap` continua declarado e ninguém o usava.

## [0.1.1] — 2026-06-05

Patch release. Fixes a render bug in `InnvColumns.badge` that surfaced
the moment a host without `InnovareDesignTheme` installed adopted the
Wave 4 primitive in production (originally reported on
`logos_saas_frontend`'s Sessions table).

### Fixed

- **`InnvColumns.badge` no longer crashes when the host hasn't adopted
  `innovare_design`.** The previous implementation delegated straight
  to `InnvBadge`, which reads `context.innv` via a bang operator
  (`Theme.of(context).extension<InnovareDesignTheme>()!`). Apps that
  consume the data table without installing the design system tripped
  a `Null check operator used on a null value` inside the cell
  builder; in release/profile mode Flutter swallowed the exception and
  swapped each badge cell for a blank grey `ErrorWidget` placeholder.

  Cells now flow through a new internal `_BadgeCell` widget that
  inspects `InnovareDesignTheme.maybeOf(context)` and picks one of two
  paths at build time:

    - **Design system present** → delegates to `InnvBadge` (unchanged
      behaviour; the path apps that already installed the theme see).
    - **Design system absent** → renders a Material 3 fallback that
      mirrors the same pill shape (tinted surface + matching border +
      readable foreground), using `errorContainer`/`primaryContainer`
      for `danger`/`info` and a synthesised tinted triad for
      `success`/`warning`. Light and dark mode both correct without
      per-app wiring.

  This mirrors the same dual-path strategy `InnovareDataTable` already
  uses for its empty/error states (`_buildEmpty` / `_buildError`), so
  the package stays consistent: every primitive that touches
  `innovare_design` either has a fallback or is documented as
  requiring the theme. `InnvColumns.actions` already had a safe
  fallback (`design?.colors.danger.content ?? theme.colorScheme.error`),
  so no change was needed there.

### Tests

- Added a regression group in `test/innv_column_builders_test.dart`
  exercising the fallback path with a `MaterialApp` that intentionally
  omits `InnovareDesignTheme`: smoke render, absence of `InnvBadge`
  proves the fallback was taken, optional `iconOf` rendering,
  exhaustive coverage of every `InnvStatusKind`, and a dark-mode pump
  covering the dark branch of `_tintedTriad`. Total: **78/78 green**
  (was 73 in v0.1.0).

### Compatibility

- Pure additive change at the source level. The public signature of
  `InnvColumns.badge` is byte-for-byte identical to v0.1.0; only the
  internal cell renderer changed. Apps that already installed
  `InnovareDesignTheme` see the exact same widget tree as before
  (`InnvBadge`); apps that did not get a working Material badge
  instead of a crash. No migration steps required — just bump the pin.

## [0.1.0] — 2026-06-05

First minor bump on top of `v0.0.18`. Folds Waves 0 → 5 of the
`innovare_design` adoption refactor: tokenized theme adapter, 1-indexed
pagination (breaking), in-place realtime updates, multi-column sort UI,
selective cache invalidation, design-system primitives in cells
(`InnvColumns.badge` / `.actions`, tokenized empty + error states,
`InnvTextField` in the unified search), filter convergence (the
unified primitives are now public; the two duplicated top-level
filter props are `@Deprecated`), and an `AppShell`-based example
with 5 dedicated showcases. 73 tests, all green.

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
- `DataTableController.sortMulti(List<DataTableSort>)`: replaces the
  whole sort stack at once (companion to the existing single-column
  `sort(field, ascending)`). Resets pagination to page 1.
- **Multi-column sort UI** in `InnovareDataTable` / `StickyDataTable` /
  `PureResizableHeaderCell` / `ResizableHeaderCell`:
  - New optional fields `activeSorts: List<DataTableSort>` and
    `onSortRequested: OnSortRequested?` on every header cell variant.
  - Header tap reads `HardwareKeyboard.instance.logicalKeysPressed`
    and emits `additive: true` when Shift is held. The parent state
    appends to the stack instead of replacing it.
  - When the stack has ≥ 2 columns, each sorted header renders a
    numeric badge (1, 2, 3 …) next to the direction icon, indicating
    the column's priority in the sort.
  - Local-mode `_applySorting` honours the stack: the primary sort
    decides the order, subsequent entries act as tie-breakers.
  - The legacy `widget.onSort(field, ascending)` callback keeps
    firing with the **primary** sort, so apps that haven't adopted
    multi-sort don't need to change anything.
- `test/multi_sort_test.dart`: 4 tests covering
  `DataTableController.sortMulti` (pagination reset, full-stack
  replacement) and `InnovareDataTable` Shift+click semantics (simple
  tap, additive tap, non-additive replacement of the primary).
- `HttpDataTableSource.invalidateCache({where})`: public API to drop
  cached responses selectively. Without a predicate, equivalent to
  `clearCache()`. With a predicate, evaluates against the original
  `DataTableRequest` that produced each cached entry — lets apps
  invalidate just the pages affected by a write (e.g. after editing
  an item, invalidate every cached page whose filter matches that
  item's status). Companions: `cachedRequests` getter (iterable of
  the original requests) and `cacheLength` getter.
- `test/cache_invalidation_test.dart`: 4 tests using a counting
  `http.Client` so each assertion verifies both the cache state and
  the network impact (e.g. an unaffected entry must not refetch
  after a targeted invalidation).
- `InnovareDataTable.onSortsChanged` (optional): callback that fires
  with the **full** sort stack in priority order. Complements the
  legacy `onSort` (which keeps emitting just the primary). Useful
  for apps that mirror the sort state somewhere outside the table —
  a debug panel, a URL query string, a server-side API.
- **Wave 4 — Design system primitives in cells**:
  - `InnvColumns.badge(...)` factory: builds a `DataColumnConfig`
    whose cell renders an `InnvBadge`. Caller maps each row to a
    display label + `InnvStatusKind` (+ optional icon). `valueGetter`
    mirrors the label so badge columns work with `sortable: true`
    out of the box. Tokenized: every preset / brightness combo
    looks correct without per-status colour wiring.
  - `InnvColumns.actions(...)` factory: builds a trailing actions
    column from a list of `InnvRowAction`s. Each action has an
    `icon`, `tooltip`, `onPressed(item)`, plus optional
    `isVisible(item)`, `isEnabled(item)` and `danger` flags. Default
    column width scales with the number of actions and is locked
    (non-resizable) so apps don't have to remember to pin it.
  - `InnvRowAction<T>` model class exposed from the library barrel.
  - `test/innv_column_builders_test.dart`: 7 tests covering
    `valueGetter` mapping, badge widget rendering with the correct
    kind, action visibility/enabled flags, danger colouring and the
    default fixed-width resize config.
- **Wave 3.3 — Filter convergence (deprecation-only)**:
  - New `docs/MIGRATING_FILTERS.md` mapping the five filter
    primitives (`QuickFilter`, `ColumnFilterOption`,
    `AdvancedFilterConfig`, `SearchConfig`, plus the unified
    `UnifiedFilter` layer) and declaring the canonical path.
  - Barrel exports for the previously-internal unified primitives:
    `src/filters/filter_models.dart` (`UnifiedFilter`,
    `UnifiedFiltersConfig`, `UnifiedFilterType`, `FilterCategory`,
    `FilterState`, `FilterPreset`) and
    `src/filters/unified_filters_controller.dart`
    (`UnifiedFiltersController`).
  - `@Deprecated('Move to InnovareDataTableConfig — removed in
    v0.2.0. See docs/MIGRATING_FILTERS.md')` lands on
    `InnovareDataTable.columnFilters` and
    `InnovareDataTable.advancedFilters` (the two top-level filter
    props that duplicate fields already available on
    `InnovareDataTableConfig`). The widget still honours both for
    v0.0.19+ — apps see the warning and can migrate at their pace.
  - `test/filter_convergence_test.dart`: 4 tests pinning (1) that
    every unified primitive is reachable from the public barrel,
    (2) that the `UnifiedFilter.fromQuickFilter` /
    `.fromAdvancedFilter` / `.search` factories preserve labels,
    and (3) that both deprecated top-level props still mount the
    widget without crashing — regression net for v0.0.19 → v0.2.0.
- **Wave 4 — `InnvTextField` in the enhanced search**: when
  `innovare_design` is installed, the search field above the table
  now renders an `InnvTextField` (focus-reactive prefix icon, haptic
  + shake on error, tokenized fill/border) instead of a plain
  Material `TextField`. The fallback Material path is preserved for
  apps that haven't adopted the design system yet — same API, same
  placeholder, same `onChanged` / `onClear` contract.
- `test/enhanced_search_field_test.dart`: 2 tests pinning the
  branching (DS present → `InnvTextField`; DS absent → `TextField`).
- **Wave 4 cleanup**: 133 `withOpacity(x)` callsites mechanically
  rewritten to `withValues(alpha: x)` across 19 files in `lib/src/`
  and 2 in `example/lib/`. Unused imports / locals / fields trimmed
  where safe. Legacy private methods in `innovare_data_table.dart`
  (`_handleSort`, `_handleSearch`, `_handleFilter`,
  `_buildSkeletonLoading`, `_buildTable`, `_sortRotation`) marked
  with `// ignore: unused_*` comments rather than deleted, so the
  diff is reversible if any of them needs to come back. The
  predictive-loading `catchError` callback was rewritten as an
  `onError`-style `.then` so it no longer trips
  `body_might_complete_normally_catch_error`.
- **Wave 4 — Empty & error states use design-system primitives**:
  - New `InnovareDataTable` props: `emptyTitle`, `emptyMessage`,
    `emptyIcon`, `emptyAction`, `errorMessage`, `onErrorRetry`.
  - When `innovare_design` is installed in the host, the empty
    state renders an `InnvEmptyState` (medallion + reveal motion);
    the error state renders an `InnvErrorState` (danger-tinted
    medallion + `InnvButton` retry). When the design system is
    absent, both fall back to a Material layout driven by the same
    props — apps describe the empty state once, get both paths.
  - `errorMessage` takes precedence over the empty branch. The
    header row is preserved in both states so the user keeps spatial
    context.
  - `test/empty_error_state_test.dart`: 5 tests covering both paths
    (design-system + Material), the error-over-empty precedence
    rule, retry button wiring and the non-empty happy path.
- **`example/` showcase rebuilt (Wave 5)**: every page now lives on
  top of the design system. `AppShell` wraps the whole app, owns
  the active `InnvPreset` (aurora / vibe / slate / lumen) plus
  `Brightness`, and re-themes everything via
  `InnovareDesignTheme.toThemeData()`. `ShellHeader` exposes a
  preset selector + dark toggle on every page. New showcases:
  - `MultiSortShowcase` — live demonstration of Shift+click +
    priority badge, with a side panel that mirrors the stack via
    `onSortsChanged`.
  - `RealtimeShowcase` — buttons that emit synthetic
    `DataTableUpdate`s on a streaming source, plus a live counter
    of `fetch()` calls so the in-place behaviour is visible.
  - `CacheInvalidationShowcase` — a counting fake `http.Client`
    plus a side panel listing every cached request; two buttons
    illustrate "wipe everything" vs `invalidateCache(where: ...)`.
  - Home page (`HomePage`) replaces the old button menu with a
    grid of feature cards. Legacy pages still reachable.

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
