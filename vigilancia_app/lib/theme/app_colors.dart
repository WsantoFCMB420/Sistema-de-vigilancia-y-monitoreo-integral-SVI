import 'package:flutter/material.dart';

class AppColors {
  final bool isDark;
  const AppColors._(this.isDark);

  factory AppColors.of(BuildContext context) {
    return AppColors._(Theme.of(context).brightness == Brightness.dark);
  }

  Color get bg => isDark ? const Color(0xFF0B1220) : const Color(0xFFDDE8F5);
  Color get card => isDark ? const Color(0xFF152033) : Colors.white;
  Color get text => isDark ? const Color(0xFFE8EEF8) : const Color(0xFF1A2340);
  Color get label => isDark ? const Color(0xFF9AA8C2) : const Color(0xFF6B7A99);
  Color get input => isDark ? const Color(0xFF1C2A42) : const Color(0xFFEEF4FF);
  Color get border => isDark ? const Color(0xFF2A3C5C) : const Color(0xFFD0DAEA);
  Color get hint => isDark ? const Color(0xFF7A8AA3) : const Color(0xFFADB8CC);
  Color get sheet => isDark ? const Color(0xFF121A2B) : Colors.white;

  static const Color primary = Color(0xFF1A5DC8);
  static const Color danger = Color(0xFFE53935);
}
