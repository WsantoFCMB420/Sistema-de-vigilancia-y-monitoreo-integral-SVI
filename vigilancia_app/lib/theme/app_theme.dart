import 'package:flutter/material.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  IconData? icon,
  Duration duration = const Duration(milliseconds: 2200),
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
      duration: duration,
      backgroundColor: backgroundColor ?? const Color(0xFF1A5DC8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}

class AppTheme {
  static const Color _primary = Color(0xFF1A5DC8);

  static ThemeData get light => _build(
        brightness: Brightness.light,
        bg: const Color(0xFFF2F5FA),
        surface: Colors.white,
        text: const Color(0xFF0F1B33),
        label: const Color(0xFF5C6B86),
        border: const Color(0xFFE2E8F2),
        input: const Color(0xFFF1F5FB),
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        bg: const Color(0xFF0A1020),
        surface: const Color(0xFF131C2E),
        text: const Color(0xFFE7ECF5),
        label: const Color(0xFF94A3BD),
        border: const Color(0xFF23314C),
        input: const Color(0xFF18233A),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color text,
    required Color label,
    required Color border,
    required Color input,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: brightness,
    ).copyWith(
      primary: _primary,
      surface: surface,
      onSurface: text,
      outline: border,
      error: const Color(0xFFE53935),
    );

    final radius12 = BorderRadius.circular(12);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: surface,
      cardColor: surface,
      dividerColor: border,
      visualDensity: VisualDensity.standard,
      textTheme: _textTheme(brightness, text, label),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: text),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: input,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(color: label.withValues(alpha: 0.8), fontSize: 14),
        labelStyle: TextStyle(color: label, fontSize: 14),
        border: OutlineInputBorder(borderRadius: radius12, borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: radius12, borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: const BorderSide(color: _primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(48, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: radius12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 46),
          shape: RoundedRectangleBorder(borderRadius: radius12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size(48, 46),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: radius12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: input,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w600),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: text),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _primary.withValues(alpha: 0.14),
        height: 66,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? _primary : label,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? _primary : label, size: 23);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: _primary,
        unselectedLabelColor: label,
        indicatorColor: _primary,
        dividerColor: border,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.horizontal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1B33),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: _primary),
      // Transición corta entre módulos (la de zoom por defecto se siente lenta en web).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _QuickFadeTransitionsBuilder(),
          TargetPlatform.iOS: _QuickFadeTransitionsBuilder(),
          TargetPlatform.windows: _QuickFadeTransitionsBuilder(),
          TargetPlatform.linux: _QuickFadeTransitionsBuilder(),
          TargetPlatform.macOS: _QuickFadeTransitionsBuilder(),
          TargetPlatform.fuchsia: _QuickFadeTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(Brightness b, Color text, Color label) {
    final base = (b == Brightness.dark ? ThemeData.dark() : ThemeData.light()).textTheme;
    return base
        .apply(bodyColor: text, displayColor: text)
        .copyWith(
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.3),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: text, letterSpacing: -0.2),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text),
          bodyMedium: TextStyle(fontSize: 14, color: text, height: 1.4),
          bodySmall: TextStyle(fontSize: 12, color: label, height: 1.35),
          labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: label, letterSpacing: 0.6),
        );
  }
}

/// Desvanecimiento con un leve desplazamiento. Se completa en la primera parte
/// de la animación, por eso el cambio de pantalla se percibe inmediato.
class _QuickFadeTransitionsBuilder extends PageTransitionsBuilder {
  const _QuickFadeTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: const Interval(0, 0.6, curve: Curves.easeOut));
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}
