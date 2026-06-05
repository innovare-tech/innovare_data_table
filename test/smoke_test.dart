import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_data_table/src/theme/innovare_design_adapter.dart';
import 'package:innovare_design/innovare_design.dart';

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

  group('innovare_design adapter — color scheme', () {
    testWidgets('toDataTableColorScheme projects brand and status colors',
        (tester) async {
      late DataTableColorScheme resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: InnvPresets.aurora(brightness: Brightness.light).toThemeData(),
          home: Builder(
            builder: (context) {
              final innv = InnovareDesignTheme.of(context);
              resolved = innv.toDataTableColorScheme();
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.primary, isA<Color>());
      expect(resolved.error, isA<Color>());
      // success/warning are no longer the hardcoded Material defaults — they
      // come from the InnvStatusColors.content slot of the host theme.
      expect(resolved.success, isNot(const Color(0xFF4CAF50)));
      expect(resolved.warning, isNot(const Color(0xFFFF9800)));
    });

    testWidgets('InnovareDataTableTheme.of prefers innovare_design when it '
        'is installed in the host', (tester) async {
      late DataTableColorScheme resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: InnvPresets.vibe(brightness: Brightness.dark).toThemeData(),
          home: Builder(
            builder: (context) {
              resolved = InnovareDataTableTheme.of(context).colorScheme;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // No InnovareDataTableTheme widget in the tree: the resolver still
      // picks up the host's innovare_design scheme via the adapter.
      expect(resolved.error, isNot(const Color(0xFFF44336)));
    });
  });

  group('innovare_design adapter — density', () {
    test('toInnvDensityConfig respects DataTableDensity row height ratios',
        () {
      final compact =
          DataTableDensity.compact.toInnvDensityConfig();
      final normal = DataTableDensity.normal.toInnvDensityConfig();
      final comfortable =
          DataTableDensity.comfortable.toInnvDensityConfig();

      expect(compact.rowHeight < normal.rowHeight, isTrue);
      expect(normal.rowHeight < comfortable.rowHeight, isTrue);

      // Cell paddings come from InnvSpacing (12 / 16 / 20).
      expect(compact.cellPadding.horizontal, 24); // 2 * 12
      expect(normal.cellPadding.horizontal, 32); // 2 * 16
      expect(comfortable.cellPadding.horizontal, 40); // 2 * 20
    });

    test('toInnvDensityConfig honours InnvTypography.scale', () {
      final base = DataTableDensity.normal.toInnvDensityConfig();
      final scaled = DataTableDensity.normal.toInnvDensityConfig(
        typography: const InnvTypography(scale: 1.5),
      );

      expect(scaled.fontSize, greaterThan(base.fontSize));
    });

    testWidgets('InnovareDataTableTheme.of injects tokenized density when '
        'innovare_design is installed and consumer did not customize',
        (tester) async {
      late InnovareDataTableThemeData resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: InnvPresets.aurora(brightness: Brightness.light).toThemeData(),
          home: Builder(
            builder: (context) {
              resolved = InnovareDataTableTheme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.density, DataTableDensity.custom);
      expect(resolved.customDensity, isNotNull);
      // Tokenized normal-equivalent: paddings match InnvSpacing.lg/md (32/24).
      expect(resolved.customDensity!.cellPadding.horizontal, 32);
    });
  });

  group('SkeletonLoader', () {
    testWidgets('renders InnvSkeleton when innovare_design is installed',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InnvPresets.vibe(brightness: Brightness.light).toThemeData(),
          home: const Scaffold(
            body: SkeletonLoader(width: 80, height: 16),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(InnvSkeleton), findsOneWidget);
    });

    testWidgets('falls back to Material shimmer when no design theme exists',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(width: 80, height: 16),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(InnvSkeleton), findsNothing);
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });
  });
}
