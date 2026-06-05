import 'package:flutter/material.dart';
import 'package:innovare_design/innovare_design.dart';
import 'package:innovare_data_table_example/pages/cache_invalidation_showcase.dart';
import 'package:innovare_data_table_example/pages/ds_primitives_showcase.dart';
import 'package:innovare_data_table_example/pages/empty_table_page.dart';
import 'package:innovare_data_table_example/pages/innovare_test_page.dart';
import 'package:innovare_data_table_example/pages/multi_sort_showcase.dart';
import 'package:innovare_data_table_example/pages/products_datatable_example.dart';
import 'package:innovare_data_table_example/pages/realtime_showcase.dart';
import 'package:innovare_data_table_example/pages/unified_filters_showcase.dart';
import 'package:innovare_data_table_example/pages/sales_dashboard_page.dart';
import 'package:innovare_data_table_example/pages/simple_http_test_page.dart';
import 'package:innovare_data_table_example/pages/test_datasource_page.dart';
import 'package:innovare_data_table_example/shell/app_shell.dart';

/// Entry point of the showcase: a tokenized landing page with one card
/// per feature delivered by Waves 0-3. The cards open into focused
/// pages that demonstrate a single feature each — much easier to grok
/// than the historical "menu of buttons" landing.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ShellHeader(
        title: 'innovare_data_table',
        subtitle: 'Showcase — Waves 0 → 3.5 delivered',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(InnvSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  title: 'New craft (Waves 3 & 4)',
                  subtitle: 'Realtime, multi-sort, smart cache invalidation, '
                      '1-indexed pagination — and design-system primitives '
                      'inside the cells.',
                ),
                const SizedBox(height: InnvSpacing.lg),
                _Grid(
                  cards: [
                    _ShowcaseCard(
                      icon: Icons.sort_by_alpha,
                      title: 'Multi-column sort',
                      subtitle: 'Wave 3.4',
                      body: 'Shift+click adds a column to the sort stack. '
                          'A priority badge appears at ≥ 2 columns.',
                      destination: const MultiSortShowcase(),
                    ),
                    _ShowcaseCard(
                      icon: Icons.bolt,
                      title: 'Realtime in-place',
                      subtitle: 'Wave 3.2',
                      body: 'insert / update / delete mutate the current '
                          'page without a fetch — when the row is on screen.',
                      destination: const RealtimeShowcase(),
                    ),
                    _ShowcaseCard(
                      icon: Icons.cached,
                      title: 'Cache invalidation',
                      subtitle: 'Wave 3.5',
                      body: 'Drop only the pages affected by a write via '
                          '`invalidateCache(where: ...)`.',
                      destination: const CacheInvalidationShowcase(),
                    ),
                    _ShowcaseCard(
                      icon: Icons.palette_outlined,
                      title: 'DS primitives in cells',
                      subtitle: 'Wave 4',
                      body: '`InnvColumns.badge` / `.actions` plus the '
                          'tokenized empty + error states.',
                      destination: const DsPrimitivesShowcase(),
                    ),
                    _ShowcaseCard(
                      icon: Icons.filter_alt_outlined,
                      title: 'Unified filters',
                      subtitle: 'Wave 3.3',
                      body: 'One `UnifiedFiltersController` drives '
                          'chips, advanced dialog and search at once.',
                      destination: const UnifiedFiltersShowcase(),
                    ),
                  ],
                ),
                const SizedBox(height: InnvSpacing.xxl),
                _SectionTitle(
                  title: 'Legacy examples',
                  subtitle: 'Carried over from earlier versions. Still '
                      'useful as references for the full API surface.',
                ),
                const SizedBox(height: InnvSpacing.lg),
                _Grid(
                  cards: [
                    _ShowcaseCard(
                      icon: Icons.cloud_outlined,
                      title: 'With DataSource',
                      subtitle: 'Server-side',
                      body: 'Pagination, sort and search driven by a '
                          'LocalDataTableSource.',
                      destination: TestDataSourcePage(),
                    ),
                    _ShowcaseCard(
                      icon: Icons.public,
                      title: 'Simple HTTP',
                      subtitle: 'HttpDataTableSource',
                      body: 'Talks to a real REST endpoint to render rows.',
                      destination: SimpleHttpTestPage(),
                    ),
                    _ShowcaseCard(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Products',
                      subtitle: 'Full toolbar',
                      body: 'Filters, search and column management '
                          'wired together.',
                      destination: ProductsDataTableExample(),
                    ),
                    _ShowcaseCard(
                      icon: Icons.dashboard_outlined,
                      title: 'Sales dashboard',
                      subtitle: 'Charts + table',
                      body: 'Tables embedded inside a richer dashboard '
                          'layout.',
                      destination: SalesDashboardExample(),
                    ),
                    _ShowcaseCard(
                      icon: Icons.inbox_outlined,
                      title: 'Empty state',
                      subtitle: 'Zero rows',
                      body: 'How the table looks (and feels) when there '
                          'is nothing to show.',
                      destination: EmptyTablePage(),
                    ),
                    _ShowcaseCard(
                      icon: Icons.science_outlined,
                      title: 'Innovare test page',
                      subtitle: 'Sandbox',
                      body: 'Scratch page used during day-to-day '
                          'development.',
                      destination: InnovareTestPage(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: InnvSpacing.xs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  final List<_ShowcaseCard> cards;
  const _Grid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 600 ? 2 : 1);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          mainAxisSpacing: InnvSpacing.lg,
          crossAxisSpacing: InnvSpacing.lg,
          childAspectRatio: cols == 1 ? 2.6 : 1.4,
          children: cards,
        );
      },
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String body;
  final Widget destination;

  const _ShowcaseCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => destination),
        ),
        child: Padding(
          padding: const EdgeInsets.all(InnvSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: InnvSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium),
                        Text(
                          subtitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: InnvSpacing.md),
              Expanded(
                child: Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_forward,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
