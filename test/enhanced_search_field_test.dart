import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_design/innovare_design.dart';

/// Tests for the Wave 4 swap in `enhanced_search_field.dart`:
/// `EnhancedSearchField` now renders an `InnvTextField` when the host
/// installed `innovare_design`, and falls back to a Material `TextField`
/// otherwise.
void main() {
  Widget _withDesign(Widget child) => MaterialApp(
        theme: InnvPresets.resolve(InnvPreset.aurora, Brightness.light)
            .toThemeData(),
        home: Scaffold(body: child),
      );

  Widget _bareMaterial(Widget child) =>
      MaterialApp(home: Scaffold(body: child));

  Widget _field() => Builder(
        builder: (ctx) => EnhancedSearchField<String>(
          config: const SearchConfig<String>(placeholder: 'Buscar produtos'),
          data: const ['apple', 'banana', 'cherry'],
          onChanged: (_) {},
          colors: DataTableColorScheme.fromTheme(ctx),
        ),
      );

  testWidgets('renders an InnvTextField when innovare_design is '
      'installed', (tester) async {
    await tester.pumpWidget(_withDesign(_field()));

    expect(find.byType(InnvTextField), findsOneWidget);
    expect(find.text('Buscar produtos'), findsOneWidget);
  });

  testWidgets('falls back to Material TextField when innovare_design '
      'is absent', (tester) async {
    await tester.pumpWidget(_bareMaterial(_field()));

    expect(find.byType(InnvTextField), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Buscar produtos'), findsOneWidget);
  });
}
