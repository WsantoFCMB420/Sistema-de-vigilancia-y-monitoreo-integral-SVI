import 'package:flutter/material.dart';

class Breakpoints {
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900;

  static int deviceColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1280) return 3;
    if (width >= 800) return 2;
    return 1;
  }

  static int moduleColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 6;
    if (width >= 700) return 4;
    return 3;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 900 ? 32.0 : 20.0;
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: 16);
  }
}

class ResponsiveShell extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveShell({
    super.key,
    required this.child,
    this.maxWidth = 1180,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
