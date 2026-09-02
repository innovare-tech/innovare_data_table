# innovare_data_table — Flutter (tabela de dados)

Pacote compartilhado — provê: **data-table**. `InnovareDataTable` (+ `InnovareDataTable.withDataSource`) com `HttpDataTableSource` (paginação/filtro/ordenação server-side via REST). Usado nas listagens dos frontends (unic, tessera, verba, rentcar, bolão).

## Dev
- Instalar: `flutter pub get`   Testar: `flutter test`   Analisar: `flutter analyze`

## Layout
- `lib/` (widget + `HttpDataTableSource` + colunas/filtros), `example/`, `test/`.

## Convenções / gotcha
- `HttpDataTableSource`: passar `headersBuilder` (auth) e o parser do envelope (`json['data']['data']`). ⚠️ **Não** usar `Flexible`/`Expanded` dentro de `DataCell` em scroll horizontal (largura unbounded → crash); usar `ConstrainedBox(maxWidth)` + ellipsis.

## Dependências internas
- Consome: `innovare-core` (release/2026-05-19_001), `innovare-design` (v0.0.1). Pra inspecionar → skill `resolve-dependency-source`.

## Nunca
- Editar `.dart_tool/`, `build/`.

## Pronto = `flutter analyze` limpo + `flutter test` verde.
