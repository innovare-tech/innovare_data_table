// Regression net for the "search field eats trailing space" bug:
//
// `UnifiedFiltersBar` mirrors `controller.searchTerm` back into its
// internal `TextEditingController` whenever the controller notifies.
// The controller stores the term TRIMMED, but the user is allowed to
// have a trailing space mid-typing (e.g. "felipe " before completing
// the surname). The original implementation compared the raw strings:
// `_searchController.text == currentSearch`. With the trim discrepancy,
// pressing space caused a self-imposed reassignment of the text — the
// caret jumped to the end and the next keystroke replaced the entire
// value, which the user reported as "ele seleciona toda a palavra".
//
// The fix compares the trimmed forms before reassigning so we only
// mirror external changes (preset load, clearSearch, …), never a typed
// trailing space.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innovare_data_table/innovare_data_table.dart';

class _Row {
  final String name;
  const _Row(this.name);
}

Widget _host({required Widget child}) => MaterialApp(
      home: Scaffold(body: child),
    );

UnifiedFiltersBar<_Row> _bar(UnifiedFiltersController<_Row> controller) =>
    UnifiedFiltersBar<_Row>(
      controller: controller,
      data: const [_Row('Felipe Almeida')],
      // The bar only consumes `colors` for chrome — `const` default
      // values are plenty for these tests.
      colors: const DataTableColorScheme(),
    );

/// Locate the search input. The bar mounts a few other `TextField`
/// instances (advanced filter dialog inputs, …) only when expanded,
/// so on first pump the search input is the only one on screen.
Finder _searchInput() => find.byType(TextField).first;

void main() {
  testWidgets('typing a trailing space does not snap the caret '
      'back to the end', (tester) async {
    final controller = UnifiedFiltersController<_Row>(
      config: const UnifiedFiltersConfig<_Row>(searchFields: ['name']),
      // Use zero debounce so the controller flushes its state inside
      // `tester.pump()` without us having to advance fake time.
      searchDebounceDelay: Duration.zero,
      fieldGetter: (r, _) => r.name,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(child: _bar(controller)));

    await tester.enterText(_searchInput(), 'felipe ');
    await tester.pump();

    // `controller.search()` trims to "felipe", but the TextField must
    // still show the user's literal "felipe " (with the trailing
    // space) — otherwise the listener stomped on the input.
    expect(
      tester.widget<TextField>(_searchInput()).controller!.text,
      'felipe ',
      reason: 'The bar must preserve the trailing space the user typed; '
          'mirroring the trimmed `controller.searchTerm` back into the '
          'TextEditingController would erase it.',
    );

    // And the controller itself recorded the trimmed term, as designed.
    expect(controller.searchTerm, 'felipe');
  });

  testWidgets('clearing through `controller.clearSearch()` does '
      'wipe the text field', (tester) async {
    final controller = UnifiedFiltersController<_Row>(
      config: const UnifiedFiltersConfig<_Row>(searchFields: ['name']),
      searchDebounceDelay: Duration.zero,
      fieldGetter: (r, _) => r.name,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(child: _bar(controller)));

    await tester.enterText(_searchInput(), 'felipe');
    await tester.pump();
    expect(
      tester.widget<TextField>(_searchInput()).controller!.text,
      'felipe',
    );

    controller.clearSearch();
    await tester.pump();

    // External clear must wipe the input.
    expect(
      tester.widget<TextField>(_searchInput()).controller!.text,
      '',
    );
  });
}
