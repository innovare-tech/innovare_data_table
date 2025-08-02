import 'package:flutter/material.dart' hide DataTableSource;
import 'package:flutter/services.dart';
import 'package:innovare_data_table/src/data_column_config.dart';
import 'package:innovare_data_table/src/data_sources/data_table_controller.dart';
import 'package:innovare_data_table/src/data_sources/data_table_source.dart';
import 'package:innovare_data_table/src/data_table_filters.dart';
import 'package:innovare_data_table/src/data_table_mobile.dart';
import 'package:innovare_data_table/src/data_table_responsive.dart';
import 'package:innovare_data_table/src/data_table_theme.dart';
import 'package:innovare_data_table/src/innovare_stick_data_table.dart';
import 'package:innovare_data_table/src/pure_resizable_header_cell.dart';
import 'package:innovare_data_table/src/quick_actions/quick_action_config.dart';
import 'package:innovare_data_table/src/resizable_header_cell.dart';

import 'package:innovare_data_table/src/search/search_config.dart';
import 'package:innovare_data_table/src/search/enhanced_search_field.dart';
import 'package:innovare_data_table/src/filters/quick_filters.dart';
import 'package:innovare_data_table/src/filters/filter_pills.dart';
import 'package:innovare_data_table/src/columns/column_management.dart';
import 'package:innovare_data_table/src/mobile/touch_gestures.dart';
import 'package:innovare_data_table/src/mobile/pull_to_refresh.dart';
import 'package:innovare_data_table/src/loading/smart_loading.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        );
      },
    );
  }
}

class InnovareDataTableConfig<T> {
  final bool enableSearch;
  final bool enableQuickFilters;
  final bool enableAdvancedFilters;
  final bool enableColumnManagement;
  final bool enableSmartLoading;
  final bool enableMobileOptimizations;

  final SearchConfig<T>? searchConfig;
  final List<QuickFiltersConfig<T>> quickFiltersConfigs;
  final List<AdvancedFilterConfig<T>> advancedFiltersConfigs;
  final TouchGesturesConfig<T>? touchGesturesConfig;
  final LoadingConfiguration? loadingConfig;
  final ColumnManagerController<T>? columnController;

  final Function(List<T> selectedItems)? onBulkAction;
  final Function(T item, String action)? onItemAction;
  final Future<void> Function()? onRefresh;

  const InnovareDataTableConfig({
    this.enableSearch = true,
    this.enableQuickFilters = false,
    this.enableAdvancedFilters = true,
    this.enableColumnManagement = true,
    this.enableSmartLoading = false,
    this.enableMobileOptimizations = true,
    this.searchConfig,
    this.quickFiltersConfigs = const [],
    this.advancedFiltersConfigs = const [],
    this.touchGesturesConfig,
    this.loadingConfig,
    this.columnController,
    this.onBulkAction,
    this.onItemAction,
    this.onRefresh,
  });

  factory InnovareDataTableConfig.simple() {
    return const InnovareDataTableConfig(
      enableQuickFilters: false,
      enableSmartLoading: false,
    );
  }
}

class InnovareDataTable<T> extends StatefulWidget {
  final List<DataColumnConfig<T>> columns;
  final List<T> rows;
  final int pageSize;
  final bool paginationEnabled;
  final void Function(String field, bool ascending)? onSort;
  final Widget Function(T item)? onRowTap;
  final bool isLoading;
  final bool enableSelection;
  final void Function(List<T> selectedItems)? onSelectionChanged;
  final String? title;
  final DataTableDensity density;
  final List<ColumnFilterOption<T>> columnFilters;
  final List<AdvancedFilterConfig<T>> advancedFilters;
  final bool enableResponsive;
  final List<String> priorityColumns;
  final bool showScreenSizeIndicator;
  final MobileCardConfig<T>? mobileConfig;
  final bool enableColumnDragDrop;
  final bool enableColumnResize;
  final ColumnResizeController? resizeController;
  final Function(Map<String, double>)? onColumnWidthChanged;
  final bool enableStickyColumns;
  final void Function(T item)? onRowTapCallback;
  final DataTableSource<T>? dataSource;
  final DataTableController<T>? controller;
  final bool enableServerSide;
  final List<QuickActionConfig> quickActions;

  final InnovareDataTableConfig<T>? config;

  const InnovareDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.pageSize = 10,
    this.paginationEnabled = true,
    this.onSort,
    this.onRowTap,
    this.isLoading = false,
    this.enableSelection = false,
    this.onSelectionChanged,
    this.title,
    this.density = DataTableDensity.normal,
    this.columnFilters = const [],
    this.advancedFilters = const [],
    this.enableResponsive = true,
    this.priorityColumns = const [],
    this.showScreenSizeIndicator = false,
    this.mobileConfig,
    this.enableColumnDragDrop = false,
    this.enableColumnResize = true,
    this.resizeController,
    this.onColumnWidthChanged,
    this.enableStickyColumns = true,
    this.onRowTapCallback,
    this.dataSource,
    this.controller,
    this.enableServerSide = false,
    this.config,
    this.quickActions = const [],
  });

  @override
  State<InnovareDataTable<T>> createState() => _InnovareDataTableState<T>();

  factory InnovareDataTable.withDataSource({
    Key? key,
    required List<DataColumnConfig<T>> columns,
    required DataTableSource<T> dataSource,
    DataTableController<T>? controller,
    int pageSize = 10,
    String? title,
    DataTableDensity density = DataTableDensity.normal,
    List<ColumnFilterOption<T>> columnFilters = const [],
    List<AdvancedFilterConfig<T>> advancedFilters = const [],
    bool enableResponsive = true,
    List<String> priorityColumns = const [],
    bool showScreenSizeIndicator = false,
    MobileCardConfig<T>? mobileConfig,
    bool enableColumnDragDrop = false,
    bool enableColumnResize = true,
    ColumnResizeController? resizeController,
    Function(Map<String, double>)? onColumnWidthChanged,
    bool enableStickyColumns = true,
    void Function(T item)? onRowTapCallback,
    InnovareDataTableConfig<T>? config,
    List<QuickActionConfig> quickActions = const [],
  }) {
    return InnovareDataTable<T>(
      key: key,
      columns: columns,
      rows: const [],
      pageSize: pageSize,
      title: title,
      density: density,
      columnFilters: columnFilters,
      advancedFilters: advancedFilters,
      enableResponsive: enableResponsive,
      priorityColumns: priorityColumns,
      showScreenSizeIndicator: showScreenSizeIndicator,
      mobileConfig: mobileConfig,
      enableColumnDragDrop: enableColumnDragDrop,
      enableColumnResize: enableColumnResize,
      resizeController: resizeController,
      onColumnWidthChanged: onColumnWidthChanged,
      enableStickyColumns: enableStickyColumns,
      onRowTapCallback: onRowTapCallback,
      dataSource: dataSource,
      controller: controller,
      enableServerSide: true,
      config: config,
      quickActions: quickActions,
    );
  }
}

class _InnovareDataTableState<T> extends State<InnovareDataTable<T>>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  String? _sortedField;
  bool _isAscending = true;
  final ScrollController _scrollController = ScrollController();
  final Set<T> _selectedItems = {};
  final Map<String, String> _filters = {};
  final TextEditingController _searchController = TextEditingController();
  final Map<String, dynamic> _columnFilters = {};
  List<ActiveFilter> _advancedFilters = [];
  List<DataColumnConfig<T>> _orderedColumns = [];

  // Controllers de animação
  late AnimationController _sortAnimationController;
  late AnimationController _selectionAnimationController;
  late AnimationController _pageTransitionController;

  // Animações
  late Animation<double> _sortRotation;
  late Animation<double> _selectionScale;
  late Animation<Offset> _pageSlideAnimation;
  late Animation<double> _pageFadeAnimation;

  // Controllers de resize e scroll
  late ColumnResizeController _resizeController;
  late ScrollController _headerScrollController;
  late ScrollController _bodyScrollController;
  late ScrollController _verticalScrollController;

  // DataSource
  DataTableController<T>? _dataController;
  bool _useDataSource = false;

  // Estados da Enhanced (opcionais)
  String _searchTerm = '';
  Set<String> _activeQuickFilters = {};
  late ColumnManagerController<T> _columnManagerController;
  SmartLoadingManager<T>? _loadingManager;

  // Configuração efetiva
  late InnovareDataTableConfig<T> _effectiveConfig;

  @override
  void initState() {
    super.initState();

    // Configuração efetiva (compatibilidade)
    _effectiveConfig = widget.config ?? InnovareDataTableConfig<T>.simple();

    // Inicializar controllers
    _headerScrollController = ScrollController();
    _bodyScrollController = ScrollController();
    _verticalScrollController = ScrollController();

    // Sincronizar scroll
    _headerScrollController.addListener(_onHeaderScroll);
    _bodyScrollController.addListener(_onBodyScroll);

    _initializeAnimations();
    _initializeDragDrop();
    _initializeResize();
    _initializeEnhancedFeatures();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureScrollVisibility();
    });

    _setupDataSource();
  }

  // Inicializar funcionalidades enhanced (opcionais)
  void _initializeEnhancedFeatures() {
    // Column manager
    _columnManagerController = _effectiveConfig.columnController ??
        ColumnManagerController<T>();

    if (_effectiveConfig.enableColumnManagement) {
      _columnManagerController.initialize(widget.columns);
    }

    // Smart loading
    if (_effectiveConfig.enableSmartLoading && widget.dataSource != null) {
      _loadingManager = SmartLoadingManager<T>(
        dataSource: widget.dataSource!,
        config: _effectiveConfig.loadingConfig ?? const LoadingConfiguration(),
      );
    }
  }

  void _setupDataSource() {
    if (widget.dataSource != null) {
      _useDataSource = true;
      _dataController = widget.controller ??
          DataTableController<T>(dataSource: widget.dataSource!);
      _dataController!.addListener(_onDataSourceChanged);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _dataController!.fetchData();
      });
    }
  }

  void _onDataSourceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  List<T> _getEffectiveData() {
    if (_useDataSource && _dataController != null) {
      return _dataController!.currentData;
    }
    return widget.rows;
  }

  bool _getEffectiveIsLoading() {
    if (_useDataSource && _dataController != null) {
      return _dataController!.isLoading;
    }
    return widget.isLoading;
  }

  int _getEffectiveTotalCount() {
    if (_useDataSource && _dataController != null) {
      // Retorna o total do servidor através do controller
      return _dataController!.totalCount;
    }
    // Para dados locais, usa o total filtrado
    return _getFilteredData().length;
  }

  int _getEffectiveCurrentPage() {
    if (_useDataSource && _dataController != null) {
      // Retorna a página atual do controller (que gerencia a página correta)
      return _dataController!.currentResult?.page ?? 0;
    }
    // Para dados locais, usa a página local
    return _currentPage;
  }

  int _getEffectiveTotalPages() {
    final totalCount = _getEffectiveTotalCount();
    final pageSize = _getEffectivePageSize();
    if (totalCount == 0) return 1;
    return (totalCount / pageSize).ceil();
  }

  int _getEffectivePageSize() {
    if (_useDataSource && _dataController != null) {
      return _dataController!.currentResult?.pageSize ?? widget.pageSize;
    }
    return widget.pageSize;
  }

  bool _getEffectiveHasNextPage() {
    if (_useDataSource && _dataController != null) {
      return _dataController!.currentResult?.hasNextPage ?? false;
    }
    // Para dados locais
    return _currentPage < _getEffectiveTotalPages() - 1;
  }

  bool _getEffectiveHasPreviousPage() {
    if (_useDataSource && _dataController != null) {
      return _dataController!.currentResult?.hasPreviousPage ?? false;
    }
    // Para dados locais
    return _currentPage > 0;
  }

  // Métodos de filtragem integrados
  List<T> _getFilteredData() {
    List<T> data = _getEffectiveData();

    // Aplicar busca (enhanced ou básica)
    if (_effectiveConfig.enableSearch && _effectiveConfig.searchConfig != null) {
      // Busca enhanced
      if (_searchTerm.isNotEmpty) {
        data = data.where((item) => _matchesEnhancedSearch(item, _searchTerm)).toList();
      }
    } else {
      // Busca básica (compatibilidade)
      final globalFilter = _filters['__global'];
      if (globalFilter != null && globalFilter.isNotEmpty) {
        final lower = globalFilter.toLowerCase();
        data = data.where((item) {
          for (final col in widget.columns.where((c) => c.filterable)) {
            final value = col.valueGetter(item).toString().toLowerCase();
            if (value.contains(lower)) return true;
          }
          return false;
        }).toList();
      }
    }

    // Aplicar quick filters (se habilitado)
    if (_effectiveConfig.enableQuickFilters && _activeQuickFilters.isNotEmpty) {
      data = _applyQuickFilters(data);
    }

    // Aplicar column filters
    data = _applyColumnFilters(data, _columnFilters, widget.columns);

    // Aplicar filtros avançados
    if (_advancedFilters.isNotEmpty) {
      data = _applyAdvancedFilters(data);
    }

    // Aplicar ordenação (se não estiver usando datasource)
    if (widget.dataSource == null && _sortedField != null) {
      data = _applySorting(data);
    }

    return data;
  }

  bool _matchesEnhancedSearch(T item, String term) {
    final config = _effectiveConfig.searchConfig;
    if (config == null) return true;

    for (final field in config.searchFields) {
      String? value;
      if (config.fieldGetter != null) {
        value = config.fieldGetter!(item, field);
      } else {
        // Fallback: procurar coluna correspondente
        final column = widget.columns.firstWhere(
              (col) => col.field == field,
          orElse: () => widget.columns.first,
        );
        value = column.valueGetter(item).toString();
      }

      if (value.toLowerCase().contains(term.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  List<T> _applyQuickFilters(List<T> data) {
    // TODO: Implementar lógica de quick filters quando os componentes estiverem disponíveis
    return data;
  }

  List<T> _applyAdvancedFilters(List<T> data) {
    var filtered = data;

    for (final filter in _advancedFilters.where((f) => f.isActive)) {
      final column = widget.columns
          .where((c) => c.field == filter.field)
          .firstOrNull;
      if (column == null) continue;

      filtered = filtered.where((item) {
        final itemValue = column.valueGetter(item);
        return _evaluateAdvancedFilter(itemValue, filter);
      }).toList();
    }

    return filtered;
  }

  List<T> _applySorting(List<T> data) {
    if (_sortedField == null) return data;

    final column = widget.columns.firstWhere((col) => col.field == _sortedField);

    data.sort((a, b) {
      final valueA = column.valueGetter(a);
      final valueB = column.valueGetter(b);

      int comparison = 0;
      if (valueA is Comparable && valueB is Comparable) {
        comparison = valueA.compareTo(valueB);
      } else {
        comparison = valueA.toString().compareTo(valueB.toString());
      }

      return _isAscending ? comparison : -comparison;
    });

    return data;
  }

  @override
  Widget build(BuildContext context) {
    final theme = InnovareDataTableTheme.of(context);
    final density = theme.densityConfig;
    final colors = theme.colorScheme;

    final columnsToUse = widget.enableColumnDragDrop ? _orderedColumns : widget.columns;
    final visibleColumns = _getVisibleColumns(
      context,
      columnsToUse,
      widget.priorityColumns,
      widget.enableResponsive,
    );

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _getEffectiveIsLoading()
        ? _buildSkeletonLoading(colors, density)
        : _buildContent(theme, colors, density, visibleColumns),
    );

    // Wrapping com funcionalidades enhanced
    if (_effectiveConfig.enableSmartLoading && _loadingManager != null) {
      content = SmartLoadingIndicator(
        loadingManager: _loadingManager!,
        child: content,
      );
    }

    // Pull to refresh (mobile)
    if (ResponsiveTableManager.isMobile(context) &&
        _effectiveConfig.enableMobileOptimizations &&
        _effectiveConfig.onRefresh != null) {
      content = PullToRefreshWrapper(
        onRefresh: _effectiveConfig.onRefresh,
        colors: colors,
        child: content,
      );
    }

    return content;
  }

  Widget _buildContent(
      InnovareDataTableThemeData theme,
      DataTableColorScheme colors,
      DensityConfig density,
      List<DataColumnConfig<T>> visibleColumns,
      ) {
    // Para DataSource, usa dados já paginados; para dados locais, aplica paginação
    final visibleRows = _getPagedData();

    return FadeTransition(
      opacity: _pageFadeAnimation,
      child: SlideTransition(
        position: _pageSlideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopSection(theme, colors, density),

            if (_effectiveConfig.enableQuickFilters &&
                _effectiveConfig.quickFiltersConfigs.isNotEmpty)
              QuickFiltersBar<T>(
                configs: _effectiveConfig.quickFiltersConfigs,
                data: _useDataSource ? _dataController!.currentData : _getFilteredData(),
                activeFilterIds: _activeQuickFilters,
                onFiltersChanged: (activeIds) {
                  setState(() {
                    _activeQuickFilters = activeIds;
                  });
                },
                colors: colors,
              ),

            if ((_activeQuickFilters.isNotEmpty || _advancedFilters.isNotEmpty) &&
                (_effectiveConfig.enableQuickFilters || widget.advancedFilters.isNotEmpty))
              _buildFilterPills(colors),

            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: widget.enableSelection && _selectedItems.isNotEmpty ? null : 0,
              child: widget.enableSelection && _selectedItems.isNotEmpty
                  ? _buildSelectionBar(colors, density)
                  : const SizedBox.shrink(),
            ),

            _buildTable(theme, colors, density, visibleRows, visibleColumns),

            if (widget.paginationEnabled)
              _buildPagination(_getEffectiveTotalCount(), colors, density),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(
    InnovareDataTableThemeData theme,
    DataTableColorScheme colors,
    DensityConfig density,
  ) {
    final isMobile = ResponsiveTableManager.isMobile(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: ResponsiveTableManager.getTablePadding(context),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: colors.outline, width: 0.5)),
      ),
      child: Column(
        children: [
          // Title row
          if (widget.title != null ||
              (_effectiveConfig.enableColumnManagement && !isMobile) ||
              widget.showScreenSizeIndicator) ...[
            Row(
              children: [
                if (widget.title != null)
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                        letterSpacing: -0.5,
                      ),
                      child: Text(widget.title!),
                    ),
                  ),
                if (_effectiveConfig.enableColumnManagement && !isMobile)
                  IconButton(
                    onPressed: _showColumnManager,
                    icon: Icon(Icons.view_column_rounded, color: colors.onSurfaceVariant),
                    tooltip: 'Gerenciar colunas',
                  ),
                if (widget.showScreenSizeIndicator) ...[
                  const SizedBox(width: 12),
                  const ScreenSizeIndicator(),
                ],
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
          ],

          // Controls
          isMobile ? _buildMobileControls(colors) : _buildDesktopControls(colors),
        ],
      ),
    );
  }

  Widget _buildMobileControls(DataTableColorScheme colors) {
    return Column(
      children: [
        // Search field
        if (_effectiveConfig.enableSearch)
          _buildSearchField(colors),

        if (_effectiveConfig.enableSearch &&
            (widget.advancedFilters.isNotEmpty || _selectedItems.isNotEmpty))
          const SizedBox(height: 12),

        // Action buttons
        Row(
          children: [
            if (widget.advancedFilters.isNotEmpty)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAdvancedFiltersDialog,
                  icon: Icon(Icons.tune_rounded, size: 18, color: colors.primary),
                  label: Text('Filtros', style: TextStyle(color: colors.primary)),
                ),
              ),

            if (widget.advancedFilters.isNotEmpty && _selectedItems.isNotEmpty)
              const SizedBox(width: 12),

            if (_selectedItems.isNotEmpty)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _effectiveConfig.onBulkAction?.call(_selectedItems.toList()),
                  icon: const Icon(Icons.more_horiz, size: 18),
                  label: Text('${_selectedItems.length} selecionados'),
                  style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopControls(DataTableColorScheme colors) {
    return Row(
      children: [
        if (_selectedItems.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 16, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  '${_selectedItems.length} selecionados',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                if (_effectiveConfig.onBulkAction != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _effectiveConfig.onBulkAction?.call(_selectedItems.toList()),
                    child: Icon(Icons.more_horiz, size: 16, color: colors.primary),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
        ] else ...[
          const Spacer(),
        ],

        // Search field
        if (_effectiveConfig.enableSearch)
          SizedBox(
            width: ResponsiveTableManager.getSearchFieldWidth(context),
            child: _buildSearchField(colors),
          ),

        const SizedBox(width: 12),

        // quick actions
        if (widget.quickActions.isNotEmpty)
          _buildQuickActionsContent(widget.quickActions, colors),

        // Filter button
        if (_effectiveConfig.enableAdvancedFilters && _effectiveConfig.advancedFiltersConfigs.isNotEmpty)
          IconButton(
            onPressed: _showAdvancedFiltersDialog,
            icon: Stack(
              children: [
                Icon(Icons.tune_rounded, color: colors.onSurfaceVariant),
                if (_advancedFilters.where((f) => f.isActive).isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filtros avançados',
          ),
      ],
    );
  }

  Widget _buildSearchField(DataTableColorScheme colors) {
    if (_effectiveConfig.searchConfig != null) {
      return EnhancedSearchField<T>(
        config: _effectiveConfig.searchConfig!,
        data: widget.rows,
        initialValue: _searchTerm,
        onChanged: (value) {
          setState(() {
            _searchTerm = value;
          });
        },
        onClear: () {
          setState(() {
            _searchTerm = '';
          });
        },
        colors: colors,
      );
    }

    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          if (value.isEmpty) {
            _filters.remove('__global');
          } else {
            _filters['__global'] = value;
          }
        });
      },
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search_rounded, color: colors.onSurfaceVariant),
        hintText: 'Buscar...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(22)),
        suffixIcon: _filters.containsKey('__global') && _filters['__global']!.isNotEmpty
            ? IconButton(
          icon: Icon(Icons.clear_rounded, size: 18, color: colors.onSurfaceVariant),
          onPressed: () {
            _searchController.clear();
            setState(() {
              _filters.remove('__global');
            });
          },
        )
            : null,
      ),
    );
  }

  Widget _buildFilterPills(DataTableColorScheme colors) {
    final pills = <FilterPill>[];

    // Quick filter pills
    for (final filterId in _activeQuickFilters) {
      // TODO: Implementar quando QuickFilter estiver disponível
    }

    // Advanced filter pills
    for (final filter in _advancedFilters.where((f) => f.isActive)) {
      final config = _effectiveConfig.advancedFiltersConfigs.firstWhere(
            (c) => c.field == filter.field,
        orElse: () => widget.advancedFilters.first,
      );
      pills.add(FilterPill.fromActiveFilter(filter, config.label));
    }

    if (pills.isEmpty) return const SizedBox.shrink();

    return FilterPillsBar(
      pills: pills,
      onRemovePill: (pillId) {
        setState(() {
          _activeQuickFilters.remove(pillId);
          _advancedFilters.removeWhere((f) =>
          '${f.field}_${f.value}' == pillId);
        });
      },
      onClearAll: () {
        setState(() {
          _activeQuickFilters.clear();
          _advancedFilters.clear();
        });
      },
      colors: colors,
    );
  }

  // Todos os outros métodos da InnovareDataTable original permanecem iguais...
  // (incluindo _initializeAnimations, _initializeDragDrop, _initializeResize,
  // _buildTable, _buildDesktopTable, _buildMobileCards, etc.)

  // Adicionar métodos da Enhanced
  void _showColumnManager() {
    showDialog(
      context: context,
      builder: (context) => ColumnManagerDialog<T>(
        controller: _columnManagerController,
        sampleData: widget.rows.take(3).toList(),
        colors: InnovareDataTableTheme.of(context).colorScheme,
        onSave: () {
          setState(() {
            // Atualizar colunas visíveis
          });
        },
      ),
    );
  }

  // Resto dos métodos permanecem os mesmos...
  // (incluindo todos os métodos de build, filtros, sort, etc.)

  void _initializeAnimations() {
    // Animação para sort
    _sortAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sortRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _sortAnimationController, curve: Curves.easeInOut),
    );

    _selectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _selectionScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _selectionAnimationController, curve: Curves.easeInOut),
    );

    _pageTransitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pageSlideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageTransitionController,
      curve: Curves.easeOutCubic,
    ));
    _pageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageTransitionController, curve: Curves.easeOut),
    );

    _pageTransitionController.forward();
  }

  void _initializeDragDrop() {
    _orderedColumns = List.from(widget.columns);
  }

  void _initializeResize() {
    _resizeController = widget.resizeController ?? ColumnResizeController();

    _resizeController.addListener(() {
      if (widget.onColumnWidthChanged != null) {
        widget.onColumnWidthChanged!(_resizeController.getAllWidths());
      }
      _ensureScrollVisibility();
    });
  }

  void _onHeaderScroll() {
    if (!mounted) return;

    if (_bodyScrollController.hasClients &&
        _headerScrollController.hasClients) {
      final headerOffset = _headerScrollController.offset;
      if ((_bodyScrollController.offset - headerOffset).abs() > 1.0) {
        _bodyScrollController.jumpTo(headerOffset);
      }
    }
  }

  void _onBodyScroll() {
    if (!mounted) return;

    if (_headerScrollController.hasClients &&
        _bodyScrollController.hasClients) {
      final bodyOffset = _bodyScrollController.offset;
      if ((_headerScrollController.offset - bodyOffset).abs() > 1.0) {
        _headerScrollController.jumpTo(bodyOffset);
      }
    }
  }

  void _ensureScrollVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_headerScrollController.hasClients) {
        final headerPosition = _headerScrollController.position;
        print('🔍 HEADER SCROLL: maxScrollExtent: ${headerPosition.maxScrollExtent}');
      }

      if (_bodyScrollController.hasClients) {
        final bodyPosition = _bodyScrollController.position;
        print('🔍 BODY SCROLL: maxScrollExtent: ${bodyPosition.maxScrollExtent}');
      }
    });
  }

  bool _hasStickyColumns(List<DataColumnConfig<T>> columns) {
    return columns.any((col) => col.isStickyEnabled);
  }

  void _reorderColumns(int fromIndex, int toIndex) {
    setState(() {
      if (toIndex > fromIndex) {
        toIndex -= 1;
      }

      final item = _orderedColumns.removeAt(fromIndex);
      _orderedColumns.insert(toIndex, item);
    });

    HapticFeedback.mediumImpact();
  }

  void _toggleSelection(T item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
        _selectionAnimationController.forward().then((_) {
          _selectionAnimationController.reverse();
        });
      }
      widget.onSelectionChanged?.call(_selectedItems.toList());
    });
  }

  void _toggleSelectAll(List<T> items) {
    setState(() {
      final allSelected = items.every(_selectedItems.contains);
      if (allSelected) {
        items.forEach(_selectedItems.remove);
      } else {
        _selectedItems.addAll(items);
      }
      widget.onSelectionChanged?.call(_selectedItems.toList());
    });
  }

  void _changePage(int newPage) {
    if (_useDataSource && _dataController != null) {
      // Para DataSource, usa o método do controller que faz a requisição ao servidor
      _dataController!.goToPage(newPage);
    } else {
      // Para dados locais, apenas muda a página local
      setState(() {
        _currentPage = newPage;
      });
      _pageTransitionController.reset();
      _pageTransitionController.forward();
    }
  }

  void _previousPage() {
    if (_useDataSource && _dataController != null) {
      _dataController!.previousPage();
    } else {
      if (_currentPage > 0) {
        _changePage(_currentPage - 1);
      }
    }
  }

  void _nextPage() {
    if (_useDataSource && _dataController != null) {
      _dataController!.nextPage();
    } else {
      if (_currentPage < _getEffectiveTotalPages() - 1) {
        _changePage(_currentPage + 1);
      }
    }
  }

  List<T> _getPagedData() {
    if (_useDataSource && _dataController != null) {
      // Para DataSource, os dados já vêm paginados do servidor
      return _dataController!.currentData;
    }

    // Para dados locais, aplica paginação manual
    final filtered = _getFilteredData();
    if (!widget.paginationEnabled) return filtered;

    final start = _currentPage * widget.pageSize;
    final end = (start + widget.pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  bool _evaluateAdvancedFilter(dynamic value, ActiveFilter filter) {
    if (value == null) {
      switch (filter.operator) {
        case FilterOperator.isEmpty:
          return true;
        case FilterOperator.isNotEmpty:
          return false;
        default:
          return false;
      }
    }

    final valueStr = value.toString();
    final filterValueStr = filter.value?.toString() ?? '';

    switch (filter.operator) {
      case FilterOperator.equals:
        return valueStr.trim().toLowerCase() == filterValueStr.trim().toLowerCase();
      case FilterOperator.notEquals:
        return valueStr.trim().toLowerCase() != filterValueStr.trim().toLowerCase();
      case FilterOperator.contains:
        if (filterValueStr.isEmpty) return true;
        return valueStr.toLowerCase().contains(filterValueStr.toLowerCase());
      case FilterOperator.notContains:
        if (filterValueStr.isEmpty) return false;
        return !valueStr.toLowerCase().contains(filterValueStr.toLowerCase());
      case FilterOperator.startsWith:
        if (filterValueStr.isEmpty) return true;
        return valueStr.toLowerCase().startsWith(filterValueStr.toLowerCase());
      case FilterOperator.endsWith:
        if (filterValueStr.isEmpty) return true;
        return valueStr.toLowerCase().endsWith(filterValueStr.toLowerCase());
      case FilterOperator.greaterThan:
        return _compareNumbers(value, filter.value, (a, b) => a > b);
      case FilterOperator.lessThan:
        return _compareNumbers(value, filter.value, (a, b) => a < b);
      case FilterOperator.between:
        return _isNumberInRange(value, filter.value, filter.secondValue);
      case FilterOperator.isEmpty:
        return valueStr.trim().isEmpty;
      case FilterOperator.isNotEmpty:
        return valueStr.trim().isNotEmpty;
    }
  }

  bool _compareNumbers(dynamic value1, dynamic value2, bool Function(double, double) comparison) {
    final num1 = _parseNumber(value1);
    final num2 = _parseNumber(value2);

    if (num1 == null || num2 == null) {
      return comparison(value1.toString().length.toDouble(), value2.toString().length.toDouble());
    }

    return comparison(num1, num2);
  }

  bool _isNumberInRange(dynamic value, dynamic min, dynamic max) {
    final numValue = _parseNumber(value);
    final numMin = _parseNumber(min);
    final numMax = _parseNumber(max);

    if (numValue == null || numMin == null || numMax == null) {
      final valueStr = value.toString();
      final minStr = min.toString();
      final maxStr = max.toString();
      return valueStr.compareTo(minStr) >= 0 && valueStr.compareTo(maxStr) <= 0;
    }

    return numValue >= numMin && numValue <= numMax;
  }

  double? _parseNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    String str = value.toString().trim();
    str = str.replaceAll(RegExp(r'[^\d.,-]'), '');
    str = str.replaceAll(',', '.');

    return double.tryParse(str);
  }

  void _onColumnFilterChanged(String field, dynamic value) {
    setState(() {
      if (value == null || value.toString().isEmpty) {
        _columnFilters.remove(field);
      } else {
        _columnFilters[field] = value;
      }
    });
  }

  Widget _buildSkeletonLoading(DataTableColorScheme colors, DensityConfig density) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Skeleton do top section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(bottom: BorderSide(color: colors.outline, width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SkeletonLoader(width: 200, height: 28, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 20),
              SkeletonLoader(width: 350, height: 44, borderRadius: BorderRadius.circular(22)),
              const SizedBox(width: 12),
              SkeletonLoader(width: 44, height: 44, borderRadius: BorderRadius.circular(8)),
            ],
          ),
        ),

        // Skeleton do header
        Container(
          height: density.headerHeight,
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            border: Border(bottom: BorderSide(color: colors.outline, width: 0.5)),
          ),
          padding: density.headerPadding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final selectionWidth = widget.enableSelection ? 60.0 : 0.0;
              final remainingWidth = availableWidth - selectionWidth;
              final columnWidth = 200.0;
              final maxColumns = (remainingWidth / columnWidth).floor().clamp(1, widget.columns.length);

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (widget.enableSelection) ...[
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SkeletonLoader(width: 20, height: 20, borderRadius: BorderRadius.circular(3)),
                      ),
                    ],
                    ...List.generate(maxColumns, (index) => Container(
                      width: columnWidth,
                      padding: const EdgeInsets.only(right: 16),
                      child: SkeletonLoader(
                        width: 120,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ],
                ),
              );
            },
          ),
        ),

        // Skeleton das linhas
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final selectionWidth = widget.enableSelection ? 60.0 : 0.0;
              final remainingWidth = availableWidth - selectionWidth;
              final columnWidth = 200.0;
              final maxColumns = (remainingWidth / columnWidth).floor().clamp(1, widget.columns.length);

              return ListView.builder(
                itemCount: widget.pageSize.clamp(0, 5),
                itemBuilder: (context, index) => Container(
                  height: density.rowHeight,
                  decoration: BoxDecoration(
                    color: index.isEven ? colors.surface : colors.surfaceVariant.withOpacity(0.3),
                    border: Border(bottom: BorderSide(color: colors.outline.withOpacity(0.3), width: 0.5)),
                  ),
                  padding: density.cellPadding,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (widget.enableSelection) ...[
                          Container(
                            width: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SkeletonLoader(width: 20, height: 20, borderRadius: BorderRadius.circular(3)),
                          ),
                        ],
                        ...List.generate(maxColumns, (index) => Container(
                          width: columnWidth,
                          padding: const EdgeInsets.only(right: 16),
                          child: SkeletonLoader(
                            width: double.infinity,
                            height: 14,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Skeleton da paginação
        if (widget.paginationEnabled)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border(top: BorderSide(color: colors.outline, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonLoader(width: 180, height: 14, borderRadius: BorderRadius.circular(4)),
                Row(
                  children: [
                    SkeletonLoader(width: 80, height: 14, borderRadius: BorderRadius.circular(4)),
                    const SizedBox(width: 16),
                    SkeletonLoader(width: 40, height: 40, borderRadius: BorderRadius.circular(8)),
                    const SizedBox(width: 8),
                    SkeletonLoader(width: 40, height: 40, borderRadius: BorderRadius.circular(8)),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSelectionBar(DataTableColorScheme colors, DensityConfig density) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colors.primaryLight,
        border: Border(bottom: BorderSide(color: colors.outline, width: 0.5)),
      ),
      child: ScaleTransition(
        scale: _selectionScale,
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: colors.primary, size: 20),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                '${_selectedItems.length} ${_selectedItems.length == 1 ? 'item selecionado' : 'itens selecionados'}',
                key: ValueKey(_selectedItems.length),
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: density.fontSize,
                ),
              ),
            ),
            const Spacer(),
            AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 200),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedItems.clear();
                    widget.onSelectionChanged?.call([]);
                  });
                },
                icon: Icon(Icons.clear_rounded, size: 16, color: colors.primary),
                label: Text(
                  'Limpar seleção',
                  style: TextStyle(color: colors.primary, fontSize: density.fontSize),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(
      InnovareDataTableThemeData theme,
      DataTableColorScheme colors,
      DensityConfig density,
      List<T> visibleRows,
      List<DataColumnConfig<T>> visibleColumns,
      ) {
    final isMobile = ResponsiveTableManager.isMobile(context);

    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: visibleRows.isEmpty
            ? _buildEmptyTable(theme, colors, density, visibleColumns)
            : (isMobile && widget.mobileConfig != null
                ? _buildMobileCards(visibleRows, colors)
                : _buildDesktopTable(theme, colors, density, visibleRows, visibleColumns)),
      ),
    );
  }

  Widget _buildEmptyTable(
      InnovareDataTableThemeData theme,
      DataTableColorScheme colors,
      DensityConfig density,
      List<DataColumnConfig<T>> visibleColumns,
      ) {
    return AnimatedBuilder(
      animation: _resizeController,
      builder: (context, child) {
        return Column(
          children: [
            _buildFixedRegularHeader(theme, colors, density, <T>[], visibleColumns),
            Expanded(
              child: _buildEmpty(colors),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileCards(List<T> visibleRows, DataTableColorScheme colors) {
    return MobileCardsView<T>(
      key: const ValueKey('mobile_cards'),
      items: visibleRows,
      config: widget.mobileConfig!,
      colors: colors,
      enableSelection: widget.enableSelection,
      selectedItems: _selectedItems,
      onSelectionChanged: _toggleSelection,
      onItemTap: widget.onRowTap,
      scrollController: _scrollController,
    );
  }

  Widget _buildDesktopTable(
      InnovareDataTableThemeData theme,
      DataTableColorScheme colors,
      DensityConfig density,
      List<T> visibleRows,
      List<DataColumnConfig<T>> visibleColumns,
      ) {
    if (widget.enableStickyColumns && _hasStickyColumns(visibleColumns)) {
      return _buildStickyTable(theme, colors, density, visibleRows, visibleColumns);
    }

    return AnimatedBuilder(
      animation: _resizeController,
      builder: (context, child) {
        return Column(
          children: [
            _buildFixedRegularHeader(theme, colors, density, visibleRows, visibleColumns),
            Expanded(
              child: _buildFixedRegularBody(theme, colors, density, visibleRows, visibleColumns),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFixedRegularHeader(
      InnovareDataTableThemeData theme,
      DataTableColorScheme colors,
      DensityConfig density,
      List<T> visibleRows,
      List<DataColumnConfig<T>> visibleColumns,
      ) {
    return Container(
      height: density.headerHeight,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        border: Border(bottom: BorderSide(color: colors.outline, width: 0.5)),
      ),
      child: Row(
        children: [
          if (widget.enableSelection)
            _buildSelectionHeaderCell(colors, density, visibleRows),
          Expanded(
            child: _buildScrollableHeaderRow(theme, colors, density, visibleColumns),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionHeaderCell(
      DataTableColorScheme colors,
      DensityConfig density,
      List<T> visibleRows,
      ) {
    return Container(
      width: 60,
      height: density.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        border: Border(right: BorderSide(color: colors.outline.withOpacity(0.3))),
      ),
      child: Center(
        child: Checkbox(
          value: visibleRows.isNotEmpty && visibleRows.every(_selectedItems.contains),
          onChanged: (_) => _toggleSelectAll(visibleRows),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildSelectionBodyColumn(
      DataTableColorScheme colors,
      DensityConfig density,
      List<T> visibleRows,
      ) {
    return Container(
      width: 60,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: colors.outline.withOpacity(0.3))),
      ),
      child: ListView.builder(
        controller: _verticalScrollController,
        itemCount: visibleRows.length,
        itemBuilder: (context, index) {
          final item = visibleRows[index];
          final isSelected = _selectedItems.contains(item);

          return Container(
            height: density.rowHeight,
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primaryLight
                  : index.isEven
                  ? colors.surface
                  : colors.surfaceVariant.withOpacity(0.3),
              border: Border(bottom: BorderSide(
                color: colors.outline.withOpacity(0.3),
                width: 0.5,
              )),
            ),
            child: Center(
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelection(item),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScrollableHeaderRow(
      InnovareDataTableThemeData theme,
      DataTableColorScheme colors,
      DensityConfig density,
      List<DataColumnConfig<T>> visibleColumns,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double totalWidth = 0;
        for (final column in visibleColumns) {
          final width = _resizeController.getColumnWidth(
            column.field,
            defaultWidth: column.effectiveWidth,
          );
          totalWidth += width + 16;
        }

        final needsScroll = totalWidth > constraints.maxWidth;

        return Scrollbar(
          controller: _headerScrollController,
          thumbVisibility: needsScroll,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _headerScrollController,
            scrollDirection: Axis.horizontal,
            physics: needsScroll
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: Container(
              width: needsScroll ? totalWidth : constraints.maxWidth,
              height: density.headerHeight,
              padding: density.headerPadding,
              child: Row(
                children: visibleColumns.asMap().entries.map((entry) {
                  final index = entry.key;
                  final column = entry.value;
                  return _buildSingleHeaderCell(column, index, theme, colors, density);
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrollableBodyContent(
      InnovareDataTableThemeData theme,
      DataTableColorScheme colors,
      DensityConfig density,
      List<T> visibleRows,
      List<DataColumnConfig<T>> visibleColumns,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double totalWidth = 0;
        for (final column in visibleColumns) {
          final width = _resizeController.getColumnWidth(
            column.field,
            defaultWidth: column.effectiveWidth,
          );
          totalWidth += width + 16;
        }

        final needsScroll = totalWidth > constraints.maxWidth;

        return Scrollbar(
          controller: _bodyScrollController,
          thumbVisibility: needsScroll,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _bodyScrollController,
            scrollDirection: Axis.horizontal,
            physics: needsScroll
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: Container(
              width: needsScroll ? totalWidth : constraints.maxWidth,
              child: ListView.builder(
                controller: _verticalScrollController,
                itemCount: visibleRows.length,
                itemBuilder: (context, index) {
                  final item = visibleRows[index];
                  return _buildSingleDataRow(item, index, colors, density, visibleColumns);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleHeaderCell(
      DataColumnConfig<T> column,
      int index,
      InnovareDataTableThemeData theme,
      DataTableColorScheme colors,
      DensityConfig density,
      ) {
    final currentWidth = _resizeController.getColumnWidth(
      column.field,
      defaultWidth: column.effectiveWidth,
    );

    if (widget.enableColumnDragDrop && widget.enableColumnResize) {
      return ResizableHeaderCell<T>(
        key: ValueKey('regular_resizable_${column.field}'),
        column: column,
        index: index,
        theme: theme,
        colors: colors,
        density: density,
        columnFilters: widget.columnFilters,
        columnFiltersState: _columnFilters,
        onColumnFilterChanged: _onColumnFilterChanged,
        onColumnReorder: _reorderColumns,
        resizeController: _resizeController,
        enableDragDrop: widget.enableColumnDragDrop,
        enableResize: widget.enableColumnResize,
        currentSortField: _sortedField,
        isAscending: _isAscending,
        onSort: (field, ascending) {
          setState(() {
            _sortedField = field;
            _isAscending = ascending;
            widget.onSort?.call(field, ascending);
          });
        },
      );
    } else if (widget.enableColumnResize) {
      return PureResizableHeaderCell<T>(
        key: ValueKey('regular_pure_resizable_${column.field}'),
        column: column,
        index: index,
        theme: theme,
        colors: colors,
        density: density,
        columnFilters: widget.columnFilters,
        columnFiltersState: _columnFilters,
        onColumnFilterChanged: _onColumnFilterChanged,
        resizeController: _resizeController,
        enableResize: widget.enableColumnResize,
        currentSortField: _sortedField,
        isAscending: _isAscending,
        onSort: (field, ascending) {
          setState(() {
            _sortedField = field;
            _isAscending = ascending;
            widget.onSort?.call(field, ascending);
          });
        },
      );
    } else {
      return _buildStaticHeaderCellFixed(column, currentWidth, colors, density);
    }
  }

  Widget _buildSingleDataRow(
      T item,
      int index,
      DataTableColorScheme colors,
      DensityConfig density,
      List<DataColumnConfig<T>> visibleColumns,
      ) {
    final isSelected = _selectedItems.contains(item);

    return InkWell(
      onTap: widget.onRowTapCallback != null ? () {
        widget.onRowTapCallback!(item);
      } : null,
      child: Container(
        height: density.rowHeight,
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryLight
              : index.isEven
              ? colors.surface
              : colors.surfaceVariant.withOpacity(0.3),
          border: Border(bottom: BorderSide(
            color: colors.outline.withOpacity(0.3),
            width: 0.5,
          )),
        ),
        child: Padding(
          padding: density.cellPadding,
          child: Row(
            children: visibleColumns.map((column) {
              final columnWidth = _resizeController.getColumnWidth(
                column.field,
                defaultWidth: column.effectiveWidth,
              );

              return Container(
                width: columnWidth,
                padding: const EdgeInsets.only(right: 16),
                alignment: column.alignment,
                child: column.cellBuilder != null
                    ? column.cellBuilder!(item)
                    : Text(
                  column.valueGetter(item).toString(),
                  style: TextStyle(
                    fontSize: density.fontSize,
                    color: colors.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStaticHeaderCellFixed(
      DataColumnConfig<T> column,
      double width,
      DataTableColorScheme colors,
      DensityConfig density,
      ) {
    final isSorted = _sortedField == column.field;
    final filterOption = widget.columnFilters
        .where((f) => f.field == column.field)
        .firstOrNull;

    return Container(
      width: width,
      padding: const EdgeInsets.only(right: 16),
      height: density.headerHeight,
      child: Container(
        alignment: column.alignment,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: column.sortable ? () {
                  setState(() {
                    if (_sortedField == column.field) {
                      _isAscending = !_isAscending;
                    } else {
                      _sortedField = column.field;
                      _isAscending = true;
                    }
                    widget.onSort?.call(_sortedField!, _isAscending);
                  });
                } : null,
                child: MouseRegion(
                  cursor: column.sortable ? SystemMouseCursors.click : SystemMouseCursors.basic,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          column.label,
                          style: TextStyle(
                            fontSize: density.headerFontSize,
                            fontWeight: FontWeight.w600,
                            color: isSorted ? colors.primary : colors.onSurface,
                            height: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (column.sortable) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isSorted
                              ? (_isAscending ? Icons.arrow_upward : Icons.arrow_downward)
                              : Icons.unfold_more,
                          size: 14,
                          color: isSorted ? colors.primary : colors.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (filterOption != null) ...[
              const SizedBox(width: 4),
              SizedBox(
                width: 20,
                height: 20,
                child: HeaderColumnFilter(
                  filterOption: filterOption,
                  currentValue: _columnFilters[column.field],
                  onFilterChanged: _onColumnFilterChanged,
                  colors: colors,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFixedRegularBody(
      InnovareDataTableThemeData theme,
      DataTableColorScheme colors,
      DensityConfig density,
      List<T> visibleRows,
      List<DataColumnConfig<T>> visibleColumns,
      ) {
    return Row(
      children: [
        if (widget.enableSelection)
          _buildSelectionBodyColumn(colors, density, visibleRows),
        Expanded(
          child: _buildScrollableBodyContent(theme, colors, density, visibleRows, visibleColumns),
        ),
      ],
    );
  }

  Widget _buildStickyTable(
      InnovareDataTableThemeData theme,
      DataTableColorScheme colors,
      DensityConfig density,
      List<T> visibleRows,
      List<DataColumnConfig<T>> visibleColumns,
      ) {
    return StickyDataTable<T>(
      key: const ValueKey('sticky_table'),
      columns: visibleColumns,
      rows: visibleRows,
      theme: theme,
      colors: colors,
      density: density,
      resizeController: _resizeController,
      enableSelection: widget.enableSelection,
      selectedItems: _selectedItems,
      onSelectionChanged: _toggleSelection,
      onSelectAll: _toggleSelectAll,
      enableColumnResize: widget.enableColumnResize,
      enableColumnDragDrop: widget.enableColumnDragDrop,
      onColumnReorder: _reorderColumns,
      currentSortField: _sortedField,
      isAscending: _isAscending,
      onSort: (field, ascending) {
        setState(() {
          _sortedField = field;
          _isAscending = ascending;
          widget.onSort?.call(field, ascending);
        });
      },
      columnFilters: widget.columnFilters,
      columnFiltersState: _columnFilters,
      onColumnFilterChanged: _onColumnFilterChanged,
    );
  }

  List<DataColumnConfig<T>> _getVisibleColumns<T>(
      BuildContext context,
      List<DataColumnConfig<T>> allColumns,
      List<String> priorityColumns,
      bool enableResponsive,
      ) {
    if (!enableResponsive) return allColumns;

    final maxColumns = ResponsiveTableManager.getMaxVisibleColumns(context);

    if (allColumns.length <= maxColumns) {
      return allColumns;
    }

    final priorityList = <DataColumnConfig<T>>[];
    final normalList = <DataColumnConfig<T>>[];

    for (final column in allColumns) {
      if (priorityColumns.contains(column.field)) {
        priorityList.add(column);
      } else {
        normalList.add(column);
      }
    }

    priorityList.sort((a, b) {
      final indexA = priorityColumns.indexOf(a.field);
      final indexB = priorityColumns.indexOf(b.field);
      return indexA.compareTo(indexB);
    });

    final result = <DataColumnConfig<T>>[];
    result.addAll(priorityList);

    final remaining = maxColumns - result.length;
    if (remaining > 0) {
      result.addAll(normalList.take(remaining));
    }

    return result.take(maxColumns).toList();
  }

  List<T> _applyColumnFilters<T>(
      List<T> original,
      Map<String, dynamic> columnFilters,
      List<DataColumnConfig<T>> columns,
      ) {
    var filtered = original;

    for (final entry in columnFilters.entries) {
      final field = entry.key;
      final filterValue = entry.value;

      if (filterValue == null || filterValue.toString().isEmpty) continue;

      final column = columns.where((c) => c.field == field).firstOrNull;
      if (column == null) continue;

      filtered = filtered.where((item) {
        final itemValue = column.valueGetter(item);
        if (itemValue == null) return false;

        return itemValue
            .toString()
            .toLowerCase()
            .contains(filterValue.toString().toLowerCase());
      }).toList();
    }

    return filtered;
  }

  Widget _buildPagination(int filteredCount, DataTableColorScheme colors, DensityConfig density) {
    final totalCount = _getEffectiveTotalCount();
    final currentPage = _getEffectiveCurrentPage();
    final totalPages = _getEffectiveTotalPages();
    final pageSize = _getEffectivePageSize();
    final hasNextPage = _getEffectiveHasNextPage();
    final hasPreviousPage = _getEffectiveHasPreviousPage();

    final start = (currentPage * pageSize) - (pageSize - 1);
    final end = (start + (pageSize - 1)).clamp(0, totalCount);
    final actualEnd = _useDataSource ?
    (start + _dataController!.currentData.length) : end;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(top: BorderSide(color: colors.outline, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              'Mostrando ${start}-${actualEnd} de $totalCount resultados',
              key: ValueKey('$start-$actualEnd-$totalCount'),
              style: TextStyle(
                fontSize: density.fontSize,
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  'Página ${currentPage} de $totalPages',
                  key: ValueKey('page-${currentPage}-$totalPages'),
                  style: TextStyle(
                    fontSize: density.fontSize,
                    color: colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              MouseRegion(
                cursor: hasPreviousPage ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: hasPreviousPage ? Colors.transparent : colors.surfaceVariant.withOpacity(0.5),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: hasPreviousPage ? colors.onSurfaceVariant : colors.onSurfaceVariant.withOpacity(0.5),
                    ),
                    onPressed: hasPreviousPage ? _previousPage : null,
                  ),
                ),
              ),
              MouseRegion(
                cursor: hasNextPage ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: hasNextPage ? Colors.transparent : colors.surfaceVariant.withOpacity(0.5),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: hasNextPage ? colors.onSurfaceVariant : colors.onSurfaceVariant.withOpacity(0.5),
                    ),
                    onPressed: hasNextPage ? _nextPage : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleSort(String field, bool ascending) {
    if (_useDataSource && _dataController != null) {
      // Para DataSource, usa o método do controller
      _dataController!.sort(field, ascending);
    } else {
      // Para dados locais, aplica ordenação local
      setState(() {
        _sortedField = field;
        _isAscending = ascending;
        widget.onSort?.call(field, ascending);
      });
    }
  }

  void _handleSearch(String searchTerm) {
    if (_useDataSource && _dataController != null) {
      // Para DataSource, usa o método do controller
      _dataController!.search(searchTerm);
    } else {
      // Para dados locais, aplica busca local
      setState(() {
        if (searchTerm.isEmpty) {
          _filters.remove('__global');
        } else {
          _filters['__global'] = searchTerm;
        }
      });
    }
  }

  void _handleFilter(String field, dynamic value) {
    if (_useDataSource && _dataController != null) {
      // Para DataSource, usa o método do controller
      if (value == null || value.toString().isEmpty) {
        _dataController!.removeFilter(field);
      } else {
        _dataController!.addFilter(field, value);
      }
    } else {
      // Para dados locais, aplica filtro local
      setState(() {
        if (value == null || value.toString().isEmpty) {
          _columnFilters.remove(field);
        } else {
          _columnFilters[field] = value;
        }
      });
    }
  }

  Widget _buildEmpty(DataTableColorScheme colors) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: Icon(
                      Icons.inbox_rounded,
                      size: 64,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Text(
                      'Nenhum dado encontrado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Text(
                      'Tente ajustar os filtros ou adicionar novos dados',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAdvancedFiltersDialog() {
    final theme = InnovareDataTableTheme.of(context);
    final colors = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AdvancedFiltersDialog<T>(
        filterConfigs: _effectiveConfig.advancedFiltersConfigs,
        currentFilters: _advancedFilters,
        onFiltersChanged: (filters) {
          setState(() {
            _advancedFilters = filters;
          });
        },
        colors: colors,
      ),
    );
  }

  @override
  void dispose() {
    _dataController?.removeListener(_onDataSourceChanged);
    if (widget.controller == null) {
      _dataController?.dispose();
    }

    _headerScrollController.removeListener(_onHeaderScroll);
    _bodyScrollController.removeListener(_onBodyScroll);

    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    _verticalScrollController.dispose();

    _scrollController.dispose();
    _searchController.dispose();
    _sortAnimationController.dispose();
    _selectionAnimationController.dispose();
    _pageTransitionController.dispose();

    _resizeController.removeListener(_ensureScrollVisibility);

    if (widget.resizeController == null) {
      _resizeController.dispose();
    }

    _loadingManager?.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(InnovareDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.columns != widget.columns || oldWidget.rows != widget.rows) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureScrollVisibility();
      });
    }
  }

  Widget _buildQuickActionButton(QuickActionConfig action, DataTableColorScheme colors) {
    return ElevatedButton.icon(
      onPressed: action.onPressed,
      label: Text(
        action.label,
        style: action.textStyle ?? TextStyle(
          color: colors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: Icon(
        action.icon,
        color: colors.primary,
        size: action.iconSize ?? 20,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: action.backgroundColor ?? colors.primaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      )
    );
  }

  Widget _buildQuickActionsContent(List<QuickActionConfig> quickActions, DataTableColorScheme colors) {
    if (ResponsiveTableManager.isDesktop(context)) {
      return Row(
        children: widget.quickActions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _buildQuickActionButton(
              action,
              colors,
            ),
          );
        }).toList(),
      );
    }

    return _buildPopupMenuQuickActions(quickActions, colors);
  }

  Widget _buildPopupMenuQuickActions(List<QuickActionConfig> quickActions, DataTableColorScheme colors) {
    return PopupMenuButton<QuickActionConfig>(
      icon: Icon(Icons.more_vert_rounded, color: colors.onSurfaceVariant),
      itemBuilder: (context) {
        return quickActions.map((action) {
          return PopupMenuItem<QuickActionConfig>(
            value: action,
            child: Row(
              children: [
                Icon(action.icon, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  action.label,
                  style: action.textStyle ?? TextStyle(
                    color: colors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      onSelected: (action) {
        action.onPressed();
      },
    );
  }
}