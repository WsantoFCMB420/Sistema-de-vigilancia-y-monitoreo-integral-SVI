import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'theme_toggle_button.dart';

/// Distribución de las pantallas de acceso (login y registro).
/// - Web / pantallas anchas: panel de marca a la izquierda y formulario a la derecha.
/// - Celular: formulario centrado con ancho máximo.
class AuthLayout extends StatelessWidget {
  /// Contenido del formulario (marca móvil, tarjeta, enlaces).
  final List<Widget> children;

  /// Se muestra arriba del formulario solo en celular.
  final Widget? mobileHeader;

  const AuthLayout({super.key, required this.children, this.mobileHeader});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 980;

    final form = SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Align(alignment: Alignment.centerRight, child: ThemeToggleButton()),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!wide && mobileHeader != null) ...[
                        mobileHeader!,
                        const SizedBox(height: 28),
                      ],
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: wide
          ? Row(
              children: [
                const Expanded(flex: 5, child: _BrandPanel()),
                Expanded(flex: 4, child: form),
              ],
            )
          : form,
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A5DC8), Color(0xFF0B1F44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Círculos decorativos
          Positioned(
            right: -120,
            top: -80,
            child: _circle(320, Colors.white.withValues(alpha: 0.06)),
          ),
          Positioned(
            left: -90,
            bottom: -110,
            child: _circle(280, Colors.white.withValues(alpha: 0.05)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 48, 56, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Text('S.V.I.',
                        style: TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Sistema de Vigilancia\ny Monitoreo Integral',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cámaras, alertas y comunicación vecinal para el Valle de Ubaté.',
                  style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 36),
                _feature(Icons.videocam_rounded, 'Cámaras en tiempo real', 'Mira tus cámaras desde la web o el celular.'),
                _feature(Icons.notifications_active_rounded, 'Alertas comunitarias', 'Reporta y sigue cada incidente hasta cerrarlo.'),
                _feature(Icons.map_rounded, 'Mapa de la red', 'Ubica cámaras y alertas en el territorio.'),
                const Spacer(),
                const Text('Universidad de Cundinamarca • Ubaté',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  static Widget _feature(IconData icon, String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
