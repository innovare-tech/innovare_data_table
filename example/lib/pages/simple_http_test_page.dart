// =============================================================================
// ARQUIVO: lib/example/simple_http_test_page.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_data_table_example/models/user.dart';

class SimpleHttpTestPage extends StatefulWidget {
  @override
  _SimpleHttpTestPageState createState() => _SimpleHttpTestPageState();
}

class _SimpleHttpTestPageState extends State<SimpleHttpTestPage> {
  late DataTableController<User> _controller;
  late HttpDataTableSource<User> _dataSource;

  @override
  void initState() {
    super.initState();
    _setupHttpDataSource();
  }

  void _setupHttpDataSource() {
    // 🌐 TESTE COM API PÚBLICA - JSONPlaceholder
    _dataSource = HttpDataTableSource<User>(
      urlBuilder: (request) {
        print('🔗 Construindo URL para request: page=${request.page}, search="${request.searchTerm}"');

        // JSONPlaceholder - API pública para testes
        final baseUrl = 'https://jsonplaceholder.typicode.com/users';

        // Para este exemplo, vamos simular server-side filtering
        if (request.searchTerm?.isNotEmpty == true) {
          // Simular busca por ID (JSONPlaceholder suporta /users/1, /users/2, etc.)
          final searchId = int.tryParse(request.searchTerm!);
          if (searchId != null && searchId >= 1 && searchId <= 10) {
            return '$baseUrl/$searchId';
          }
        }

        return baseUrl;
      },

      headersBuilder: () {
        print('🔑 Construindo headers');
        return {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
      },

      responseParser: (json) {
        print('📄 Parsing response: ${json.runtimeType}');

        List<User> users = [];

        if (json is List<dynamic>) {
          final jsonList = json as List<dynamic>;
          print('📋 Response é lista com ${jsonList.length} itens');

          // ✅ DEBUG ITEM POR ITEM
          for (int i = 0; i < jsonList.length; i++) {
            try {
              final item = jsonList[i];
              print('🔍 Item $i: tipo=${item.runtimeType}');

              if (item is Map<String, dynamic>) {
                final userItem = item;
                print('🔍 Item $i: ID=${userItem['id']}, Name=${userItem['name']}');

                final user = User(
                  id: userItem['id'].toString(),
                  name: userItem['name'],
                  email: userItem['email'],
                  active: userItem['id'] % 2 == 0,
                  createdAt: DateTime.now().subtract(Duration(days: userItem['id'] * 2)),
                );

                users.add(user);
                print('✅ Item $i: User criado com sucesso');
              } else {
                print('❌ Item $i: Não é Map<String, dynamic>, é ${item.runtimeType}');
              }
            } catch (e, stackTrace) {
              print('❌ Erro processando item $i: $e');
              print('❌ Stack trace item $i: $stackTrace');
            }
          }

        } else if (json is Map<String, dynamic>) {
          print('📄 Response é objeto único');
          final userMap = json;

          users = [User(
            id: userMap['id'].toString(),
            name: userMap['name'],
            email: userMap['email'],
            active: userMap['id'] % 2 == 0,
            createdAt: DateTime.now().subtract(Duration(days: userMap['id'] * 2)),
          )];
        }

        print('📊 Total de usuários processados: ${users.length}');

        return DataTableResult<User>(
          data: users,
          totalCount: users.length,
          page: 0,
          pageSize: users.length,
          metadata: {'source': 'jsonplaceholder', 'type': 'list'},
        );
      },

      errorHandler: (error, stackTrace) {
        print('❌ Erro HTTP: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na API: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },

      enableCache: true,
    );

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
        title: Text('🌐 Teste HTTP Simples'),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInstructions(),
            SizedBox(height: 16),
            _buildControls(),
            SizedBox(height: 20),
            Expanded(
              child: InnovareDataTable.withDataSource(
                columns: _getUserColumns(),
                dataSource: _dataSource,
                controller: _controller,
                title: 'Usuários via JSONPlaceholder API',
                pageSize: 3, // Páginas pequenas para testar paginação
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

  Widget _buildInstructions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.teal.shade700),
              SizedBox(width: 8),
              Text(
                'Como Testar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• Esta tabela consome dados da API pública JSONPlaceholder\n'
                '• Digite um número de 1 a 10 na busca para filtrar por usuário específico\n'
                '• Use os botões de paginação para navegar\n'
                '• Observe o console para ver as requisições HTTP',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
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
            '🎮 Controles HTTP',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              // Campo de busca
              SizedBox(
                width: 250,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Buscar usuário por ID',
                    hintText: 'Digite 1, 2, 3... até 10',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    print('🔍 Iniciando busca por: "$value"');
                    _controller.search(value);
                  },
                ),
              ),

              // Botões de paginação
              ElevatedButton.icon(
                onPressed: () {
                  print('📄 Indo para primeira página');
                  _controller.goToPage(0);
                },
                icon: Icon(Icons.first_page, size: 16),
                label: Text('Primeira'),
              ),

              ElevatedButton.icon(
                onPressed: () {
                  print('📄 Página anterior');
                  _controller.previousPage();
                },
                icon: Icon(Icons.navigate_before, size: 16),
                label: Text('Anterior'),
              ),

              ElevatedButton.icon(
                onPressed: () {
                  print('📄 Próxima página');
                  _controller.nextPage();
                },
                icon: Icon(Icons.navigate_next, size: 16),
                label: Text('Próxima'),
              ),

              // Ações
              ElevatedButton.icon(
                onPressed: () {
                  print('🔄 Fazendo refresh');
                  _controller.refresh();
                },
                icon: Icon(Icons.refresh, size: 16),
                label: Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
              ),

              ElevatedButton.icon(
                onPressed: () {
                  print('🗑️ Limpando cache');
                  _dataSource.clearCache();
                  _controller.refresh();
                },
                icon: Icon(Icons.clear_all, size: 16),
                label: Text('Limpar Cache'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Status em tempo real
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
                      '📊 Status HTTP em Tempo Real:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _controller.isLoading
                                ? Colors.orange
                                : (_controller.error != null ? Colors.red : Colors.green),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(_controller.isLoading
                            ? 'Carregando...'
                            : (_controller.error != null ? 'Erro' : 'OK')),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text('• Total de registros: ${_controller.totalCount}'),
                    Text('• Página atual: ${_controller.currentRequest.page + 1}'),
                    Text('• Registros na página: ${_controller.currentData.length}'),
                    Text('• Busca ativa: "${_controller.currentRequest.searchTerm ?? 'Nenhuma'}"'),
                    if (_controller.error != null)
                      Text('• Erro: ${_controller.error}',
                          style: TextStyle(color: Colors.red.shade700)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<DataColumnConfig<User>> _getUserColumns() {
    return [
      DataColumnConfig.text(
        field: 'id',
        label: 'ID',
        valueGetter: (user) => user.id,
        sortable: true,
      ),
      DataColumnConfig.text(
        field: 'name',
        label: 'Nome',
        valueGetter: (user) => user.name,
        sortable: true,
      ),
      DataColumnConfig.text(
        field: 'email',
        label: 'Email',
        valueGetter: (user) => user.email,
        sortable: true,
      ),
      DataColumnConfig.status(
        field: 'active',
        label: 'Status',
        valueGetter: (user) => user.active ? 'Ativo' : 'Inativo',
        cellBuilder: (user) => Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: user.active ? Colors.green.shade100 : Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: user.active ? Colors.green.shade300 : Colors.orange.shade300,
            ),
          ),
          child: Text(
            user.active ? 'Ativo' : 'Inativo',
            style: TextStyle(
              color: user.active ? Colors.green.shade800 : Colors.orange.shade800,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    ];
  }
}