import 'package:flutter/material.dart';
import 'package:innovare_data_table/src/data_table_filters.dart';
import 'package:innovare_data_table/src/data_table_responsive.dart';
import 'package:innovare_data_table/src/data_table_theme.dart';
import 'package:innovare_data_table/src/filters/filter_models.dart';
import 'package:innovare_data_table/src/filters/unified_filters_controller.dart';

// =============================================================================
// DIALOG MODERNO PARA FILTROS AVANÇADOS
// =============================================================================

class ModernFiltersDialog<T> extends StatefulWidget {
  final UnifiedFiltersController<T> controller;
  final DataTableColorScheme colors;

  const ModernFiltersDialog({
    super.key,
    required this.controller,
    required this.colors,
  });

  @override
  State<ModernFiltersDialog<T>> createState() => _ModernFiltersDialogState<T>();
}

class _ModernFiltersDialogState<T> extends State<ModernFiltersDialog<T>>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Estado de trabalho
  List<ActiveFilter> _workingFilters = [];
  List<FilterPreset<T>> _workingPresets = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTabs();
    _initializeWorkingState();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  void _initializeTabs() {
    final tabs = <Tab>[];

    // Sempre incluir filtros
    tabs.add(const Tab(
      icon: Icon(Icons.tune_rounded, size: 20),
      text: 'Filtros',
    ));

    // Incluir presets se habilitado
    if (widget.controller.config.enableFilterPresets) {
      tabs.add(const Tab(
        icon: Icon(Icons.bookmark_rounded, size: 20),
        text: 'Presets',
      ));
    }

    _tabController = TabController(length: tabs.length, vsync: this);
  }

  void _initializeWorkingState() {
    _workingFilters = List.from(widget.controller.getActiveAdvancedFilters());
    _workingPresets = List.from(widget.controller.presets);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveTableManager.isMobile(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: isMobile ? double.infinity : 600,
          height: isMobile ? MediaQuery.of(context).size.height * 0.9 : 700,
          child: Column(
            children: [
              _buildHeader(),
              if (_tabController.length > 1) _buildTabBar(),
              Expanded(child: _buildContent()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: widget.colors.outline.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.colors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: widget.colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtros Avançados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: widget.colors.onSurface,
                  ),
                ),
                Text(
                  'Configure filtros personalizados para seus dados',
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: widget.colors.onSurfaceVariant),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: widget.colors.surface,
        border: Border(bottom: BorderSide(color: widget.colors.outline.withOpacity(0.2))),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: widget.colors.primary,
        unselectedLabelColor: widget.colors.onSurfaceVariant,
        indicatorColor: widget.colors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        tabs: [
          const Tab(
            icon: Icon(Icons.tune_rounded, size: 20),
            text: 'Filtros',
          ),
          if (widget.controller.config.enableFilterPresets)
            const Tab(
              icon: Icon(Icons.bookmark_rounded, size: 20),
              text: 'Presets',
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_tabController.length == 1) {
      return _buildFiltersTab();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildFiltersTab(),
        if (widget.controller.config.enableFilterPresets)
          _buildPresetsTab(),
      ],
    );
  }

  Widget _buildFiltersTab() {
    return Column(
      children: [
        // Add filter button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: ElevatedButton.icon(
            onPressed: _showAddFilterDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Adicionar Filtro'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),

        // Filters list
        Expanded(
          child: _workingFilters.isEmpty
              ? _buildEmptyFiltersState()
              : _buildFiltersList(),
        ),
      ],
    );
  }

  Widget _buildEmptyFiltersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.colors.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.filter_alt_outlined,
              size: 48,
              color: widget.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum filtro configurado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: widget.colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione filtros personalizados para refinar seus resultados',
            style: TextStyle(
              fontSize: 14,
              color: widget.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _showAddFilterDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Adicionar Primeiro Filtro'),
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.colors.primary,
              side: BorderSide(color: widget.colors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _workingFilters.length,
      itemBuilder: (context, index) {
        final filter = _workingFilters[index];
        return _buildFilterCard(filter, index);
      },
    );
  }

  Widget _buildFilterCard(ActiveFilter filter, int index) {
    final config = widget.controller.config.advancedFiltersConfigs.firstWhere(
          (c) => c.field == filter.field,
      orElse: () => AdvancedFilterConfig<T>(
        field: filter.field,
        label: filter.field,
        type: SimpleFilterType.text,
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filter.isActive
              ? widget.colors.primary.withOpacity(0.3)
              : widget.colors.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: filter.isActive
                        ? widget.colors.primary
                        : widget.colors.onSurfaceVariant.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),

                // Filter info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        filter.getDisplayText(config.label),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: filter.isActive
                              ? widget.colors.onSurface
                              : widget.colors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Campo: ${config.label}',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toggle switch
                    Switch(
                      value: filter.isActive,
                      onChanged: (value) {
                        setState(() {
                          _workingFilters[index] = filter.copyWith(isActive: value);
                        });
                      },
                      activeColor: widget.colors.primary,
                    ),

                    // Edit button
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: widget.colors.onSurfaceVariant,
                      ),
                      onPressed: () => _editFilter(filter, index),
                      tooltip: 'Editar filtro',
                    ),

                    // Delete button
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: widget.colors.error,
                      ),
                      onPressed: () => _deleteFilter(index),
                      tooltip: 'Remover filtro',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsTab() {
    return Column(
      children: [
        // Save current as preset
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Salvar Configuração Atual',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _showSavePresetDialog,
                icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                label: const Text('Criar Preset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),

        const Divider(),

        // Presets list
        Expanded(
          child: _workingPresets.isEmpty
              ? _buildEmptyPresetsState()
              : _buildPresetsList(),
        ),
      ],
    );
  }

  Widget _buildEmptyPresetsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 48,
            color: widget.colors.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum preset salvo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: widget.colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Salve suas configurações favoritas como presets',
            style: TextStyle(
              fontSize: 14,
              color: widget.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _workingPresets.length,
      itemBuilder: (context, index) {
        final preset = _workingPresets[index];
        return _buildPresetCard(preset, index);
      },
    );
  }

  Widget _buildPresetCard(FilterPreset<T> preset, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.bookmark_rounded,
          color: widget.colors.primary,
        ),
        title: Text(
          preset.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: widget.colors.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (preset.description?.isNotEmpty == true)
              Text(preset.description!),
            Text(
              '${preset.filters.length} filtros • ${preset.createdAt.day}/${preset.createdAt.month}/${preset.createdAt.year}',
              style: TextStyle(
                fontSize: 12,
                color: widget.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.download_rounded, color: widget.colors.primary),
              onPressed: () => _loadPreset(preset.id),
              tooltip: 'Carregar preset',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: widget.colors.error),
              onPressed: () => _deletePreset(index),
              tooltip: 'Deletar preset',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.colors.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: widget.colors.outline.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          // Clear all button
          OutlinedButton.icon(
            onPressed: _workingFilters.isNotEmpty ? _clearAllFilters : null,
            icon: const Icon(Icons.clear_all_rounded, size: 18),
            label: const Text('Limpar Todos'),
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.colors.error,
              side: BorderSide(color: widget.colors.error.withOpacity(0.5)),
            ),
          ),

          const Spacer(),

          // Cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),

          const SizedBox(width: 12),

          // Apply button
          ElevatedButton.icon(
            onPressed: _applyFilters,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text('Aplicar ${_workingFilters.where((f) => f.isActive).length} Filtros'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.colors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // MÉTODOS DE AÇÃO
  // =============================================================================

  void _showAddFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterBuilderDialog<T>(
        controller: widget.controller,
        colors: widget.colors,
        onFilterCreated: (filter) {
          setState(() {
            _workingFilters.add(filter);
          });
        },
      ),
    );
  }

  void _editFilter(ActiveFilter filter, int index) {
    showDialog(
      context: context,
      builder: (context) => _FilterBuilderDialog<T>(
        controller: widget.controller,
        colors: widget.colors,
        existingFilter: filter,
        onFilterCreated: (updatedFilter) {
          setState(() {
            _workingFilters[index] = updatedFilter;
          });
        },
      ),
    );
  }

  void _deleteFilter(int index) {
    setState(() {
      _workingFilters.removeAt(index);
    });
  }

  void _clearAllFilters() {
    setState(() {
      _workingFilters.clear();
    });
  }

  void _showSavePresetDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salvar Preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do preset',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                widget.controller.savePreset(
                  nameController.text.trim(),
                  description: descController.text.trim().isNotEmpty
                      ? descController.text.trim()
                      : null,
                );
                setState(() {
                  _workingPresets = List.from(widget.controller.presets);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _loadPreset(String presetId) {
    widget.controller.loadPreset(presetId);
    setState(() {
      _workingFilters = List.from(widget.controller.getActiveAdvancedFilters());
    });
  }

  void _deletePreset(int index) {
    final preset = _workingPresets[index];
    widget.controller.deletePreset(preset.id);
    setState(() {
      _workingPresets.removeAt(index);
    });
  }

  void _applyFilters() {
    widget.controller.setAdvancedFilters(_workingFilters);
    Navigator.pop(context);
  }
}

// =============================================================================
// DIALOG PARA CRIAR/EDITAR FILTROS
// =============================================================================

class _FilterBuilderDialog<T> extends StatefulWidget {
  final UnifiedFiltersController<T> controller;
  final DataTableColorScheme colors;
  final Function(ActiveFilter) onFilterCreated;
  final ActiveFilter? existingFilter;

  const _FilterBuilderDialog({
    required this.controller,
    required this.colors,
    required this.onFilterCreated,
    this.existingFilter,
  });

  @override
  State<_FilterBuilderDialog<T>> createState() => _FilterBuilderDialogState<T>();
}

class _FilterBuilderDialogState<T> extends State<_FilterBuilderDialog<T>> {
  AdvancedFilterConfig<T>? _selectedConfig;
  FilterOperator? _selectedOperator;
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _secondValueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeExistingFilter();
    _setupListeners();
  }

  void _initializeExistingFilter() {
    if (widget.existingFilter != null) {
      _selectedConfig = widget.controller.config.advancedFiltersConfigs.firstWhere(
            (c) => c.field == widget.existingFilter!.field,
        orElse: () => AdvancedFilterConfig<T>(
          field: widget.existingFilter!.field,
          label: widget.existingFilter!.field,
          type: SimpleFilterType.text,
        ),
      );
      _selectedOperator = widget.existingFilter!.operator;
      _valueController.text = widget.existingFilter!.value?.toString() ?? '';
      _secondValueController.text = widget.existingFilter!.secondValue?.toString() ?? '';
    }
  }

  void _setupListeners() {
    _valueController.addListener(() => setState(() {}));
    _secondValueController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _valueController.dispose();
    _secondValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.add_circle_outline, color: widget.colors.primary),
                const SizedBox(width: 12),
                Text(
                  widget.existingFilter != null ? 'Editar Filtro' : 'Criar Filtro',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: widget.colors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Campo
            DropdownButtonFormField<AdvancedFilterConfig<T>>(
              value: _selectedConfig,
              decoration: InputDecoration(
                labelText: 'Campo',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.table_chart, color: widget.colors.primary),
              ),
              items: widget.controller.config.advancedFiltersConfigs.map((config) {
                return DropdownMenuItem(
                  value: config,
                  child: Text(config.label),
                );
              }).toList(),
              onChanged: (config) {
                setState(() {
                  _selectedConfig = config;
                  _selectedOperator = null;
                  _valueController.clear();
                  _secondValueController.clear();
                });
              },
            ),

            const SizedBox(height: 16),

            // Operador
            if (_selectedConfig != null) ...[
              DropdownButtonFormField<FilterOperator>(
                value: _selectedOperator,
                decoration: InputDecoration(
                  labelText: 'Operador',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.compare_arrows, color: widget.colors.primary),
                ),
                items: _selectedConfig!.allowedOperators.map((op) {
                  return DropdownMenuItem(
                    value: op,
                    child: Text(_getOperatorLabel(op)),
                  );
                }).toList(),
                onChanged: (op) {
                  setState(() {
                    _selectedOperator = op;
                    _valueController.clear();
                    _secondValueController.clear();
                  });
                },
              ),

              const SizedBox(height: 16),

              // Valores
              if (_selectedOperator != null && _needsValue(_selectedOperator!))
                _buildValueFields(),
            ],

            const SizedBox(height: 24),

            // Validation indicator
            if (_selectedConfig != null && _selectedOperator != null)
              _buildValidationIndicator(),

            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _canCreate() ? _createFilter : null,
                  icon: Icon(
                    widget.existingFilter != null ? Icons.check : Icons.add,
                    size: 18,
                  ),
                  label: Text(widget.existingFilter != null ? 'Atualizar' : 'Criar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canCreate()
                        ? widget.colors.primary
                        : widget.colors.onSurfaceVariant.withOpacity(0.3),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueFields() {
    if (_selectedOperator == FilterOperator.between) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: 'Valor inicial',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.start, color: widget.colors.primary),
              ),
              keyboardType: _getKeyboardType(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _secondValueController,
              decoration: InputDecoration(
                labelText: 'Valor final',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.arrow_forward_rounded,
                  color: widget.colors.primary
                ),
              ),
              keyboardType: _getKeyboardType(),
            ),
          ),
        ],
      );
    }

    if (_selectedConfig!.type == SimpleFilterType.select) {
      return DropdownButtonFormField<dynamic>(
        value: _valueController.text.isNotEmpty ? _valueController.text : null,
        decoration: InputDecoration(
          labelText: 'Valor',
          border: const OutlineInputBorder(),
          prefixIcon: Icon(Icons.list, color: widget.colors.primary),
        ),
        items: _selectedConfig!.options?.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option.toString()),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _valueController.text = value?.toString() ?? '';
          });
        },
      );
    }

    return TextField(
      controller: _valueController,
      decoration: InputDecoration(
        labelText: 'Valor',
        border: const OutlineInputBorder(),
        prefixIcon: Icon(Icons.edit, color: widget.colors.primary),
      ),
      keyboardType: _getKeyboardType(),
    );
  }

  Widget _buildValidationIndicator() {
    final isValid = _canCreate();
    final message = _getValidationMessage();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.error,
            size: 16,
            color: isValid ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: isValid ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextInputType _getKeyboardType() {
    if (_selectedConfig?.type == SimpleFilterType.number) {
      return TextInputType.number;
    }
    return TextInputType.text;
  }

  bool _needsValue(FilterOperator operator) {
    return operator != FilterOperator.isEmpty && operator != FilterOperator.isNotEmpty;
  }

  bool _canCreate() {
    if (_selectedConfig == null || _selectedOperator == null) return false;

    if (!_needsValue(_selectedOperator!)) return true;

    if (_selectedOperator == FilterOperator.between) {
      return _valueController.text.trim().isNotEmpty &&
          _secondValueController.text.trim().isNotEmpty;
    }

    return _valueController.text.trim().isNotEmpty;
  }

  String _getValidationMessage() {
    if (_selectedConfig == null) return 'Selecione um campo';
    if (_selectedOperator == null) return 'Selecione um operador';

    if (!_needsValue(_selectedOperator!)) {
      return 'Filtro pronto para ser criado';
    }

    if (_selectedOperator == FilterOperator.between) {
      if (_valueController.text.trim().isEmpty) return 'Digite o valor inicial';
      if (_secondValueController.text.trim().isEmpty) return 'Digite o valor final';
    } else {
      if (_valueController.text.trim().isEmpty) return 'Digite um valor';
    }

    return 'Filtro pronto para ser criado';
  }

  void _createFilter() {
    final filter = ActiveFilter(
      field: _selectedConfig!.field,
      operator: _selectedOperator!,
      value: _valueController.text.trim().isNotEmpty ? _valueController.text.trim() : null,
      secondValue: _secondValueController.text.trim().isNotEmpty ? _secondValueController.text.trim() : null,
    );

    widget.onFilterCreated(filter);
    Navigator.pop(context);
  }

  String _getOperatorLabel(FilterOperator operator) {
    switch (operator) {
      case FilterOperator.equals: return 'Igual a';
      case FilterOperator.notEquals: return 'Diferente de';
      case FilterOperator.contains: return 'Contém';
      case FilterOperator.notContains: return 'Não contém';
      case FilterOperator.startsWith: return 'Começa com';
      case FilterOperator.endsWith: return 'Termina com';
      case FilterOperator.greaterThan: return 'Maior que';
      case FilterOperator.lessThan: return 'Menor que';
      case FilterOperator.between: return 'Entre';
      case FilterOperator.isEmpty: return 'Está vazio';
      case FilterOperator.isNotEmpty: return 'Não está vazio';
    }
  }
}