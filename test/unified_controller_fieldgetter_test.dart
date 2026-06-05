// Regression net for the "fieldGetter trap" that bit the Wave 3.3
// showcase:
//
// `UnifiedFiltersController` historically exposed a top-level
// `fieldGetter` AND `UnifiedFiltersConfig.fieldGetter`. The local-data
// helpers (`applyFiltersToLocalData`, `_applySearchToLocalData`) only
// consulted the top-level one. Apps that copy-pasted from
// `UnifiedFiltersConfig.full(...)` examples (which surface the
// getter on the config) would get a silently-broken search: the
// helpers fell back to `item.toString().contains(...)`, returning
// `'Instance of '...'` and matching nothing.
//
// The constructor now collapses the two slots: if you only set
// `config.fieldGetter`, it propagates to the top-level field. These
// tests pin the new behaviour.

import 'package:flutter_test/flutter_test.dart';
import 'package:innovare_data_table/innovare_data_table.dart';

class _Emp {
  final String name;
  final String role;
  const _Emp(this.name, this.role);
}

String _byField(_Emp e, String field) {
  switch (field) {
    case 'name':
      return e.name;
    case 'role':
      return e.role;
    default:
      return '';
  }
}

void main() {
  final rows = const [
    _Emp('Hugo Iglesias', 'Engineer'),
    _Emp('Felipe Almeida', 'QA Analyst'),
  ];

  test('fieldGetter on `config` only — controller propagates it to '
      'the top-level slot so `applyFiltersToLocalData` works', () {
    final c = UnifiedFiltersController<_Emp>(
      config: UnifiedFiltersConfig<_Emp>.full(
        searchFields: const ['name', 'role'],
        fieldGetter: _byField, // ← only set on the config
      ),
      searchDebounceDelay: Duration.zero,
      // NOTE: no top-level fieldGetter passed.
    );
    addTearDown(c.dispose);

    expect(c.fieldGetter, isNotNull,
        reason: 'The top-level fieldGetter must fall back to the one '
            'on `config` so apps can set it in either place.');

    c.search('Hugo');
    expect(c.applyFiltersToLocalData(rows).map((e) => e.name),
        contains('Hugo Iglesias'));
  });

  test('fieldGetter at top-level takes precedence over `config` one', () {
    String topLevel(_Emp e, String f) => '__top__';
    String fromConfig(_Emp e, String f) => '__config__';

    final c = UnifiedFiltersController<_Emp>(
      config: UnifiedFiltersConfig<_Emp>.full(
        searchFields: const ['name'],
        fieldGetter: fromConfig,
      ),
      fieldGetter: topLevel,
      searchDebounceDelay: Duration.zero,
    );
    addTearDown(c.dispose);

    expect(c.fieldGetter, same(topLevel),
        reason: 'When both slots are set, the explicit top-level '
            'argument wins.');
  });

  test('neither slot set — fieldGetter stays null (old fallback)', () {
    final c = UnifiedFiltersController<_Emp>(
      config: const UnifiedFiltersConfig<_Emp>(searchFields: ['name']),
      searchDebounceDelay: Duration.zero,
    );
    addTearDown(c.dispose);

    expect(c.fieldGetter, isNull);
  });
}
