import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    final seed = const Color(0xFF0D9488);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }

  static ThemeData dark() {
    final seed = const Color(0xFF5EEAD4);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }
}
