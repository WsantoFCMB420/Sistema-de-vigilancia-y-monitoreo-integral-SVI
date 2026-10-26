import 'package:flutter/material.dart';

/// Paleta del proyecto. Las pantallas leen los colores con `AppColors.of(context)`
/// para que el modo claro y el oscuro cambien en un solo lugar.
class AppColors {
  final bool isDark;
  const AppColors._(this.isDark);

  factory AppColors.of(BuildContext context) {
    return AppColors._(Theme.of(context).brightness == Brightness.dark);
  }

  // Superficies
  Color get bg => isDark ? const Color(0xFF0A1020) : const Color(0xFFF2F5FA);
  Color get card => isDark ? const Color(0xFF131C2E) : Colors.white;
  Color get cardAlt => isDark ? const Color(0xFF18233A) : const Color(0xFFF7F9FC);
  Color get sheet => isDark ? const Color(0xFF111A2B) : Colors.white;
  Color get sidebar => isDark ? const Color(0xFF0D1526) : Colors.white;
  Color get input => isDark ? const Color(0xFF18233A) : const Color(0xFFF1F5FB);

  // Texto
  Color get text => isDark ? const Color(0xFFE7ECF5) : const Color(0xFF0F1B33);
  Color get label => isDark ? const Color(0xFF94A3BD) : const Color(0xFF5C6B86);
  Color get hint => isDark ? const Color(0xFF6E7D97) : const Color(0xFF9AA6BA);

  // Bordes y sombras
  Color get border => isDark ? const Color(0xFF23314C) : const Color(0xFFE2E8F2);
  Color get shadow => isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0xFF0F1B33).withValues(alpha: 0.06);

  /// Fondo suave para un color de acento (íconos, chips).
  Color tint(Color c) => c.withValues(alpha: isDark ? 0.18 : 0.10);

  List<BoxShadow> get softShadow => [
        BoxShadow(color: shadow, blurRadius: 18, offset: const Offset(0, 6)),
      ];

  // Acentos (iguales en ambos modos)
  static const Color primary = Color(0xFF1A5DC8);
  static const Color primaryDark = Color(0xFF0F3E8C);
  static const Color danger = Color(0xFFE53935);
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFF2A100);
  static const Color info = Color(0xFF0288D1);
}
