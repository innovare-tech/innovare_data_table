import 'package:flutter/material.dart';
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_data_table_example/models/product.dart';

class ProductsDataTableExample extends StatefulWidget {
  @override
  State<ProductsDataTableExample> createState() => _ProductsDataTableExampleState();
}

class _ProductsDataTableExampleState extends State<ProductsDataTableExample> {
  late ColumnManagerController<Product> _columnController;

  @override
  void initState() {
    super.initState();
    _columnController = ColumnManagerController<Product>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exemplo de DataTable de Produtos'),
      ),
      body: InnovareDataTable<Product>(
        quickActions: [
          QuickActionConfig.add(
            label: 'Adicionar Produto',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Adicionar Produto')),
              );
            },
          ),
          QuickActionConfig.export(
            label: 'Exportar Produtos',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Exportar Produtos')),
              );
            },
          ),
        ],
        title: 'Gestão de Produtos',
        columns: _buildProductColumns(),
        rows: _generateSampleProducts(),
        config: InnovareDataTableConfig(
          enableQuickFilters: true,
          enableAdvancedFilters: true,
          enableColumnManagement: true,
          enableMobileOptimizations: true,
          enableSearch: true,
          enableSmartLoading: true,
          searchConfig: SearchConfig<Product>.full(
            placeholder: "Buscar produtos, códigos, descrições...",
            searchFields: ['name', 'category', 'id'],
            fieldGetter: (product, field) {
              switch (field) {
                case 'name': return product.name;
                case 'category': return product.category;
                case 'id': return product.id;
                default: return product.name;
              }
            },
            maxSuggestions: 8,
            maxHistory: 10,
          ),
          quickFiltersConfigs: [
            QuickFiltersConfig<Product>(
              groupLabel: "Categoria",
              filters: [
                QuickFilter<Product>.category(
                  id: 'electronics',
                  label: 'Eletrônicos',
                  value: 'electronics',
                  icon: Icons.electrical_services,
                ),
                QuickFilter<Product>.category(
                  id: 'clothing',
                  label: 'Roupas',
                  value: 'clothing',
                  icon: Icons.checkroom,
                ),
                QuickFilter<Product>.category(
                  id: 'books',
                  label: 'Livros',
                  value: 'books',
                  icon: Icons.book,
                ),
              ],
            ),
            QuickFiltersConfig<Product>.status(
              statusList: ['active', 'inactive', 'out_of_stock'],
            ),
          ],
          advancedFiltersConfigs: [
            AdvancedFilterConfig<Product>(
              field: 'price',
              label: 'Preço',
              type: SimpleFilterType.number,
              allowedOperators: [
                FilterOperator.greaterThan,
                FilterOperator.lessThan,
                FilterOperator.between,
              ],
            ),
            AdvancedFilterConfig<Product>(
              field: 'stock',
              label: 'Estoque',
              type: SimpleFilterType.number,
            ),
            AdvancedFilterConfig<Product>(
              field: 'rating',
              label: 'Avaliação',
              type: SimpleFilterType.number,
            ),
          ],
          touchGesturesConfig: TouchGesturesConfig<Product>(
            enableSwipeActions: true,
            enableLongPressSelection: true,
            leftSwipeActions: (product) => [
              SwipeActionConfig.edit(() => _editProduct(product)),
              SwipeActionConfig.share(() => _shareProduct(product)),
            ],
            rightSwipeActions: (product) => [
              SwipeActionConfig.archive(() => _archiveProduct(product)),
              SwipeActionConfig.delete(() => _deleteProduct(product)),
            ],
            onRefresh: _refreshProducts,
          ),
          loadingConfig: LoadingConfiguration(
            enablePredictiveLoading: true,
            enableBackgroundRefresh: true,
            backgroundRefreshInterval: Duration(minutes: 2),
            predictivePageCount: 3,
          ),
          columnController: _columnController,
          onBulkAction: _handleBulkAction,
          onItemAction: _handleItemAction,
          onRefresh: _refreshProducts,
        ),

        // Configuração mobile
        mobileConfig: MobileCardConfig<Product>(
          titleBuilder: (product) => product.name,
          subtitleBuilder: (product) => '${product.category} • R\$ ${product.price.toStringAsFixed(2)}',
          leadingBuilder: (product) => CircleAvatar(
            backgroundImage: NetworkImage(product.imageUrl),
            radius: 24,
          ),
          trailingBuilder: (product) => _buildProductStatus(product),
          fields: [
            MobileCardField<Product>(
              label: 'Código',
              valueBuilder: (product) => product.id,
              icon: Icons.qr_code,
            ),
            MobileCardField<Product>(
              label: 'Estoque',
              valueBuilder: (product) => '${product.stock} unidades',
              icon: Icons.inventory,
              showOnlyIfNotEmpty: true,
            ),
            MobileCardField<Product>(
              label: 'Avaliação',
              valueBuilder: (product) => '${product.rating}/5.0',
              customBuilder: (product) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  SizedBox(width: 4),
                  Text('${product.rating}/5.0'),
                ],
              ),
            ),
            MobileCardField<Product>(
              label: 'Criado em',
              valueBuilder: (product) =>
              '${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}',
              icon: Icons.calendar_today,
            ),
          ],
        ),

        pageSize: 25,
        density: DataTableDensity.normal,
        enableSelection: false,
        showScreenSizeIndicator: true,
        enableColumnResize: true,
        enableColumnDragDrop: true,
      ),
    );
  }

  List<DataColumnConfig<Product>> _buildProductColumns() {
    return [
      // Coluna sticky com imagem e nome
      DataColumnConfig<Product>.stickyLeft(
        field: 'product',
        label: 'Produto',
        width: 280,
        valueGetter: (product) => product.name,
        cellBuilder: (product) => Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                product.imageUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(
                      width: 40,
                      height: 40,
                      color: Colors.grey[300],
                      child: Icon(Icons.image_not_supported),
                    ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    product.id,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        sortable: true,
        filterable: true,
      ),

      // Categoria
      DataColumnConfig<Product>.text(
        field: 'category',
        label: 'Categoria',
        valueGetter: (product) => product.category,
        sortable: true,
        filterable: true,
        width: 120,
      ),

      // Preço
      DataColumnConfig<Product>.number(
        field: 'price',
        label: 'Preço',
        valueGetter: (product) => 'R\$ ${product.price.toStringAsFixed(2)}',
        sortable: true,
        filterable: true,
        width: 100,
      ),

      DataColumnConfig<Product>.number(
        field: 'stock',
        label: 'Estoque',
        valueGetter: (product) => product.stock.toString(),
        cellBuilder: (product) => Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: product.stock > 10
                ? Colors.green.withOpacity(0.1)
                : product.stock > 0
                ? Colors.orange.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${product.stock} un.',
            style: TextStyle(
              color: product.stock > 10
                  ? Colors.green[700]
                  : product.stock > 0
                  ? Colors.orange[700]
                  : Colors.red[700],
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
        sortable: true,
        filterable: true,
        width: 120,
      ),

      // Status
      DataColumnConfig<Product>.status(
        field: 'status',
        label: 'Status',
        valueGetter: (product) => product.status,
        cellBuilder: (product) => _buildProductStatus(product),
        sortable: true,
        filterable: true,
      ),

      // Avaliação
      DataColumnConfig<Product>(
        field: 'rating',
        label: 'Avaliação',
        valueGetter: (product) => product.rating.toString(),
        cellBuilder: (product) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.amber, size: 16),
            SizedBox(width: 4),
            Text(
              product.rating.toStringAsFixed(1),
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        sortable: true,
        filterable: true,
        resizeConfig: ColumnResizeConfig(
          minWidth: 80,
          maxWidth: 120,
        )
      ),

      // Data de criação
      DataColumnConfig<Product>.text(
        field: 'createdAt',
        label: 'Criado em',
        valueGetter: (product) =>
        '${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}',
        sortable: true,
        width: 150,
      ),

      // Ações (sticky right)
      DataColumnConfig<Product>.stickyRight(
        field: 'actions',
        label: 'Ações',
        valueGetter: (product) => '',
        cellBuilder: (product) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, size: 18),
              onPressed: () => _editProduct(product),
              tooltip: 'Editar',
            ),
            IconButton(
              icon: Icon(Icons.more_vert, size: 18),
              onPressed: () => _showProductMenu(product),
              tooltip: 'Mais ações',
            ),
          ],
        ),
        width: 100,
      ),
    ];
  }

  Widget _buildProductStatus(Product product) {
    Color color;
    String label;

    switch (product.status) {
      case 'active':
        color = Colors.green;
        label = 'Ativo';
        break;
      case 'inactive':
        color = Colors.orange;
        label = 'Inativo';
        break;
      case 'out_of_stock':
        color = Colors.red;
        label = 'Sem Estoque';
        break;
      default:
        color = Colors.grey;
        label = product.status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  List<Product> _generateSampleProducts() {
    return List.generate(100, (index) {
      final categories = ['electronics', 'clothing', 'books', 'home', 'sports'];
      final statuses = ['active', 'inactive', 'out_of_stock'];

      return Product(
        id: 'PRD${(index + 1).toString().padLeft(3, '0')}',
        name: 'Produto ${index + 1}',
        category: categories[index % categories.length],
        price: 10.0 + (index * 5.5),
        stock: index % 4 == 0 ? 0 : (index % 50),
        status: statuses[index % statuses.length],
        createdAt: DateTime.now().subtract(Duration(days: index)),
        imageUrl: 'https://picsum.photos/100/100?random=$index',
        rating: 3.0 + (index % 3),
      );
    });
  }

  // Ações dos produtos
  void _editProduct(Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editando ${product.name}')),
    );
  }

  void _shareProduct(Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Compartilhando ${product.name}')),
    );
  }

  void _archiveProduct(Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Arquivando ${product.name}')),
    );
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.name} excluído')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showProductMenu(Product product) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _editProduct(product);
              },
            ),
            ListTile(
              leading: Icon(Icons.copy),
              title: Text('Duplicar'),
              onTap: () {
                Navigator.pop(context);
                // Implementar duplicação
              },
            ),
            ListTile(
              leading: Icon(Icons.archive),
              title: Text('Arquivar'),
              onTap: () {
                Navigator.pop(context);
                _archiveProduct(product);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Excluir', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteProduct(product);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleBulkAction(List<Product> selectedProducts) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ações em lote (${selectedProducts.length} itens)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Editar em lote'),
              onTap: () {
                Navigator.pop(context);
                // Implementar edição em lote
              },
            ),
            ListTile(
              leading: Icon(Icons.archive),
              title: Text('Arquivar selecionados'),
              onTap: () {
                Navigator.pop(context);
                // Implementar arquivamento em lote
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Excluir selecionados', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // Implementar exclusão em lote
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleItemAction(Product product, String action) {
    switch (action) {
      case 'edit':
        _editProduct(product);
        break;
      case 'delete':
        _deleteProduct(product);
        break;
      case 'archive':
        _archiveProduct(product);
        break;
    }
  }

  Future<void> _refreshProducts() async {
    // Simular refresh
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      // Atualizar dados
    });
  }
}
