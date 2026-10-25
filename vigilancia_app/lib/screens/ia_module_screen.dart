import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../main.dart'; // AppRoutes
import '../widgets/theme_toggle_button.dart';
import '../widgets/responsive.dart';
import '../theme/app_colors.dart';

class IAModuleScreen extends StatefulWidget {
const IAModuleScreen({super.key});

@override
State<IAModuleScreen> createState() => _IAModuleScreenState();
}

class _IAModuleScreenState extends State<IAModuleScreen>
    with TickerProviderStateMixin {
  // ── Colores ───────────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1A5DC8);
  static const Color _danger = Color(0xFFE53935);
  static const Color _purple = Color(0xFF7C3AED);
  static const Color _liveBadge = Color(0xFF16A34A);

  AppColors get _c => AppColors.of(context);
  Color get _bg => _c.bg;
  Color get _cardBg => _c.card;
  Color get _textDark => _c.text;
  Color get _textGray => _c.label;

  // ── Estado ────────────────────────────────────────────────────
  bool _alertActive = false;
  double _precision = 98.4;
List<double> _networkLoad = [0.6, 0.45, 0.8, 0.55, 0.7, 0.5, 0.65];

late AnimationController _pulseController;
late AnimationController _alertBoxController;
late Animation<double> _pulseAnim;
late Animation<double> _alertBoxAnim;
Timer? _liveTimer;

final List<Map<String, dynamic>> _events = [
    {
    'title': 'Detección de Merodeo',
    'desc': 'Sujeto identificado permaneciendo >5 min en Zona A.',
    'time': '14:22:10',
    'icon': Icons.warning_amber_rounded,
    'color': Color(0xFFFF8C00),
    'severity': 'ALTO',
    },
    {
    'title': 'Conglomeración Detectada',
    'desc': 'Grupo inusual de 8 personas en punto de control 02.',
    'time': '14:18:45',
    'icon': Icons.groups_rounded,
    'color': Color(0xFF1A5DC8),
    'severity': 'MEDIO',
    },
    {
    'title': 'Patrón de Movimiento SOS',
    'desc': 'Detección de caída o altercado físico potencial.',
    'time': '14:05:12',
    'icon': Icons.personal_injury_rounded,
    'color': Color(0xFFE53935),
    'severity': 'CRÍTICO',
    },
];

@override
void initState() {
    super.initState();

    _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _alertBoxController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _alertBoxAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
    CurvedAnimation(parent: _alertBoxController, curve: Curves.easeInOut),
    );

    // Simular actualización de datos en vivo
    _liveTimer = Timer.periodic(const Duration(seconds: 3), (_) {
    if (mounted) {
        setState(() {
        final rng = Random();
          _networkLoad = List.generate(7, (_) => 0.3 + rng.nextDouble() * 0.6);
          _precision = 97.0 + rng.nextDouble() * 2.0;
        });
    }
    });
}

@override
void dispose() {
    _pulseController.dispose();
    _alertBoxController.dispose();
    _liveTimer?.cancel();
    super.dispose();
}

@override
Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: _bg,
    drawer: _buildDrawer(),
    body: SafeArea(
        child: ResponsiveShell(
          child: Column(
          children: [
              _buildTopBar(),
              Expanded(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildCameraFeed(),
                      const SizedBox(height: 20),
                      _buildEventosRecientes(),
                      const SizedBox(height: 20),
                      _buildNetworkCard(),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                  ],
                  ),
              ),
              ),
          ],
          ),
        ),
    ),
    );
}

  // ── TOP BAR ───────────────────────────────────────────────────
Widget _buildTopBar() {
    return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    color: _cardBg,
    child: Row(
        children: [
        Builder(builder: (ctx) => GestureDetector(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.menu_rounded, color: _primaryBlue, size: 20),
            ),
        )),
        const SizedBox(width: 10),
        Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
            color: _primaryBlue,
            borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Text(
            'IA Hub',
            style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _textDark,
            ),
        ),
        const Spacer(),
        Row(
          children: [
            const ThemeToggleButton(),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
              child: CircleAvatar(
                  radius: 18,
                  backgroundColor: _primaryBlue.withValues(alpha: 0.15),
                  child: const Icon(Icons.person_rounded, color: _primaryBlue, size: 20),
              ),
            ),
          ],
        ),
        ],
    ),
    );
}

Widget _buildDrawer() {
    const allModules = [
      _ModuleItem(Icons.dashboard_rounded, 'Dashboard', AppRoutes.dashboard, Color(0xFF1A5DC8)),
      _ModuleItem(Icons.map_rounded, 'Mapa', AppRoutes.map, Color(0xFF00897B)),
      _ModuleItem(Icons.videocam_rounded, 'Cámaras', AppRoutes.cameraView, Color(0xFF6D4C41)),
      _ModuleItem(Icons.devices_rounded, 'Dispositivos', AppRoutes.devices, Color(0xFF5E35B1)),
      _ModuleItem(Icons.warning_amber_rounded, 'Alertas', AppRoutes.alerts, Color(0xFFE53935)),
      _ModuleItem(Icons.forum_rounded, 'Comunicación', AppRoutes.communication, Color(0xFF0288D1)),
      _ModuleItem(Icons.psychology_rounded, 'IA Hub', AppRoutes.iaModule, Color(0xFF7B1FA2)),
      _ModuleItem(Icons.assessment_rounded, 'Reportes', AppRoutes.reportes, Color(0xFF2E7D32)),
      _ModuleItem(Icons.admin_panel_settings_rounded, 'Admin', AppRoutes.admin, Color(0xFFAD1457)),
    ];
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A5DC8), Color(0xFF0D1B2A)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 14),
                const Text('Sentinel SVI',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const Text('Sistema de Vigilancia Integral',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: allModules.map((mod) {
                final isCurrent = mod.route == AppRoutes.iaModule;
                return ListTile(
                  leading: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: isCurrent ? mod.color : mod.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(mod.icon, color: isCurrent ? Colors.white : mod.color, size: 20),
                  ),
                  title: Text(
                    mod.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent ? _primaryBlue : _textDark,
                    ),
                  ),
                  trailing: isCurrent
                      ? Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(color: _primaryBlue, shape: BoxShape.circle),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (!isCurrent) {
                      Navigator.pushNamed(context, mod.route);
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: _danger),
            title: const Text('Cerrar sesión', style: TextStyle(color: _danger, fontWeight: FontWeight.w600)),
            onTap: () async {
              Navigator.pop(context);
              await SessionService.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────
Widget _buildHeader() {
    return Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Row(
        children: [
        Expanded(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                'Módulo de IA',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                ),
                ),
                const SizedBox(height: 4),
                Text(
                'Análisis de comportamiento en tiempo real\ny detección de amenazas.',
                style: TextStyle(fontSize: 12, color: _textGray, height: 1.4),
                ),
            ],
            ),
        ),
        AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
            scale: _pulseAnim.value,
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                color: _liveBadge,
                borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                    Icon(Icons.circle, color: Colors.white, size: 8),
                    SizedBox(width: 5),
                    Text(
                    'EN VIVO',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                    ),
                    ),
                ],
                ),
            ),
            ),
        ),
        ],
    ),
    );
}

  // ── CAMERA FEED ───────────────────────────────────────────────
Widget _buildCameraFeed() {
    return Container(
    height: 200,
    decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1A1A2E),
        image: const DecorationImage(
        image: NetworkImage(
            'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=600&q=80',
        ),
        fit: BoxFit.cover,
        opacity: 0.4,
        ),
    ),
    child: Stack(
        children: [
          // Overlay oscuro
        Container(
            decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.6),
                ],
            ),
            ),
        ),

          // Badge IA ACTIVA
        Positioned(
            top: 12,
            right: 12,
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: _purple,
                borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                Icon(Icons.psychology_rounded, color: Colors.white, size: 13),
                SizedBox(width: 4),
                Text(
                    'IA ACTIVA',
                    style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    ),
                ),
                ],
            ),
            ),
        ),

          // Bounding box detección
        Center(
            child: AnimatedBuilder(
            animation: _alertBoxAnim,
            builder: (_, __) => Container(
                width: 120,
                height: 110,
                decoration: BoxDecoration(
                border: Border.all(
                    color: _danger.withValues(alpha: _alertBoxAnim.value),
                    width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
                ),
                child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                    color: _danger.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                    'SUJETO_005',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                    ),
                    ),
                ),
                ),
            ),
            ),
        ),

          // Alerta Merodeo
        Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                color: _danger,
                borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                '⚠ ALERTA: MERODEO',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                ),
                ),
            ),
            ),
        ),

          // Camera label
        Positioned(
            bottom: 12,
            left: 12,
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
            ),
            child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                Icon(Icons.videocam_rounded, color: Colors.white70, size: 14),
                SizedBox(width: 6),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Text(
                        'CÁMARA',
                        style: TextStyle(color: Colors.white54, fontSize: 8, letterSpacing: 1),
                    ),
                    Text(
                        'ENTRADA_PRINCIPAL_04',
                        style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        ),
                    ),
                    ],
                ),
                ],
            ),
            ),
        ),

        // Scan line animado
        _buildScanLine(),
        ],
    ),
    );
}

Widget _buildScanLine() {
    return AnimatedBuilder(
    animation: _pulseController,
    builder: (_, __) {
        return Positioned(
          top: 200 * _pulseAnim.value - 10,
        left: 0,
        right: 0,
        child: Container(
            height: 1.5,
            decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
                Colors.transparent,
                _primaryBlue.withValues(alpha: 0.8),
                Colors.transparent,
            ]),
            ),
        ),
        );
    },
    );
}

// ── EVENTOS RECIENTES ─────────────────────────────────────────
Widget _buildEventosRecientes() {
    return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
        Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
            Text(
            'Eventos Recientes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textDark),
            ),
            GestureDetector(
            onTap: () {},
            child: const Text(
                'VER TODO',
                style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _primaryBlue,
                letterSpacing: 0.5,
                ),
            ),
            ),
        ],
        ),
        const SizedBox(height: 12),
        ..._events.map((e) => _buildEventCard(e)).toList(),
    ],
    );
}

Widget _buildEventCard(Map<String, dynamic> e) {
    return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
    ),
    child: Row(
        children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
            color: (e['color'] as Color).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(e['icon'] as IconData, color: e['color'] as Color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Row(
                children: [
                    Expanded(
                    child: Text(
                        e['title'],
                        style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                        ),
                    ),
                    ),
                    Text(
                    e['time'],
                    style: TextStyle(fontSize: 11, color: _textGray),
                    ),
                ],
                ),
                const SizedBox(height: 3),
                Text(
                e['desc'],
                style: TextStyle(fontSize: 11, color: _textGray, height: 1.3),
                ),
            ],
            ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, color: _textGray, size: 20),
        ],
    ),
    );
}

  // ── NETWORK CARD ──────────────────────────────────────────────
Widget _buildNetworkCard() {
    return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 3)),
        ],
    ),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(
            'Carga de Red IA',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textDark),
        ),
        const SizedBox(height: 16),
        _buildBarChart(),
        const SizedBox(height: 14),
        Row(
            children: [
            Text(
                'PRECISIÓN',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textGray, letterSpacing: 0.8),
            ),
            const SizedBox(width: 10),
            Text(
                '${_precision.toStringAsFixed(1)}%',
                style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _primaryBlue,
                ),
            ),
            ],
        ),
        const SizedBox(height: 14),
        SizedBox(
            width: double.infinity,
            child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
                foregroundColor: _primaryBlue,
                side: const BorderSide(color: _primaryBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
                'OPTIMIZAR NODO',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1),
            ),
            ),
        ),
        ],
    ),
    );
}

Widget _buildBarChart() {
    final labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return SizedBox(
    height: 90,
    child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_networkLoad.length, (i) {
        final isHighest = _networkLoad[i] == _networkLoad.reduce(max);
        return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
            AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                width: 28,
                height: 70 * _networkLoad[i],
                decoration: BoxDecoration(
                  color: isHighest ? _purple : _primaryBlue.withValues(alpha: 0.4 + _networkLoad[i] * 0.4),
                borderRadius: BorderRadius.circular(6),
                ),
            ),
            const SizedBox(height: 4),
            Text(labels[i], style: TextStyle(fontSize: 10, color: _textGray)),
            ],
        );
        }),
    ),
    );
}

  // ── ACTION BUTTONS ────────────────────────────────────────────
Widget _buildActionButtons() {
    return Row(
    children: [
        Expanded(
        child: ElevatedButton.icon(
            onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notificación enviada al equipo')),
            );
            },
            icon: const Icon(Icons.notifications_active_rounded, size: 20),
            label: const Text(
            'NOTIFICAR\nEQUIPO',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.3),
            ),
            style: ElevatedButton.styleFrom(
            backgroundColor: _primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            ),
        ),
        ),
        const SizedBox(width: 12),
        Expanded(
        child: ElevatedButton.icon(
            onPressed: () {
            setState(() => _alertActive = !_alertActive);
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                content: Text(_alertActive ? '🚨 Alarma activada' : 'Alarma desactivada'),
                backgroundColor: _alertActive ? _danger : Colors.grey,
                ),
            );
            },
            icon: const Icon(Icons.shield_outlined, size: 20),
            label: Text(
            _alertActive ? 'ALARMA\nACTIVA' : 'ACTIVAR\nALARMA',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.3),
            ),
            style: ElevatedButton.styleFrom(
            backgroundColor: _alertActive ? _danger.withValues(alpha: 0.7) : _danger,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            ),
        ),
        ),
    ],
    );
}


}

class _ModuleItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _ModuleItem(this.icon, this.label, this.route, this.color);
}