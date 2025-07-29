import 'package:flutter/material.dart';
import 'package:innovare_data_table/innovare_data_table.dart';

class EmptyTablePage extends StatelessWidget {
  const EmptyTablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InnovareDataTable<Person>(
        columns: [
          DataColumnConfig(
            field: "id",
            label: "ID",
            valueGetter: (item) => item.id.toString(),
          ),
          DataColumnConfig(
            field: "name",
            label: "Nome",
            valueGetter: (item) => item.name,
          ),
          DataColumnConfig(
            field: "age",
            label: "Idade",
            valueGetter: (item) => item.age.toString(),
          )
        ],
        rows: []
      ),
    );
  }
}

class Person {
  final int id;
  final String name;
  final int age;

  Person({required this.id, required this.name, required this.age});
}