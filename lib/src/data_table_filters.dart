import 'package:flutter/material.dart';
import 'package:innovare_data_table/src/data_table_theme.dart';

enum SimpleFilterType { text, number, date, select }

enum FilterOperator {
  equals,
  notEquals,
  contains,
  notContains,
  startsWith,
  endsWith,
  greaterThan,
  lessThan,
  between,
  isEmpty,
  isNotEmpty,
}

class AdvancedFilterConfig<T> {
  final String field;
  final String label;
  final SimpleFilterType type;
  final List<FilterOperator> allowedOperators;
  final List<dynamic>? options;
  final dynamic Function(T item)? valueGetter;

  const AdvancedFilterConfig({
    required this.field,
    required this.label,
    required this.type,
    this.allowedOperators = const [FilterOperator.contains],
    this.options,
    this.valueGetter,
  });

  // Operadores padrão por tipo
  static List<FilterOperator> getDefaultOperators(SimpleFilterType type) {
    switch (type) {
      case SimpleFilterType.text:
        return [
          FilterOperator.contains,
          FilterOperator.notContains,
          FilterOperator.equals,
          FilterOperator.notEquals,
          FilterOperator.startsWith,
          FilterOperator.endsWith,
          FilterOperator.isEmpty,
          FilterOperator.isNotEmpty,
        ];
      case SimpleFilterType.number:
        return [
          FilterOperator.equals,
          FilterOperator.notEquals,
          FilterOperator.greaterThan,
          FilterOperator.lessThan,
          FilterOperator.between,
        ];
      case SimpleFilterType.date:
        return [
          FilterOperator.equals,
          FilterOperator.greaterThan,
          FilterOperator.lessThan,
          FilterOperator.between,
        ];
      case SimpleFilterType.select:
        return [
          FilterOperator.equals,
          FilterOperator.notEquals,
        ];
    }
  }
}

class ActiveFilter {
  final String field;
  final FilterOperator operator;
  final dynamic value;
  final dynamic secondValue; // Para between
  final bool isActive;

  const ActiveFilter({
    required this.field,
    required this.operator,
    this.value,
    this.secondValue,
    this.isActive = true,
  });

  ActiveFilter copyWith({
    String? field,
    FilterOperator? operator,
    dynamic value,
    dynamic secondValue,
    bool? isActive,
  }) {
    return ActiveFilter(
      field: field ?? this.field,
      operator: operator ?? this.operator,
      value: value ?? this.value,
      secondValue: secondValue ?? this.secondValue,
      isActive: isActive ?? this.isActive,
    );
  }

  String getDisplayText(String fieldLabel) {
    final operatorText = _getOperatorDisplayText(operator);
    if (operator == FilterOperator.between) {
      return '$fieldLabel $operatorText $value e $secondValue';
    }
    if (operator == FilterOperator.isEmpty || operator == FilterOperator.isNotEmpty) {
      return '$fieldLabel $operatorText';
    }
    return '$fieldLabel $operatorText $value';
  }

  String _getOperatorDisplayText(FilterOperator op) {
    switch (op) {
      case FilterOperator.equals:
        return 'igual a';
      case FilterOperator.notEquals:
        return 'diferente de';
      case FilterOperator.contains:
        return 'contém';
      case FilterOperator.notContains:
        return 'não contém';
      case FilterOperator.startsWith:
        return 'começa com';
      case FilterOperator.endsWith:
        return 'termina com';
      case FilterOperator.greaterThan:
        return 'maior que';
      case FilterOperator.lessThan:
        return 'menor que';
      case FilterOperator.between:
        return 'entre';
      case FilterOperator.isEmpty:
        return 'está vazio';
      case FilterOperator.isNotEmpty:
        return 'não está vazio';
    }
  }
}

class AdvancedFiltersDialog<T> extends StatefulWidget {
  final List<AdvancedFilterConfig<T>> filterConfigs;
  final List<ActiveFilter> currentFilters;
  final Function(List<ActiveFilter>) onFiltersChanged;
  final DataTableColorScheme colors;

  const AdvancedFiltersDialog({
    super.key,
    required this.filterConfigs,
    required this.currentFilters,
    required this.onFiltersChanged,
    required this.colors,
  });

  @override
  State<AdvancedFiltersDialog<T>> createState() => _AdvancedFiltersDialogState<T>();
}

class _AdvancedFiltersDialogState<T> extends State<AdvancedFiltersDialog<T>> {
  late List<ActiveFilter> _workingFilters;

  @override
  void initState() {
    super.initState();
    _workingFilters = List.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildContent(),
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
          Icon(Icons.tune_rounded, color: widget.colors.primary, size: 24),
          const SizedBox(width: 12),
          Text(
            'Filtros Avançados',
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

  Widget _buildContent() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botão para adicionar filtro
            _buildAddFilterButton(),
            const SizedBox(height: 16),

            // Lista de filtros ativos
            if (_workingFilters.isNotEmpty) ...[
              Text(
                'Filtros Ativos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ..._workingFilters.asMap().entries.map((entry) {
                final index = entry.key;
                final filter = entry.value;
                return _buildFilterItem(filter, index);
              }),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.filter_alt_outlined,
                      size: 48,
                      color: widget.colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum filtro adicionado',
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use o botão acima para adicionar filtros',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddFilterButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showAddFilterDialog,
        icon: Icon(Icons.add_rounded, color: widget.colors.primary),
        label: Text(
          'Adicionar Filtro',
          style: TextStyle(color: widget.colors.primary),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: widget.colors.primary),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterItem(ActiveFilter filter, int index) {
    final config = widget.filterConfigs.firstWhere((c) => c.field == filter.field);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.colors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.colors.outline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do filtro
          Row(
            children: [
              Expanded(
                child: Text(
                  filter.getDisplayText(config.label),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: widget.colors.onSurface,
                  ),
                ),
              ),
              Switch(
                value: filter.isActive,
                onChanged: (value) {
                  setState(() {
                    _workingFilters[index] = filter.copyWith(isActive: value);
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: widget.colors.onSurfaceVariant),
                onPressed: () => _editFilter(filter, index),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: widget.colors.error),
                onPressed: () {
                  setState(() {
                    _workingFilters.removeAt(index);
                  });
                },
              ),
            ],
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
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _workingFilters.clear();
                });
              },
              child: const Text('Limpar Todos'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                widget.onFiltersChanged(_workingFilters);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.colors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Aplicar'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterBuilderDialog<T>(
        filterConfigs: widget.filterConfigs,
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
        filterConfigs: widget.filterConfigs,
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
}

class _FilterBuilderDialog<T> extends StatefulWidget {
  final List<AdvancedFilterConfig<T>> filterConfigs;
  final DataTableColorScheme colors;
  final Function(ActiveFilter) onFilterCreated;
  final ActiveFilter? existingFilter;

  const _FilterBuilderDialog({
    required this.filterConfigs,
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

    // Configurar valores existentes se estiver editando
    if (widget.existingFilter != null) {
      _selectedConfig = widget.filterConfigs.firstWhere(
            (c) => c.field == widget.existingFilter!.field,
      );
      _selectedOperator = widget.existingFilter!.operator;
      _valueController.text = widget.existingFilter!.value?.toString() ?? '';
      _secondValueController.text = widget.existingFilter!.secondValue?.toString() ?? '';
    }

    // CORREÇÃO: Adicionar listeners para atualizar o estado quando o usuário digitar
    _valueController.addListener(() {
      setState(() {}); // Força rebuild quando o texto muda
    });

    _secondValueController.addListener(() {
      setState(() {}); // Força rebuild quando o texto muda
    });
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
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existingFilter != null ? 'Editar Filtro' : 'Criar Filtro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: widget.colors.onSurface,
              ),
            ),
            const SizedBox(height: 20),

            // Seleção do campo
            DropdownButtonFormField<AdvancedFilterConfig<T>>(
              value: _selectedConfig,
              decoration: const InputDecoration(
                labelText: 'Campo',
                border: OutlineInputBorder(),
              ),
              items: widget.filterConfigs.map((config) => DropdownMenuItem(
                value: config,
                child: Text(config.label),
              )).toList(),
              onChanged: (config) {
                setState(() {
                  _selectedConfig = config;
                  _selectedOperator = null; // Reset operator
                  // Limpar campos de valor quando trocar de campo
                  _valueController.clear();
                  _secondValueController.clear();
                });
              },
            ),

            const SizedBox(height: 16),

            // Seleção do operador
            if (_selectedConfig != null) ...[
              DropdownButtonFormField<FilterOperator>(
                value: _selectedOperator,
                decoration: const InputDecoration(
                  labelText: 'Operador',
                  border: OutlineInputBorder(),
                ),
                items: _selectedConfig!.allowedOperators.map((op) => DropdownMenuItem(
                  value: op,
                  child: Text(_getOperatorLabel(op)),
                )).toList(),
                onChanged: (op) {
                  setState(() {
                    _selectedOperator = op;
                    // Limpar campos de valor quando trocar de operador
                    _valueController.clear();
                    _secondValueController.clear();
                  });
                },
              ),

              const SizedBox(height: 16),

              // Campos de valor
              if (_selectedOperator != null &&
                  _selectedOperator != FilterOperator.isEmpty &&
                  _selectedOperator != FilterOperator.isNotEmpty) ...[
                if (_selectedOperator == FilterOperator.between) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _valueController,
                          decoration: const InputDecoration(
                            labelText: 'Valor inicial',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: _selectedConfig!.type == SimpleFilterType.number
                              ? TextInputType.number
                              : TextInputType.text,
                          // CORREÇÃO: onChanged não é mais necessário pois temos o listener
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _secondValueController,
                          decoration: const InputDecoration(
                            labelText: 'Valor final',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: _selectedConfig!.type == SimpleFilterType.number
                              ? TextInputType.number
                              : TextInputType.text,
                          // CORREÇÃO: onChanged não é mais necessário pois temos o listener
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  if (_selectedConfig!.type == SimpleFilterType.select) ...[
                    DropdownButtonFormField<dynamic>(
                      value: _valueController.text.isNotEmpty ? _valueController.text : null,
                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        border: OutlineInputBorder(),
                      ),
                      items: _selectedConfig!.options?.map((option) => DropdownMenuItem(
                        value: option,
                        child: Text(option.toString()),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _valueController.text = value?.toString() ?? '';
                        });
                      },
                    ),
                  ] else ...[
                    TextField(
                      controller: _valueController,
                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: _selectedConfig!.type == SimpleFilterType.number
                          ? TextInputType.number
                          : TextInputType.text,
                      // CORREÇÃO: onChanged não é mais necessário pois temos o listener
                    ),
                  ],
                ],
              ],
            ],

            const SizedBox(height: 24),

            // CORREÇÃO: Adicionar indicador visual do estado do botão
            if (_selectedConfig != null && _selectedOperator != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _canCreateFilter() ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _canCreateFilter() ? Colors.green.shade300 : Colors.red.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _canCreateFilter() ? Icons.check_circle : Icons.error,
                      size: 16,
                      color: _canCreateFilter() ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _canCreateFilter()
                            ? 'Filtro pronto para ser criado'
                            : _getValidationMessage(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _canCreateFilter() ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Botões
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _canCreateFilter() ? _createFilter : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canCreateFilter()
                        ? widget.colors.primary
                        : widget.colors.onSurfaceVariant.withOpacity(0.3),
                    foregroundColor: _canCreateFilter()
                        ? Colors.white
                        : widget.colors.onSurfaceVariant.withOpacity(0.6),
                  ),
                  child: Text(widget.existingFilter != null ? 'Atualizar' : 'Criar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canCreateFilter() {
    if (_selectedConfig == null || _selectedOperator == null) return false;

    if (_selectedOperator == FilterOperator.isEmpty ||
        _selectedOperator == FilterOperator.isNotEmpty) {
      return true;
    }

    if (_selectedOperator == FilterOperator.between) {
      return _valueController.text.trim().isNotEmpty &&
          _secondValueController.text.trim().isNotEmpty;
    }

    return _valueController.text.trim().isNotEmpty;
  }

  // CORREÇÃO: Adicionar método para mensagens de validação
  String _getValidationMessage() {
    if (_selectedConfig == null) return 'Selecione um campo';
    if (_selectedOperator == null) return 'Selecione um operador';

    if (_selectedOperator == FilterOperator.isEmpty ||
        _selectedOperator == FilterOperator.isNotEmpty) {
      return 'Filtro pronto para ser criado';
    }

    if (_selectedOperator == FilterOperator.between) {
      if (_valueController.text.trim().isEmpty) return 'Digite o valor inicial';
      if (_secondValueController.text.trim().isEmpty) return 'Digite o valor final';
    } else {
      if (_valueController.text.trim().isEmpty) return 'Digite um valor';
    }

    return 'Preencha todos os campos obrigatórios';
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
      case FilterOperator.equals:
        return 'Igual a';
      case FilterOperator.notEquals:
        return 'Diferente de';
      case FilterOperator.contains:
        return 'Contém';
      case FilterOperator.notContains:
        return 'Não contém';
      case FilterOperator.startsWith:
        return 'Começa com';
      case FilterOperator.endsWith:
        return 'Termina com';
      case FilterOperator.greaterThan:
        return 'Maior que';
      case FilterOperator.lessThan:
        return 'Menor que';
      case FilterOperator.between:
        return 'Entre';
      case FilterOperator.isEmpty:
        return 'Está vazio';
      case FilterOperator.isNotEmpty:
        return 'Não está vazio';
    }
  }
}

class ColumnFilterOption<T> {
  final String field;
  final String label;
  final SimpleFilterType type;
  final List<dynamic>? options; // Para tipo select

  const ColumnFilterOption({
    required this.field,
    required this.label,
    required this.type,
    this.options,
  });
}

class HeaderColumnFilter extends StatefulWidget {
  final ColumnFilterOption filterOption;
  final Function(String field, dynamic value) onFilterChanged;
  final dynamic currentValue;
  final DataTableColorScheme colors;

  const HeaderColumnFilter({
    super.key,
    required this.filterOption,
    required this.onFilterChanged,
    this.currentValue,
    required this.colors,
  });

  @override
  State<HeaderColumnFilter> createState() => _HeaderColumnFilterState();
}

class _HeaderColumnFilterState extends State<HeaderColumnFilter> {
  late TextEditingController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.filter_alt_outlined,
        size: 16,
        color: widget.currentValue != null && widget.currentValue.toString().isNotEmpty
            ? widget.colors.primary
            : widget.colors.onSurfaceVariant,
      ),
      tooltip: 'Filtrar ${widget.filterOption.label}',
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Filtrar ${widget.filterOption.label}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: widget.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                _buildFilterWidget(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _controller.clear();
                        widget.onFilterChanged(widget.filterOption.field, null);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Limpar',
                        style: TextStyle(color: widget.colors.onSurfaceVariant),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onFilterChanged(
                          widget.filterOption.field,
                          _controller.text.isEmpty ? null : _controller.text,
                        );
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Aplicar',
                        style: TextStyle(color: widget.colors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterWidget() {
    switch (widget.filterOption.type) {
      case SimpleFilterType.text:
        return TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Digite para filtrar...',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 14),
        );

      case SimpleFilterType.number:
        return TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Digite um número...',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 14),
        );

      case SimpleFilterType.date:
        return InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              _controller.text = '${date.day}/${date.month}/${date.year}';
            }
          },
          child: IgnorePointer(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Selecionar data...',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
                suffixIcon: const Icon(Icons.calendar_today, size: 16),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );

      case SimpleFilterType.select:
        return DropdownButtonFormField<dynamic>(
          value: widget.currentValue,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          hint: const Text('Selecionar...', style: TextStyle(fontSize: 14)),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todos')),
            ...widget.filterOption.options?.map((option) => DropdownMenuItem(
              value: option,
              child: Text(option.toString(), style: const TextStyle(fontSize: 14)),
            )) ?? [],
          ],
          onChanged: (value) {
            widget.onFilterChanged(widget.filterOption.field, value);
            Navigator.pop(context);
          },
        );
    }
  }
}