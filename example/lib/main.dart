import 'package:flutter/material.dart';
import 'package:innovare_data_table_example/pages/home_page.dart';
import 'package:innovare_data_table_example/shell/app_shell.dart';

/// Entry point of the example app.
///
/// `AppShell` owns the currently selected `InnvPreset` + `Brightness`
/// and wires the resulting `InnovareDesignTheme` into a `MaterialApp`.
/// Every showcase page reads from `AppShellScope.of(context)` to render
/// the preset selector / dark toggle in its header, so the user can
/// flip the entire theme from any page in the app.
void main() {
  runApp(const AppShell(builder: _homeBuilder));
}

Widget _homeBuilder(BuildContext context) => const HomePage();
