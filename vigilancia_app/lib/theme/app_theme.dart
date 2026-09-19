import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primary = Color(0xFF1A5DC8);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFDDE8F5),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A2340),
          elevation: 0,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1220),
        cardColor: const Color(0xFF152033),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF152033),
          foregroundColor: Color(0xFFE8EEF8),
          elevation: 0,
        ),
      );
}
