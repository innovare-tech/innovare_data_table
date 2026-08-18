import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innovare_data_table/innovare_data_table.dart';

/// Regressão: em telefone a tabela vira cards (`mobileConfig`) e o toque no
/// card não abria o detalhe — em NENHUMA lista de NENHUM produto.
///
/// A causa era uma troca de campo em `_buildMobileCards`: o card recebia
/// `onRowTap` (um `Widget Function(T)`, builder que ninguém no workspace
/// preenche) no lugar de `onRowTapCallback` (o `void Function(T)` que todas
/// as listas passam). Como `MobileCardsView.onItemTap` estava tipado como
/// `Function(T)?` — sem tipo de retorno —, o builder type-checava e o erro
/// não aparecia em lugar nenhum: o `InkWell` só recebia `onTap: null`.
void main() {
  final rows = ['Alpha', 'Beta'];

  Future<List<String>> pumpAndTap(WidgetTester tester, Size tela) async {
    final tapped = <String>[];

    tester.view
      ..physicalSize = tela
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: InnovareDataTable<String>(
          columns: [
            DataColumnConfig.text(
              field: 'name',
              label: 'Nome',
              valueGetter: (r) => r,
              width: 200,
            ),
          ],
          rows: rows,
          paginationEnabled: false,
          enableServerSide: false,
          enableStickyColumns: false,
          mobileConfig: MobileCardConfig<String>(
            titleBuilder: (r) => r,
            fields: const [],
          ),
          onRowTapCallback: tapped.add,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha'), warnIfMissed: false);
    await tester.pumpAndSettle();

    return tapped;
  }

  testWidgets('no card mobile, o toque dispara onRowTapCallback',
      (tester) async {
    expect(await pumpAndTap(tester, const Size(430, 932)), ['Alpha']);
  });

  testWidgets('em desktop o mesmo callback continua valendo', (tester) async {
    expect(await pumpAndTap(tester, const Size(1440, 900)), ['Alpha']);
  });
}
