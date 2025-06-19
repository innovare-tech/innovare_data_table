import 'package:flutter/material.dart';
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_data_table_example/models/user.dart';

class TestDataSourcePage extends StatefulWidget {
  @override
  _TestDataSourcePageState createState() => _TestDataSourcePageState();
}

class _TestDataSourcePageState extends State<TestDataSourcePage> {
  late DataTableController<User> _controller;
  late LocalDataTableSource<User> _dataSource;

  // DADOS DE EXEMPLO
  final List<User> _users = [
    User(id: '1', name: 'João Silva', email: 'joao@email.com', active: true, createdAt: DateTime.now().subtract(Duration(days: 10))),
    User(id: '2', name: 'Maria Santos', email: 'maria@email.com', active: true, createdAt: DateTime.now().subtract(Duration(days: 5))),
    User(id: '3', name: 'Pedro Costa', email: 'pedro@email.com', active: false, createdAt: DateTime.now().subtract(Duration(days: 15))),
    User(id: '4', name: 'Ana Oliveira', email: 'ana@email.com', active: true, createdAt: DateTime.now().subtract(Duration(days: 2))),
    User(id: '5', name: 'Carlos Pereira', email: 'carlos@email.com', active: false, createdAt: DateTime.now().subtract(Duration(days: 8))),
    // Adicione mais usuários para testar paginação...
    ...List.generate(50, (index) => User(
      id: 'user_${index + 6}',
      name: 'Usuário ${index + 6}',
      email: 'user${index + 6}@email.com',
      active: index % 3 == 0,
      createdAt: DateTime.now().subtract(Duration(days: index)),
    )),
  ];

  // CONFIGURAÇÃO DAS COLUNAS
  List<DataColumnConfig<User>> get _userColumns => [
    DataColumnConfig.text(
      field: 'name',
      label: 'Nome',
      valueGetter: (user) => user.name,
      sortable: true,
      filterable: true,
    ),
    DataColumnConfig.text(
      field: 'email',
      label: 'Email',
      valueGetter: (user) => user.email,
      sortable: true,
      filterable: true,
    ),
    DataColumnConfig.status(
      field: 'active',
      label: 'Status',
      valueGetter: (user) => user.active ? 'Ativo' : 'Inativo',
      cellBuilder: (user) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: user.active ? Colors.green.shade100 : Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: user.active ? Colors.green.shade300 : Colors.red.shade300,
          ),
        ),
        child: Text(
          user.active ? 'Ativo' : 'Inativo',
          style: TextStyle(
            color: user.active ? Colors.green.shade800 : Colors.red.shade800,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ),
    DataColumnConfig.text(
      field: 'createdAt',
      label: 'Criado em',
      valueGetter: (user) => '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
      sortable: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupDataSource();
  }

  void _setupDataSource() {
    // Criar DataSource local
    _dataSource = LocalDataTableSource<User>(
      data: _users,
      fieldGetter: (user, field) {
        switch (field) {
          case 'name':
            return user.name;
          case 'email':
            return user.email;
          case 'active':
            return user.active.toString();
          case 'createdAt':
            return user.createdAt.toString();
          case 'search':
          // Campo especial para busca global
            return '${user.name} ${user.email}';
          default:
            return '';
        }
      },
    );

    // Criar controller
    _controller = DataTableController<User>(dataSource: _dataSource);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🧪 Teste DataSource - Mini-Fase 1.1'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PAINEL DE CONTROLES PARA TESTE
            _buildTestControls(),

            SizedBox(height: 20),

            // DATATABLE COM DATASOURCE
            Expanded(
              child: InnovareDataTable.withDataSource(
                columns: _userColumns,
                dataSource: _dataSource,
                controller: _controller,
                title: 'Usuários (DataSource)',
                pageSize: 10,
                enableColumnResize: true,
                enableResponsive: true,
                showScreenSizeIndicator: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestControls() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🧪 Controles de Teste',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              // TESTE DE BUSCA
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Buscar usuários',
                    hintText: 'Digite nome ou email...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    _controller.search(value);
                  },
                ),
              ),

              // TESTE DE FILTROS
              ElevatedButton.icon(
                onPressed: () => _controller.addFilter('active', 'true'),
                icon: Icon(Icons.filter_alt, size: 16),
                label: Text('Apenas Ativos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
              ),

              ElevatedButton.icon(
                onPressed: () => _controller.addFilter('active', 'false'),
                icon: Icon(Icons.filter_alt, size: 16),
                label: Text('Apenas Inativos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
              ),

              // TESTE DE ORDENAÇÃO
              ElevatedButton.icon(
                onPressed: () => _controller.sort('name', true),
                icon: Icon(Icons.sort_by_alpha, size: 16),
                label: Text('Nome A-Z'),
              ),

              ElevatedButton.icon(
                onPressed: () => _controller.sort('name', false),
                icon: Icon(Icons.sort_by_alpha, size: 16),
                label: Text('Nome Z-A'),
              ),

              // LIMPAR TUDO
              ElevatedButton.icon(
                onPressed: () => _controller.clearFilters(),
                icon: Icon(Icons.clear_all, size: 16),
                label: Text('Limpar Filtros'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
              ),

              // REFRESH
              ElevatedButton.icon(
                onPressed: () => _controller.refresh(),
                icon: Icon(Icons.refresh, size: 16),
                label: Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // INFORMAÇÕES DE DEBUG
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Estado Atual:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• Total de registros: ${_controller.totalCount}'),
                    Text('• Página atual: ${_controller.currentRequest.page + 1}'),
                    Text('• Registros na página: ${_controller.currentData.length}'),
                    Text('• Loading: ${_controller.isLoading}'),
                    Text('• Erro: ${_controller.error ?? "Nenhum"}'),
                    Text('• Busca: "${_controller.currentRequest.searchTerm ?? ""}"'),
                    Text('• Filtros ativos: ${_controller.currentRequest.filters.length}'),
                    Text('• Ordenação: ${_controller.currentRequest.sorts.map((s) => "${s.field} ${s.ascending ? "↗️" : "↘️"}").join(", ")}'),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}