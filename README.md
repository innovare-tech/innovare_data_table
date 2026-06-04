# innovare_data_table

A Flutter data table for **real product screens** — server-side, sortable,
filterable, mobile-friendly, accessible, and ready to inherit the
[`innovare_design`](https://github.com/innovare-tech/innovare_design) tokens of
its host app.

> Status: `v0.0.18` on `main`. Active work on
> `feat/adopt-innovare-design` — see [`ROADMAP.md`](./ROADMAP.md).

## Why

Most Innovare apps live on dense listing screens (users, transactions,
withdrawals, audit logs, tickets). Each app was reinventing the same wheel —
hover, zebra, sticky, filters, pagination, multi-sort, mobile cards, empty/
error states. This package consolidates that machinery into a single primitive
that:

- Reads its **colors, density and typography from `innovare_design`** when
  available (no hex hardcoded — see `lib/src/theme/innovare_design_adapter.dart`).
- Stays usable on plain Material projects (falls back to `Theme.of(context).colorScheme`).
- Ships with the heavy artillery already wired: HTTP data source with cache and
  realtime stream, multi-sort, unified filters, sticky columns + drag-drop +
  resize, virtual scrolling, mobile cards, keyboard nav, screen-reader
  utilities.

## Features

- **Two modes** — local rows (`InnovareDataTable(rows: ...)`) or server-side
  (`InnovareDataTable.withDataSource(dataSource: ...)`).
- **`DataTableController`** — pagination, multi-column sort, multi-field
  filters, debounced search (300 ms), cache, realtime updates with granular
  mutation (`updateItemWhere`, `notifyDataChanged`).
- **Filtering** — column filters, quick filters, advanced filters, unified
  filters bar with pills (converging into `UnifiedFiltersController` — see
  ROADMAP Wave 3).
- **Columns** — drag-and-drop reorder, resize, sticky leading columns.
- **Responsive** — desktop table ↔ mobile cards via `MobileCardConfig`,
  `pull_to_refresh`, `touch_gestures`.
- **Performance** — virtual scrolling, debounced operations, memory
  optimization, performance monitor.
- **Accessibility** — keyboard navigation, screen-reader utilities,
  high-contrast theme support.

## Installation

This package is **not on pub.dev**. Consume it as a git dependency:

```yaml
dependencies:
  innovare_data_table:
    git:
      url: https://github.com/innovare-tech/innovare_data_table.git
      ref: v0.0.18 # or `main`
```

The package depends on `innovare_design` and `innovare_core`, which are also
distributed as git tags. They are resolved transitively — no need to declare
them again in the consumer.

## Getting started

### Local data

```dart
import 'package:flutter/material.dart';
import 'package:innovare_data_table/innovare_data_table.dart';

class UsersTable extends StatelessWidget {
  const UsersTable({super.key, required this.users});
  final List<User> users;

  @override
  Widget build(BuildContext context) => InnovareDataTable<User>(
        rows: users,
        pageSize: 25,
        columns: [
          DataColumnConfig(
            field: 'name',
            label: 'Name',
            valueGetter: (u) => u.name,
          ),
          DataColumnConfig(
            field: 'email',
            label: 'Email',
            valueGetter: (u) => u.email,
          ),
        ],
      );
}
```

### Server-side with `HttpDataTableSource`

```dart
final controller = DataTableController(
  dataSource: HttpDataTableSource<User>(
    url: 'https://api.example.com/users',
    parser: (json) => User.fromJson(json),
    enableCache: true,
  ),
);

InnovareDataTable<User>.withDataSource(
  controller: controller,
  columns: [...],
);
```

### With `innovare_design` (recommended)

Wrap your app with an `InnovareDesignTheme` (via `InnvPresets.aurora()`,
`vibe()`, `slate()`, `lumen()` or your own `BolaoInnvTheme`). The table picks
the host's colors automatically:

```dart
MaterialApp(
  theme: InnvPresets.vibe(Brightness.light).toThemeData(),
  darkTheme: InnvPresets.vibe(Brightness.dark).toThemeData(),
  home: ...,
)
```

## Example

A full showcase app lives in [`example/`](./example). Run it with:

```powershell
cd example
flutter pub get
flutter run -d chrome
```

(See `ROADMAP.md` — the example is being rewritten in Wave 5 with an
`InnvPreset` selector, dark toggle, and one dedicated page per feature.)

## Roadmap

See [`ROADMAP.md`](./ROADMAP.md) for the seven-wave plan to land design system
adoption, close structural gaps (page indexing, realtime, filter convergence),
add primitives in cells, rewrite the example, and ship `v0.1.0`.

## License

MIT — see [`LICENSE`](./LICENSE).