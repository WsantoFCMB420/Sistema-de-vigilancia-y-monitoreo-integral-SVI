import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return IconButton(
          tooltip: dark ? 'Cambiar a tema claro' : 'Cambiar a tema oscuro',
          onPressed: themeController.toggle,
          icon: Icon(
            dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: colors.text,
          ),
        );
      },
    );
  }
}
