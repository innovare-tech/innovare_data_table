import 'package:flutter/material.dart';
import 'package:innovare_data_table_example/pages/empty_table_page.dart';
import 'package:innovare_data_table_example/pages/products_datatable_example.dart';
import 'package:innovare_data_table_example/pages/sales_dashboard_page.dart';
import 'package:innovare_data_table_example/pages/simple_http_test_page.dart';
import 'package:innovare_data_table_example/pages/test_datasource_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Innovare Data Table Demo',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
    ),
    routes: {
      '/test_datasource': (context) => TestDataSourcePage(),
      '/simple_http': (context) => SimpleHttpTestPage(),
      '/products': (context) => ProductsDataTableExample(),
      '/sales-dashboard': (context) => SalesDashboardExample(),
      '/empty': (context) => EmptyTablePage(),
    },
    home: const InnovareDataTableDemo(),
  );
}

class InnovareDataTableDemo extends StatefulWidget {
  const InnovareDataTableDemo({super.key});

  @override
  State<InnovareDataTableDemo> createState() => _InnovareDataTableDemoState();
}

class _InnovareDataTableDemoState extends State<InnovareDataTableDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/test_datasource');
              },
              child: Text("With DataSource")
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/simple_http');
              },
              child: Text("With Simple HTTP")
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/products');
              },
              child: Text("Products")
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/sales-dashboard');
              },
              child: Text("Sales Dashboard")
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/empty');
              },
              child: Text("Empty Table Example")
            ),
          ],
        ),
      ),
    );
  }
}
