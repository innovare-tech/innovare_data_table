import 'package:flutter/material.dart';
import 'package:innovare_data_table/innovare_data_table.dart';

class SalesDashboardExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard de Vendas')),
      body: InnovareDataTable<SaleRecord>(
        title: 'Vendas Recentes',
        columns: _buildSalesColumns(),
        rows: _generateSalesData(),
        config: InnovareDataTableConfig<SaleRecord>(
          searchConfig: SearchConfig<SaleRecord>.simple(
            placeholder: "Buscar por cliente, produto...",
            searchFields: ['customerName', 'productName'],
          ),
          quickFiltersConfigs: [
            QuickFiltersConfig<SaleRecord>.dateRanges(),
            QuickFiltersConfig<SaleRecord>(
              groupLabel: "Status",
              filters: [
                QuickFilter<SaleRecord>.status(
                  id: 'completed',
                  label: 'Concluído',
                  value: 'completed',
                  color: Colors.green,
                ),
                QuickFilter<SaleRecord>.status(
                  id: 'pending',
                  label: 'Pendente',
                  value: 'pending',
                  color: Colors.orange,
                ),
                QuickFilter<SaleRecord>.status(
                  id: 'cancelled',
                  label: 'Cancelado',
                  value: 'cancelled',
                  color: Colors.red,
                ),
              ],
            ),
          ],
          loadingConfig: LoadingConfiguration(
            enableBackgroundRefresh: true,
            backgroundRefreshInterval: Duration(minutes: 1),
          ),
        ),
        mobileConfig: MobileCardConfig<SaleRecord>(
          titleBuilder: (sale) => 'Venda #${sale.id}',
          subtitleBuilder: (sale) => '${sale.customerName} • R\$ ${sale.amount.toStringAsFixed(2)}',
          fields: [
            MobileCardField<SaleRecord>(
              label: 'Produto',
              valueBuilder: (sale) => sale.productName,
              icon: Icons.shopping_bag,
            ),
            MobileCardField<SaleRecord>(
              label: 'Data',
              valueBuilder: (sale) => '${sale.date.day}/${sale.date.month}/${sale.date.year}',
              icon: Icons.calendar_today,
            ),
          ],
        ),
      ),
    );
  }

  List<DataColumnConfig<SaleRecord>> _buildSalesColumns() {
    return [
      DataColumnConfig<SaleRecord>.text(
        field: 'id',
        label: 'ID',
        valueGetter: (sale) => sale.id,
        width: 80,
      ),
      DataColumnConfig<SaleRecord>.text(
        field: 'customerName',
        label: 'Cliente',
        valueGetter: (sale) => sale.customerName,
        sortable: true,
        filterable: true,
      ),
      DataColumnConfig<SaleRecord>.text(
        field: 'productName',
        label: 'Produto',
        valueGetter: (sale) => sale.productName,
        sortable: true,
        filterable: true,
      ),
      DataColumnConfig<SaleRecord>.number(
        field: 'amount',
        label: 'Valor',
        valueGetter: (sale) => 'R\$ ${sale.amount.toStringAsFixed(2)}',
        sortable: true,
        width: 120,
      ),
      DataColumnConfig<SaleRecord>.status(
        field: 'status',
        label: 'Status',
        valueGetter: (sale) => sale.status,
        cellBuilder: (sale) => _buildSaleStatus(sale.status),
        sortable: true,
        filterable: true,
      ),
      DataColumnConfig<SaleRecord>.text(
        field: 'date',
        label: 'Data',
        valueGetter: (sale) => '${sale.date.day}/${sale.date.month}/${sale.date.year}',
        sortable: true,
      ),
    ];
  }

  Widget _buildSaleStatus(String status) {
    Color color;
    String label;

    switch (status) {
      case 'completed':
        color = Colors.green;
        label = 'Concluído';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Pendente';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelado';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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

  List<SaleRecord> _generateSalesData() {
    final customers = ['João Silva', 'Maria Santos', 'Pedro Oliveira', 'Ana Costa'];
    final products = ['Notebook', 'Mouse', 'Teclado', 'Monitor', 'Headset'];
    final statuses = ['completed', 'pending', 'cancelled'];

    return List.generate(50, (index) {
      return SaleRecord(
        id: (index + 1).toString().padLeft(4, '0'),
        customerName: customers[index % customers.length],
        productName: products[index % products.length],
        amount: 50.0 + (index * 12.5),
        status: statuses[index % statuses.length],
        date: DateTime.now().subtract(Duration(days: index)),
      );
    });
  }
}

class SaleRecord {
  final String id;
  final String customerName;
  final String productName;
  final double amount;
  final String status;
  final DateTime date;

  SaleRecord({
    required this.id,
    required this.customerName,
    required this.productName,
    required this.amount,
    required this.status,
    required this.date,
  });
}