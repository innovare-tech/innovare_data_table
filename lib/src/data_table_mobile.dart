import 'package:flutter/material.dart';
import 'package:innovare_data_table/src/data_table_theme.dart';

class MobileCardConfig<T> {
  final String Function(T item) titleBuilder;
  final String Function(T item)? subtitleBuilder;
  final Widget Function(T item)? leadingBuilder;
  final Widget Function(T item)? trailingBuilder;
  final List<MobileCardField<T>> fields;
  final EdgeInsets cardPadding;
  final double cardSpacing;
  final BorderRadius cardBorderRadius;

  const MobileCardConfig({
    required this.titleBuilder,
    this.subtitleBuilder,
    this.leadingBuilder,
    this.trailingBuilder,
    required this.fields,
    this.cardPadding = const EdgeInsets.all(16),
    this.cardSpacing = 12,
    this.cardBorderRadius = const BorderRadius.all(Radius.circular(12)),
  });
}

class MobileCardField<T> {
  final String label;
  final String Function(T item) valueBuilder;
  final Widget Function(T item)? customBuilder;
  final IconData? icon;
  final bool showOnlyIfNotEmpty;

  const MobileCardField({
    required this.label,
    required this.valueBuilder,
    this.customBuilder,
    this.icon,
    this.showOnlyIfNotEmpty = false,
  });
}

class MobileCardsView<T> extends StatelessWidget {
  final List<T> items;
  final MobileCardConfig<T> config;
  final bool enableSelection;
  final Set<T> selectedItems;
  final Function(T item)? onSelectionChanged;
  final Function(T item)? onItemTap;
  final DataTableColorScheme colors;
  final ScrollController? scrollController;

  const MobileCardsView({
    super.key,
    required this.items,
    required this.config,
    required this.colors,
    this.enableSelection = false,
    this.selectedItems = const {},
    this.onSelectionChanged,
    this.onItemTap,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.all(config.cardSpacing),
      itemCount: items.length,
      separatorBuilder: (context, index) => SizedBox(height: config.cardSpacing),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildCard(context, item, index);
      },
    );
  }

  Widget _buildCard(BuildContext context, T item, int index) {
    final isSelected = selectedItems.contains(item);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)), // Animação escalonada
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation)),
          child: Opacity(
            opacity: animation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? colors.primaryLight : colors.surface,
                borderRadius: config.cardBorderRadius,
                border: Border.all(
                  color: isSelected
                      ? colors.primary.withOpacity(0.5)
                      : colors.outline.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isSelected ? 0.08 : 0.04),
                    blurRadius: isSelected ? 12 : 6,
                    offset: Offset(0, isSelected ? 4 : 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: config.cardBorderRadius,
                child: InkWell(
                  borderRadius: config.cardBorderRadius,
                  onTap: onItemTap != null ? () => onItemTap!(item) : null,
                  child: Padding(
                    padding: config.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCardHeader(item, isSelected),
                        if (config.fields.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildCardFields(item),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardHeader(T item, bool isSelected) {
    return Row(
      children: [
        // Leading (avatar/icon)
        if (config.leadingBuilder != null) ...[
          AnimatedScale(
            scale: isSelected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: config.leadingBuilder!(item),
          ),
          const SizedBox(width: 12),
        ],

        // Title e Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? colors.primary : colors.onSurface,
                  height: 1.2,
                ),
                child: Text(
                  config.titleBuilder(item),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (config.subtitleBuilder != null) ...[
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurfaceVariant,
                    height: 1.2,
                  ),
                  child: Text(
                    config.subtitleBuilder!(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Trailing e Selection
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (config.trailingBuilder != null) ...[
              config.trailingBuilder!(item),
              const SizedBox(width: 8),
            ],
            if (enableSelection)
              AnimatedScale(
                scale: isSelected ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => onSelectionChanged?.call(item),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardFields(T item) {
    final visibleFields = config.fields.where((field) {
      if (!field.showOnlyIfNotEmpty) return true;
      final value = field.valueBuilder(item);
      return value.isNotEmpty;
    }).toList();

    if (visibleFields.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: visibleFields.asMap().entries.map((entry) {
          final index = entry.key;
          final field = entry.value;
          final isLast = index == visibleFields.length - 1;

          return Column(
            children: [
              _buildFieldRow(field, item),
              if (!isLast) ...[
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: colors.outline.withOpacity(0.2),
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFieldRow(MobileCardField<T> field, T item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícone (se disponível)
        if (field.icon != null) ...[
          Icon(
            field.icon,
            size: 16,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
        ],

        // Label
        SizedBox(
          width: 80,
          child: Text(
            field.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Valor
        Expanded(
          child: field.customBuilder != null
              ? field.customBuilder!(item)
              : Text(
            field.valueBuilder(item),
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurface,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}