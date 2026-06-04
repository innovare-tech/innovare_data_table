import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innovare_data_table/innovare_data_table.dart';

void main() {
  group('innovare_data_table smoke', () {
    test('public surface — core symbols are importable', () {
      const scheme = DataTableColorScheme();
      expect(scheme.primary, isA<Color>());
      expect(scheme.success, isA<Color>());
      expect(scheme.warning, isA<Color>());

      const themeData = InnovareDataTableThemeData();
      expect(themeData.density, DataTableDensity.normal);
      expect(themeData.densityConfig.rowHeight, DensityConfig.normal.rowHeight);
    });

    test('density configs are stable', () {
      expect(DensityConfig.compact.rowHeight, 40);
      expect(DensityConfig.normal.rowHeight, 52);
      expect(DensityConfig.comfortable.rowHeight, 64);
    });

    testWidgets('InnovareDataTableTheme resolves color scheme from host theme '
        'when consumer passes the hardcoded default', (tester) async {
      late DataTableColorScheme resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          home: InnovareDataTableTheme(
            data: const InnovareDataTableThemeData(),
            child: Builder(
              builder: (context) {
                resolved = InnovareDataTableTheme.of(context).colorScheme;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      // Host primary leaks through (no longer the hardcoded blue default).
      expect(resolved.primary, isNot(const Color(0xFF1976D2)));
    });
  });
}
