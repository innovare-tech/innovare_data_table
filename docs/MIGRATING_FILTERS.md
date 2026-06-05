# Migrating filters — convergence guide (Wave 3.3)

`innovare_data_table` ships **five primitives** that can produce a
filtered view of your rows. Until v0.0.18 they were all wired
independently, and `InnovareDataTable` exposed two redundant ways to
pass them in (top-level props *and* via `InnovareDataTableConfig`).

This document maps the surface, declares which path is **canonical**
going forward, and lists which props are now **`@Deprecated`**. None
of the deprecated paths are removed in this release — they keep
working in v0.0.19+. They will be removed in **v0.2.0**.

---

## TL;DR

```dart
// CANONICAL (v0.0.19+):
InnovareDataTable<Employee>(
  rows: rows,
  columns: cols,
  config: InnovareDataTableConfig<Employee>.withUnifiedFilters(
    quickFilters:    [/* QuickFiltersConfig */],
    advancedFilters: [/* AdvancedFilterConfig */],
    searchFields:    ['name', 'email'],
    fieldGetter:     (item, f) => item.byField(f),
  ),
)

// DEPRECATED (still works, removed in v0.2.0):
InnovareDataTable<Employee>(
  rows: rows,
  columns: cols,
  columnFilters: [/* ColumnFilterOption */],   // ← move to config
  advancedFilters: [/* AdvancedFilterConfig */], // ← move to config
)
```

---

## The five primitives

Each primitive answers a different UX question. They are **ortho-
gonal** — apps usually pick 2-3 of them, not all five.

### 1. `QuickFilter<T>` / `QuickFiltersConfig<T>`

> "Tap to apply a preset" — chips above the table.

Best for: a small set of mutually-exclusive (or compatible) preset
views, e.g. `[All, Active, Pending, Archived]`. Each `QuickFilter`
carries its own `(field, value, operator)` triple plus optional icon
and color.

### 2. `ColumnFilterOption<T>` / `HeaderColumnFilter`

> "Filter from the column header" — inline filter chip per column.

Best for: per-column quick filters discoverable next to the header
sort indicator. The user opens a small popup tied to that column and
picks the operator + value. The result is a `Map<String, dynamic>` of
active per-column filters.

### 3. `AdvancedFilterConfig<T>` / `ActiveFilter` / `AdvancedFiltersDialog`

> "Open a builder" — multi-condition dialog.

Best for: power users who need to combine several conditions across
several fields (e.g. `name contains 'foo' AND created_at >=
2024-01-01 AND status != archived`). The dialog drives a list of
`ActiveFilter`.

### 4. `SearchConfig<T>` / `EnhancedSearchField`

> "Free text on top" — debounced input with suggestions/history.

Best for: global text search. The widget calls back with the raw
search term; you decide which fields it filters against.

### 5. `UnifiedFilter<T>` / `UnifiedFiltersConfig<T>` / `UnifiedFiltersController<T>` *(canonical wrapper)*

> "All of the above behind one controller."

This is the **convergence layer**. It re-uses the four primitives
above (it does not replace them) and exposes them through a single
state container so:

- Filter pills can show every active filter regardless of which
  primitive produced it.
- Apps can dispatch / inspect filters from one place
  (`controller.state.activeFilters`).
- Persistence and presets (`FilterPreset<T>`) operate on the unified
  shape.

Public surface exported by `package:innovare_data_table` from
v0.0.19 onwards:

```dart
// barrel exports (new in 0.0.19):
export 'src/filters/filter_models.dart';
export 'src/filters/unified_filters_controller.dart';
```

You get: `UnifiedFilter<T>`, `UnifiedFilterType`, `FilterCategory`,
`UnifiedFiltersConfig<T>`, `FilterState<T>`, `FilterPreset<T>`,
`UnifiedFiltersController<T>`.

---

## Migration matrix

| You wrote (≤ v0.0.18)                                                 | Write instead (≥ v0.0.19)                                                            |
| --------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `InnovareDataTable(columnFilters: opts, ...)`                         | Move `opts` to `InnovareDataTableConfig` and pass `config:`                          |
| `InnovareDataTable(advancedFilters: cfgs, ...)`                       | Same. The top-level prop is deprecated.                                              |
| `InnovareDataTableConfig(quickFiltersConfigs: q, advancedFiltersConfigs: a)` | Still supported. Prefer `InnovareDataTableConfig.withUnifiedFilters(quickFilters: q, advancedFilters: a, ...)` when you want filter pills + presets. |
| Hand-rolling `_columnFilters`, `_advancedFilters`, `_activeQuickFilters` in your screen | Use `UnifiedFiltersController<T>` — single source of truth, supports presets and persistence. |

---

## Why two paths still exist after this release

We're keeping both surfaces alive across one minor release on
purpose:

- **Backwards compatibility.** Trunk apps that mounted
  `InnovareDataTable(columnFilters: ..., advancedFilters: ...)` keep
  rendering the exact same output. The widget internally folds the
  deprecated props into the same path as the canonical one.
- **Migration room.** v0.0.19 ships a `@Deprecated('Move to
  InnovareDataTableConfig — removed in v0.2.0')` annotation on each
  deprecated prop. Apps see the warning in the IDE *and* in
  `flutter analyze`, with a one-liner pointing to this guide.
- **Removal scheduled.** In **v0.2.0**, both top-level filter props
  will be deleted. The migration is mechanical (one-line move).

---

## Quick recipes

### Filter chips above the table (no dialog)

```dart
InnovareDataTable<Order>(
  rows: rows,
  columns: cols,
  config: InnovareDataTableConfig<Order>(
    enableQuickFilters: true,
    quickFiltersConfigs: [
      QuickFiltersConfig(
        filters: [
          QuickFilter(id: 'all',    label: 'All',    field: '_',      value: null, isDefault: true),
          QuickFilter(id: 'active', label: 'Active', field: 'status', value: 'active'),
          QuickFilter(id: 'paid',   label: 'Paid',   field: 'status', value: 'paid'),
        ],
      ),
    ],
  ),
)
```

### Search + advanced dialog + filter pills, fully unified

```dart
final controller = UnifiedFiltersController<Order>(
  config: UnifiedFiltersConfig<Order>.full(
    quickFilters: [...],
    advancedFilters: [...],
    searchFields: ['id', 'customer', 'product'],
    fieldGetter: (o, f) => o.byField(f),
  ),
  dataTableController: tableController, // optional — drives backend
);

// Watch the state anywhere:
ValueListenableBuilder(
  valueListenable: controller,
  builder: (_, __, ___) {
    final n = controller.state.activeFilters.length;
    return Text('$n active filter(s)');
  },
);
```

### Per-column header filter (still supported, no migration)

```dart
InnovareDataTable<Order>(
  rows: rows,
  columns: cols,
  config: InnovareDataTableConfig<Order>(
    // Column filters live inside the config in v0.0.19+.
    // (Previously also accepted as the top-level `columnFilters:` prop.)
    advancedFiltersConfigs: [
      AdvancedFilterConfig(field: 'status', label: 'Status', /* ... */),
    ],
  ),
)
```

---

## Removal timeline

| Release | What happens                                                            |
| ------- | ----------------------------------------------------------------------- |
| v0.0.19 | This guide ships. `@Deprecated` lands on the two top-level props.       |
| v0.1.0  | Unchanged. Both paths still work. Warnings remain.                      |
| v0.2.0  | Top-level `columnFilters` and `advancedFilters` are removed from `InnovareDataTable`. Migration is a single-line move into `InnovareDataTableConfig`. |

If you have a downstream constraint that requires removing the props
earlier or later, please open an issue and we'll discuss.
