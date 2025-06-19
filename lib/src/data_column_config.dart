import 'package:flutter/material.dart';

// ENUM PARA POSIÇÃO STICKY
enum StickyPosition { left, right, none }

// CONFIGURAÇÃO DE RESIZE POR COLUNA
class ColumnResizeConfig {
  final double? initialWidth;
  final double? minWidth;
  final double? maxWidth;
  final bool resizable;

  const ColumnResizeConfig({
    this.initialWidth,
    this.minWidth = 80.0,
    this.maxWidth = 500.0,
    this.resizable = true,
  });

  // Factory para coluna não redimensionável
  factory ColumnResizeConfig.fixed(double width) {
    return ColumnResizeConfig(
      initialWidth: width,
      minWidth: width,
      maxWidth: width,
      resizable: false,
    );
  }

  // Factory para coluna com limites específicos
  factory ColumnResizeConfig.bounded({
    double? initialWidth,
    required double minWidth,
    required double maxWidth,
  }) {
    return ColumnResizeConfig(
      initialWidth: initialWidth,
      minWidth: minWidth,
      maxWidth: maxWidth,
      resizable: true,
    );
  }

  // Factory para coluna flexível
  factory ColumnResizeConfig.flexible({
    double? initialWidth,
    double minWidth = 80.0,
    double maxWidth = 500.0,
  }) {
    return ColumnResizeConfig(
      initialWidth: initialWidth,
      minWidth: minWidth,
      maxWidth: maxWidth,
      resizable: true,
    );
  }
}

// ✨ CONFIGURAÇÃO STICKY
class StickyConfig {
  final StickyPosition position;
  final bool enabled;
  final int zIndex;
  final Color? shadowColor;
  final double shadowBlur;

  const StickyConfig({
    this.position = StickyPosition.none,
    this.enabled = false,
    this.zIndex = 1,
    this.shadowColor,
    this.shadowBlur = 8.0,
  });

  factory StickyConfig.left({int zIndex = 1}) {
    return StickyConfig(
      position: StickyPosition.left,
      enabled: true,
      zIndex: zIndex,
    );
  }

  factory StickyConfig.right({int zIndex = 1}) {
    return StickyConfig(
      position: StickyPosition.right,
      enabled: true,
      zIndex: zIndex,
    );
  }

  factory StickyConfig.none() {
    return const StickyConfig(
      position: StickyPosition.none,
      enabled: false,
    );
  }
}

class DataColumnConfig<T> {
  final String field;
  final String label;
  final dynamic Function(T item) valueGetter;
  final Widget Function(T item)? cellBuilder;
  final bool sortable;
  final bool filterable;
  final Alignment alignment;

  // Configurações de resize
  final ColumnResizeConfig? resizeConfig;

  // ✨ NOVA CONFIGURAÇÃO STICKY
  final StickyConfig? stickyConfig;

  // 🔄 DEPRECATED: Manter para compatibilidade
  @Deprecated('Use resizeConfig.initialWidth instead')
  final double? width;

  @Deprecated('Use stickyConfig.enabled instead')
  final bool isSticky;

  final int priority;

  const DataColumnConfig({
    required this.field,
    required this.label,
    required this.valueGetter,
    this.cellBuilder,
    this.sortable = false,
    this.filterable = false,
    this.alignment = Alignment.centerLeft,

    // Configurações modernas
    this.resizeConfig,
    this.stickyConfig,

    // 🔄 DEPRECATED: Manter compatibilidade
    @Deprecated('Use resizeConfig.initialWidth instead')
    this.width,

    @Deprecated('Use stickyConfig.enabled instead')
    this.isSticky = false,

    this.priority = 0,
  });

  // HELPERS PARA FACILITAR MIGRAÇÃO
  double get effectiveWidth => resizeConfig?.initialWidth ?? width ?? 200.0;
  double get effectiveMinWidth => resizeConfig?.minWidth ?? 80.0;
  double get effectiveMaxWidth => resizeConfig?.maxWidth ?? 500.0;
  bool get isResizable => resizeConfig?.resizable ?? true;

  // ✨ NOVOS HELPERS STICKY
  bool get isStickyEnabled => stickyConfig?.enabled ?? isSticky;
  StickyPosition get stickyPosition => stickyConfig?.position ?? (isSticky ? StickyPosition.left : StickyPosition.none);
  int get stickyZIndex => stickyConfig?.zIndex ?? 1;

  // FACTORY CONSTRUCTORS EXPANDIDOS
  factory DataColumnConfig.text({
    required String field,
    required String label,
    required dynamic Function(T item) valueGetter,
    bool sortable = true,
    bool filterable = true,
    double? width,
    double minWidth = 100.0,
    double maxWidth = 400.0,
    StickyConfig? sticky,
    Widget Function(T item)? cellBuilder,
  }) {
    return DataColumnConfig(
      field: field,
      label: label,
      valueGetter: valueGetter,
      sortable: sortable,
      filterable: filterable,
      resizeConfig: ColumnResizeConfig.flexible(
        initialWidth: width,
        minWidth: minWidth,
        maxWidth: maxWidth,
      ),
      stickyConfig: sticky,
      cellBuilder: cellBuilder
    );
  }

  factory DataColumnConfig.number({
    required String field,
    required String label,
    required dynamic Function(T item) valueGetter,
    bool sortable = true,
    bool filterable = true,
    double? width,
    double minWidth = 80.0,
    double maxWidth = 200.0,
    StickyConfig? sticky,
    Widget Function(T item)? cellBuilder,
  }) {
    return DataColumnConfig(
      field: field,
      label: label,
      valueGetter: valueGetter,
      sortable: sortable,
      filterable: filterable,
      alignment: Alignment.centerRight,
      resizeConfig: ColumnResizeConfig.flexible(
        initialWidth: width ?? 120.0,
        minWidth: minWidth,
        maxWidth: maxWidth,
      ),
      stickyConfig: sticky,
      cellBuilder: cellBuilder,
    );
  }

  factory DataColumnConfig.action({
    required String field,
    required String label,
    required Widget Function(T item) cellBuilder,
    double width = 120.0,
    StickyConfig? sticky,
  }) {
    return DataColumnConfig(
      field: field,
      label: label,
      valueGetter: (_) => '',
      cellBuilder: cellBuilder,
      sortable: false,
      filterable: false,
      alignment: Alignment.center,
      resizeConfig: ColumnResizeConfig.fixed(width),
      stickyConfig: sticky ?? StickyConfig.right(),
    );
  }

  factory DataColumnConfig.status({
    required String field,
    required String label,
    required dynamic Function(T item) valueGetter,
    Widget Function(T item)? cellBuilder,
    double width = 100.0,
    StickyConfig? sticky,
    bool sortable = true,
    bool filterable = true,
  }) {
    return DataColumnConfig(
      field: field,
      label: label,
      valueGetter: valueGetter,
      cellBuilder: cellBuilder,
      sortable: sortable,
      filterable: filterable,
      alignment: Alignment.center,
      resizeConfig: ColumnResizeConfig.bounded(
        initialWidth: width,
        minWidth: 80.0,
        maxWidth: 150.0,
      ),
      stickyConfig: sticky,
    );
  }

  // ✨ NOVO: FACTORY PARA COLUNAS STICKY ESPECÍFICAS
  factory DataColumnConfig.stickyLeft({
    required String field,
    required String label,
    required dynamic Function(T item) valueGetter,
    Widget Function(T item)? cellBuilder,
    double width = 150.0,
    int zIndex = 1,
    bool sortable = true,
    bool filterable = true,
  }) {
    return DataColumnConfig(
      field: field,
      label: label,
      valueGetter: valueGetter,
      cellBuilder: cellBuilder,
      sortable: sortable,
      filterable: filterable,
      resizeConfig: ColumnResizeConfig.bounded(
        initialWidth: width,
        minWidth: 100.0,
        maxWidth: 300.0,
      ),
      stickyConfig: StickyConfig.left(zIndex: zIndex),
    );
  }

  factory DataColumnConfig.stickyRight({
    required String field,
    required String label,
    required dynamic Function(T item) valueGetter,
    Widget Function(T item)? cellBuilder,
    double width = 120.0,
    int zIndex = 1,
    bool sortable = false,
    bool filterable = false,
  }) {
    return DataColumnConfig(
      field: field,
      label: label,
      valueGetter: valueGetter,
      cellBuilder: cellBuilder,
      sortable: sortable,
      filterable: filterable,
      alignment: Alignment.center,
      resizeConfig: ColumnResizeConfig.bounded(
        initialWidth: width,
        minWidth: 80.0,
        maxWidth: 200.0,
      ),
      stickyConfig: StickyConfig.right(zIndex: zIndex),
    );
  }

  // COPYSWITH ATUALIZADO
  DataColumnConfig<T> copyWith({
    String? field,
    String? label,
    dynamic Function(T item)? valueGetter,
    Widget Function(T item)? cellBuilder,
    bool? sortable,
    bool? filterable,
    Alignment? alignment,
    ColumnResizeConfig? resizeConfig,
    StickyConfig? stickyConfig,
    double? width,
    bool? isSticky,
    int? priority,
  }) {
    return DataColumnConfig<T>(
      field: field ?? this.field,
      label: label ?? this.label,
      valueGetter: valueGetter ?? this.valueGetter,
      cellBuilder: cellBuilder ?? this.cellBuilder,
      sortable: sortable ?? this.sortable,
      filterable: filterable ?? this.filterable,
      alignment: alignment ?? this.alignment,
      resizeConfig: resizeConfig ?? this.resizeConfig,
      stickyConfig: stickyConfig ?? this.stickyConfig,
      width: width ?? this.width,
      isSticky: isSticky ?? this.isSticky,
      priority: priority ?? this.priority,
    );
  }
}