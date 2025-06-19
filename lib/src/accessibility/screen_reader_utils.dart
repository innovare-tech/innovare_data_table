class ScreenReaderUtils {
  static String formatTableSummary({
    required int totalRows,
    required int totalColumns,
    required int visibleRows,
    required int selectedRows,
    String? title,
  }) {
    final buffer = StringBuffer();

    if (title != null) {
      buffer.write('Tabela $title. ');
    }

    buffer.write('$totalColumns colunas, $totalRows linhas no total. ');
    buffer.write('Mostrando $visibleRows linhas. ');

    if (selectedRows > 0) {
      buffer.write('$selectedRows linhas selecionadas. ');
    }

    buffer.write('Use as setas para navegar, espaço para selecionar, Control+A para selecionar tudo.');

    return buffer.toString();
  }

  static String formatCellDescription({
    required String columnName,
    required String value,
    required int rowIndex,
    required int columnIndex,
    bool isSelected = false,
    bool isSortable = false,
    bool isFilterable = false,
  }) {
    final buffer = StringBuffer();

    buffer.write('$columnName: $value. ');
    buffer.write('Linha ${rowIndex + 1}, coluna ${columnIndex + 1}. ');

    if (isSelected) {
      buffer.write('Selecionado. ');
    }

    final actions = <String>[];
    if (isSortable) actions.add('ordenável');
    if (isFilterable) actions.add('filtrável');

    if (actions.isNotEmpty) {
      buffer.write('Esta coluna é ${actions.join(' e ')}. ');
    }

    return buffer.toString();
  }

  static String formatSortStatus({
    required String columnName,
    required bool isAscending,
  }) {
    return 'Tabela ordenada por $columnName em ordem ${isAscending ? "crescente" : "decrescente"}';
  }

  static String formatFilterStatus({
    required int totalItems,
    required int filteredItems,
    required List<String> activeFilters,
  }) {
    final buffer = StringBuffer();

    if (activeFilters.isEmpty) {
      buffer.write('Nenhum filtro ativo. Mostrando todos os $totalItems itens.');
    } else {
      buffer.write('Filtros ativos: ${activeFilters.join(", ")}. ');
      buffer.write('Mostrando $filteredItems de $totalItems itens.');
    }

    return buffer.toString();
  }

  static String formatPageStatus({
    required int currentPage,
    required int totalPages,
    required int itemsPerPage,
    required int totalItems,
  }) {
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage).clamp(0, totalItems);

    return 'Página $currentPage de $totalPages. '
        'Mostrando itens $startItem a $endItem de $totalItems no total.';
  }
}
