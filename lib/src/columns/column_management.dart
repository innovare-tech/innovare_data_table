import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:innovare_data_table/src/data_column_config.dart';
import 'package:innovare_data_table/src/data_table_theme.dart';

class ColumnState<T> {
  final DataColumnConfig<T> config;
  final bool isVisible;
  final int originalIndex;
  final int currentIndex;
  final double? customWidth;
  final bool isSticky;

  const ColumnState({
    required this.config,
    required this.isVisible,
    required this.originalIndex,
    required this.currentIndex,
    this.customWidth,
    this.isSticky = false,
  });

  ColumnState<T> copyWith({
    DataColumnConfig<T>? config,
    bool? isVisible,
    int? originalIndex,
    int? currentIndex,
    double? customWidth,
    bool? isSticky,
  }) {
    return ColumnState<T>(
      config: config ?? this.config,
      isVisible: isVisible ?? this.isVisible,
      originalIndex: originalIndex ?? this.originalIndex,
      currentIndex: currentIndex ?? this.currentIndex,
      customWidth: customWidth ?? this.customWidth,
      isSticky: isSticky ?? this.isSticky,
    );
  }
}

class ColumnManagerController<T> extends ChangeNotifier {
  List<ColumnState<T>> _columnStates = [];
  final Map<String, ColumnPreset<T>> _presets = {};

  List<ColumnState<T>> get columnStates => List.unmodifiable(_columnStates);
  List<DataColumnConfig<T>> get visibleColumns => _columnStates
      .where((state) => state.isVisible)
      .map((state) => state.config)
      .toList();

  Map<String, ColumnPreset<T>> get presets => Map.unmodifiable(_presets);

  void initialize(List<DataColumnConfig<T>> columns) {
    _columnStates = columns.asMap().entries.map((entry) {
      final index = entry.key;
      final column = entry.value;

      return ColumnState<T>(
        config: column,
        isVisible: true,
        originalIndex: index,
        currentIndex: index,
        customWidth: column.effectiveWidth,
        isSticky: column.isStickyEnabled,
      );
    }).toList();

    notifyListeners();
  }

  void toggleColumnVisibility(String field) {
    final index = _columnStates.indexWhere((state) => state.config.field == field);
    if (index != -1) {
      _columnStates[index] = _columnStates[index].copyWith(
        isVisible: !_columnStates[index].isVisible,
      );
      notifyListeners();
    }
  }

  void setColumnVisibility(String field, bool visible) {
    final index = _columnStates.indexWhere((state) => state.config.field == field);
    if (index != -1) {
      _columnStates[index] = _columnStates[index].copyWith(isVisible: visible);
      notifyListeners();
    }
  }

  void reorderColumns(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = _columnStates.removeAt(oldIndex);
    _columnStates.insert(newIndex, item.copyWith(currentIndex: newIndex));

    // Atualizar índices
    for (int i = 0; i < _columnStates.length; i++) {
      _columnStates[i] = _columnStates[i].copyWith(currentIndex: i);
    }

    notifyListeners();
  }

  void setColumnWidth(String field, double width) {
    final index = _columnStates.indexWhere((state) => state.config.field == field);
    if (index != -1) {
      _columnStates[index] = _columnStates[index].copyWith(customWidth: width);
      notifyListeners();
    }
  }

  void resetToDefaults() {
    // Ordenar por índice original
    _columnStates.sort((a, b) => a.originalIndex.compareTo(b.originalIndex));

    // Restaurar visibilidade e larguras
    for (int i = 0; i < _columnStates.length; i++) {
      _columnStates[i] = _columnStates[i].copyWith(
        isVisible: true,
        currentIndex: i,
        customWidth: _columnStates[i].config.effectiveWidth,
      );
    }

    notifyListeners();
  }

  void savePreset(String name, String description) {
    _presets[name] = ColumnPreset<T>(
      name: name,
      description: description,
      columnStates: List.from(_columnStates),
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  void loadPreset(String name) {
    final preset = _presets[name];
    if (preset != null) {
      _columnStates = List.from(preset.columnStates);
      notifyListeners();
    }
  }

  void deletePreset(String name) {
    _presets.remove(name);
    notifyListeners();
  }

  // Persistência
  Map<String, dynamic> toJson() {
    return {
      'columnStates': _columnStates.map((state) => {
        'field': state.config.field,
        'isVisible': state.isVisible,
        'currentIndex': state.currentIndex,
        'customWidth': state.customWidth,
      }).toList(),
      'presets': _presets.map((key, preset) => MapEntry(key, preset.toJson())),
    };
  }

  void fromJson(Map<String, dynamic> json, List<DataColumnConfig<T>> originalColumns) {
    final states = json['columnStates'] as List?;
    if (states != null) {
      final newStates = <ColumnState<T>>[];

      for (final stateData in states) {
        final field = stateData['field'] as String;
        final column = originalColumns.firstWhere((col) => col.field == field);

        newStates.add(ColumnState<T>(
          config: column,
          isVisible: stateData['isVisible'] ?? true,
          originalIndex: originalColumns.indexOf(column),
          currentIndex: stateData['currentIndex'] ?? 0,
          customWidth: stateData['customWidth']?.toDouble(),
        ));
      }

      _columnStates = newStates;
    }

    final presetsData = json['presets'] as Map<String, dynamic>?;
    if (presetsData != null) {
      _presets.clear();
      presetsData.forEach((key, value) {
        _presets[key] = ColumnPreset<T>.fromJson(value, originalColumns);
      });
    }

    notifyListeners();
  }
}

class ColumnPreset<T> {
  final String name;
  final String description;
  final List<ColumnState<T>> columnStates;
  final DateTime createdAt;

  const ColumnPreset({
    required this.name,
    required this.description,
    required this.columnStates,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'columnStates': columnStates.map((state) => {
        'field': state.config.field,
        'isVisible': state.isVisible,
        'currentIndex': state.currentIndex,
        'customWidth': state.customWidth,
      }).toList(),
    };
  }

  factory ColumnPreset.fromJson(Map<String, dynamic> json, List<DataColumnConfig<T>> originalColumns) {
    final states = <ColumnState<T>>[];
    final statesData = json['columnStates'] as List;

    for (final stateData in statesData) {
      final field = stateData['field'] as String;
      final column = originalColumns.firstWhere((col) => col.field == field);

      states.add(ColumnState<T>(
        config: column,
        isVisible: stateData['isVisible'] ?? true,
        originalIndex: originalColumns.indexOf(column),
        currentIndex: stateData['currentIndex'] ?? 0,
        customWidth: stateData['customWidth']?.toDouble(),
      ));
    }

    return ColumnPreset<T>(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      columnStates: states,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ColumnManagerDialog<T> extends StatefulWidget {
  final ColumnManagerController<T> controller;
  final List<T> sampleData;
  final DataTableColorScheme colors;
  final VoidCallback? onSave;

  const ColumnManagerDialog({
    super.key,
    required this.controller,
    required this.sampleData,
    required this.colors,
    this.onSave,
  });

  @override
  State<ColumnManagerDialog<T>> createState() => _ColumnManagerDialogState<T>();
}

class _ColumnManagerDialogState<T> extends State<ColumnManagerDialog<T>>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late List<ColumnState<T>> _workingStates;
  final TextEditingController _presetNameController = TextEditingController();
  final TextEditingController _presetDescController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _workingStates = List.from(widget.controller.columnStates);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _presetNameController.dispose();
    _presetDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 600,
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
            _buildFooter(),
          ],
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
        border: Border(bottom: BorderSide(color: widget.colors.outline)),
      ),
      child: Row(
        children: [
          Icon(Icons.view_column_rounded, color: widget.colors.primary, size: 24),
          const SizedBox(width: 12),
          Text(
            'Gerenciar Colunas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: widget.colors.onSurface,
            ),
          ),
          const Spacer(),
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
        border: Border(bottom: BorderSide(color: widget.colors.outline)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: widget.colors.primary,
        unselectedLabelColor: widget.colors.onSurfaceVariant,
        indicatorColor: widget.colors.primary,
        tabs: const [
          Tab(text: 'Visibilidade', icon: Icon(Icons.visibility)),
          Tab(text: 'Ordem', icon: Icon(Icons.reorder)),
          Tab(text: 'Presets', icon: Icon(Icons.bookmark)),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildVisibilityTab(),
        _buildOrderTab(),
        _buildPresetsTab(),
      ],
    );
  }

  Widget _buildVisibilityTab() {
    return Column(
      children: [
        // Quick actions
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    for (int i = 0; i < _workingStates.length; i++) {
                      _workingStates[i] = _workingStates[i].copyWith(isVisible: true);
                    }
                  });
                },
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('Mostrar Todas'),
                style: ElevatedButton.styleFrom(backgroundColor: widget.colors.primary),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    for (int i = 0; i < _workingStates.length; i++) {
                      _workingStates[i] = _workingStates[i].copyWith(isVisible: false);
                    }
                  });
                },
                icon: const Icon(Icons.visibility_off, size: 16),
                label: const Text('Ocultar Todas'),
              ),
            ],
          ),
        ),

        // Column list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _workingStates.length,
            itemBuilder: (context, index) {
              final state = _workingStates[index];
              return _buildColumnVisibilityItem(state, index);
            },
          ),
        ),

        // Preview
        if (widget.sampleData.isNotEmpty)
          _buildPreviewSection(),
      ],
    );
  }

  Widget _buildColumnVisibilityItem(ColumnState<T> state, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        value: state.isVisible,
        onChanged: (value) {
          setState(() {
            _workingStates[index] = state.copyWith(isVisible: value);
          });
        },
        title: Text(
          state.config.label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: widget.colors.onSurface,
          ),
        ),
        subtitle: Text(
          'Campo: ${state.config.field}',
          style: TextStyle(
            fontSize: 12,
            color: widget.colors.onSurfaceVariant,
          ),
        ),
        secondary: Icon(
          _getColumnIcon(state.config),
          color: widget.colors.onSurfaceVariant,
        ),
        activeColor: widget.colors.primary,
      ),
    );
  }

  Widget _buildOrderTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Arraste as colunas para reordená-las',
            style: TextStyle(
              color: widget.colors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _workingStates.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = _workingStates.removeAt(oldIndex);
                _workingStates.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final state = _workingStates[index];
              return _buildReorderableItem(state, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReorderableItem(ColumnState<T> state, int index) {
    return Card(
      key: ValueKey(state.config.field),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.drag_handle,
          color: widget.colors.onSurfaceVariant,
        ),
        title: Text(
          state.config.label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: state.isVisible
                ? widget.colors.onSurface
                : widget.colors.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          'Posição: ${index + 1}',
          style: TextStyle(
            fontSize: 12,
            color: widget.colors.onSurfaceVariant,
          ),
        ),
        trailing: state.isVisible
            ? Icon(Icons.visibility, color: widget.colors.primary, size: 20)
            : Icon(Icons.visibility_off, color: widget.colors.onSurfaceVariant, size: 20),
      ),
    );
  }

  Widget _buildPresetsTab() {
    return Column(
      children: [
        // Save new preset
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Salvar configuração atual',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _presetNameController,
                decoration: InputDecoration(
                  labelText: 'Nome do preset',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _presetDescController,
                decoration: InputDecoration(
                  labelText: 'Descrição (opcional)',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _savePreset,
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Salvar Preset'),
                style: ElevatedButton.styleFrom(backgroundColor: widget.colors.primary),
              ),
            ],
          ),
        ),

        const Divider(),

        // Existing presets
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.controller.presets.length,
            itemBuilder: (context, index) {
              final entry = widget.controller.presets.entries.elementAt(index);
              return _buildPresetItem(entry.key, entry.value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPresetItem(String name, ColumnPreset<T> preset) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.bookmark, color: widget.colors.primary),
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
            if (preset.description.isNotEmpty)
              Text(preset.description),
            Text(
              'Criado em ${preset.createdAt.day}/${preset.createdAt.month}/${preset.createdAt.year}',
              style: TextStyle(
                fontSize: 11,
                color: widget.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.download, color: widget.colors.primary),
              onPressed: () => _loadPreset(name),
              tooltip: 'Carregar preset',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: widget.colors.error),
              onPressed: () => _deletePreset(name),
              tooltip: 'Deletar preset',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: widget.colors.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.colors.surfaceVariant,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(Icons.preview, size: 16, color: widget.colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Preview da Tabela',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: widget.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: _workingStates
                    .where((state) => state.isVisible)
                    .map((state) => DataColumn(
                  label: Text(
                    state.config.label,
                    style: const TextStyle(fontSize: 12),
                  ),
                ))
                    .toList(),
                rows: widget.sampleData.take(3).map((item) {
                  return DataRow(
                    cells: _workingStates
                        .where((state) => state.isVisible)
                        .map((state) => DataCell(
                      Text(
                        state.config.valueGetter(item).toString(),
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                        .toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.colors.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: widget.colors.outline)),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _workingStates = List.from(widget.controller.columnStates);
              });
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Restaurar'),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _applyChanges,
            style: ElevatedButton.styleFrom(backgroundColor: widget.colors.primary),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  IconData _getColumnIcon(DataColumnConfig<T> config) {
    if (config.sortable && config.filterable) return Icons.sort;
    if (config.sortable) return Icons.sort;
    if (config.filterable) return Icons.filter_list;
    return Icons.table_chart;
  }

  void _savePreset() {
    if (_presetNameController.text.trim().isEmpty) return;

    widget.controller.savePreset(
      _presetNameController.text.trim(),
      _presetDescController.text.trim(),
    );

    _presetNameController.clear();
    _presetDescController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preset salvo com sucesso!')),
    );
  }

  void _loadPreset(String name) {
    widget.controller.loadPreset(name);
    setState(() {
      _workingStates = List.from(widget.controller.columnStates);
    });
  }

  void _deletePreset(String name) {
    widget.controller.deletePreset(name);
    setState(() {});
  }

  void _applyChanges() {
    // Aplicar mudanças no controller
    for (int i = 0; i < _workingStates.length; i++) {
      final state = _workingStates[i];
      widget.controller.setColumnVisibility(state.config.field, state.isVisible);
    }

    widget.onSave?.call();
    Navigator.pop(context);
  }
}
