import 'package:flutter/material.dart';

enum ScreenSize { mobile, tablet, desktop, ultrawide }

class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double ultrawide = 1600;

  static ScreenSize getScreenSize(double width) {
    if (width < mobile) return ScreenSize.mobile;
    if (width < tablet) return ScreenSize.tablet;
    if (width < desktop) return ScreenSize.desktop;
    return ScreenSize.ultrawide;
  }
}

class ResponsiveTableManager {
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return ResponsiveBreakpoints.getScreenSize(width);
  }

  static bool isMobile(BuildContext context) {
    return getScreenSize(context) == ScreenSize.mobile;
  }

  static bool isTablet(BuildContext context) {
    return getScreenSize(context) == ScreenSize.tablet;
  }

  static bool isDesktop(BuildContext context) {
    final size = getScreenSize(context);
    return size == ScreenSize.desktop || size == ScreenSize.ultrawide;
  }

  // Largura de colunas baseada no tamanho da tela
  static double getColumnWidth(BuildContext context, {double? customWidth}) {
    if (customWidth != null) return customWidth;

    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 120; // Mais estreito no mobile
      case ScreenSize.tablet:
        return 160;
      case ScreenSize.desktop:
        return 200; // Padrão atual
      case ScreenSize.ultrawide:
        return 220; // Mais largo em telas grandes
    }
  }

  // Número de colunas visíveis baseado no tamanho da tela
  static int getMaxVisibleColumns(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 3; // Máximo 3 colunas no mobile
      case ScreenSize.tablet:
        return 5; // Máximo 5 no tablet
      case ScreenSize.desktop:
        return 8; // Máximo 8 no desktop
      case ScreenSize.ultrawide:
        return 12; // Sem limite em telas muito grandes
    }
  }

  // Padding da tabela baseado no tamanho da tela
  static EdgeInsets getTablePadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.all(12);
      case ScreenSize.tablet:
        return const EdgeInsets.all(16);
      case ScreenSize.desktop:
      case ScreenSize.ultrawide:
        return const EdgeInsets.all(20);
    }
  }

  // Tamanho da página baseado no tamanho da tela
  static int getOptimalPageSize(BuildContext context, int defaultPageSize) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return (defaultPageSize * 0.5).round().clamp(3, 8); // Menos itens no mobile
      case ScreenSize.tablet:
        return (defaultPageSize * 0.8).round().clamp(5, 12);
      case ScreenSize.desktop:
      case ScreenSize.ultrawide:
        return defaultPageSize; // Tamanho normal
    }
  }

  static double getSearchFieldWidth(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 200;
      case ScreenSize.tablet:
        return 280;
      case ScreenSize.desktop:
        return 350;
      case ScreenSize.ultrawide:
        return 400;
    }
  }
}

class ScreenSizeIndicator extends StatelessWidget {
  const ScreenSizeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveTableManager.getScreenSize(context);
    final width = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColorForSize(screenSize),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${screenSize.name.toUpperCase()} (${width.round()}px)',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getColorForSize(ScreenSize size) {
    switch (size) {
      case ScreenSize.mobile:
        return Colors.red;
      case ScreenSize.tablet:
        return Colors.orange;
      case ScreenSize.desktop:
        return Colors.green;
      case ScreenSize.ultrawide:
        return Colors.blue;
    }
  }
}
