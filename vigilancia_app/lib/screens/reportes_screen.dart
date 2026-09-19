import 'dart:math';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class ReportesScreen extends StatefulWidget {
const ReportesScreen({super.key});
@override
State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen>
    with SingleTickerProviderStateMixin {
  // ── Colores ───────────────────────────────────────────────────
static const Color _bg         = Color(0xFFF4F7FB);
static const Color _blue       = Color(0xFF1A5DC8);
static const Color _blueSoft   = Color(0xFFEEF4FF);
static const Color _textDark   = Color(0xFF1A2340);
static const Color _textGray   = Color(0xFF6B7A99);
static const Color _card       = Colors.white;
static const Color _danger     = Color(0xFFE53935);
static const Color _success    = Color(0xFF16A34A);
static const Color _aiDark     = Color(0xFF0F2057);

late AnimationController _lineController;
late Animation<double> _lineAnim;

  // ── Datos de API ─────────────────────────────────────────────
  Map<String, dynamic>? _reportData;
  bool _loadingReport = true;

  // Datos gráfica línea semanal (desde API o fallback)
  List<double> _weekData = [0, 0, 0, 0, 0, 0, 0];
  List<String> _weekLabels = ['LUN','MAR','MIÉ','JUE','VIE','SÁB','DOM'];

  // Datos gráfica barras diaria
  final List<double> _dailyData = [4, 7, 18, 28, 12, 9, 14, 8];
  final List<String> _dailyLabels = ['08:00','10:00','12:00','14:00','16:00','18:00','20:00','22:00'];

  // Mapa de calor
  late List<List<double>> _heatmap;

@override
void initState() {
    super.initState();
    final rng = Random(42);
    _heatmap = List.generate(6, (_) => List.generate(8, (_) => rng.nextDouble()));

    _lineController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _lineAnim = CurvedAnimation(parent: _lineController, curve: Curves.easeOut);
    _lineController.forward();
    _loadReport();
}

Future<void> _loadReport() async {
    try {
      final data = await ApiService.getReports();
      if (!mounted) return;
      final days = (data['last_7_days'] as List? ?? []);
      setState(() {
        _reportData = data;
        _weekData   = days.map<double>((d) => (d['count'] as num).toDouble()).toList();
        _weekLabels = days.map<String>((d) => d['label'] as String).toList();
        _loadingReport = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingReport = false);
    }
}

@override
void dispose() {
    _lineController.dispose();
    super.dispose();
}

@override
Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: _bg,
    drawer: _buildDrawer(),
    body: SafeArea(
        child: Column(
        children: [
            _buildTopBar(),
            Expanded(
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildStatsGrid(),
                    const SizedBox(height: 16),
                    _buildWeeklyChart(),
                    const SizedBox(height: 16),
                    _buildDailyBars(),
                    const SizedBox(height: 16),
                    _buildHeatmap(),
                    const SizedBox(height: 16),
                    _buildZonasAnalisis(),
                    const SizedBox(height: 16),
                    _buildAIInsight(),
                    const SizedBox(height: 20),
                ],
                ),
            ),
            ),
            _buildBottomNav(),
        ],
        ),
    ),
    );
}

  // ── TOP BAR ───────────────────────────────────────────────────
Widget _buildTopBar() {
    return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    color: _card,
    child: Row(
        children: [
        GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.arrow_back_rounded, color: _blue, size: 20),
            ),
        ),
        const SizedBox(width: 8),
        Builder(builder: (ctx) => GestureDetector(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.menu_rounded, color: _blue, size: 20),
            ),
        )),
        const SizedBox(width: 10),
        Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        const Text('Reportes',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textDark)),
        const Spacer(),
        CircleAvatar(
            radius: 18,
            backgroundColor: _blue.withValues(alpha: 0.15),
            child: const Icon(Icons.person_rounded, color: _blue, size: 20),
        ),
        ],
    ),
    );
}

  // ── DRAWER ────────────────────────────────────────────────────
Widget _buildDrawer() {
    const mods = [
    _RepMod(Icons.dashboard_rounded,            'Dashboard',    AppRoutes.dashboard,     Color(0xFF1A5DC8)),
    _RepMod(Icons.map_rounded,                  'Mapa',         AppRoutes.map,           Color(0xFF00897B)),
    _RepMod(Icons.videocam_rounded,             'Cámaras',      AppRoutes.cameraView,    Color(0xFF6D4C41)),
    _RepMod(Icons.devices_rounded,              'Dispositivos', AppRoutes.devices,       Color(0xFF5E35B1)),
    _RepMod(Icons.warning_amber_rounded,        'Alertas',      AppRoutes.alerts,        Color(0xFFE53935)),
    _RepMod(Icons.forum_rounded,                'Comunicación', AppRoutes.communication, Color(0xFF0288D1)),
    _RepMod(Icons.psychology_rounded,           'IA Hub',       AppRoutes.iaModule,      Color(0xFF7B1FA2)),
    _RepMod(Icons.assessment_rounded,           'Reportes',     AppRoutes.reportes,      Color(0xFF2E7D32)),
    _RepMod(Icons.admin_panel_settings_rounded, 'Admin',        AppRoutes.admin,         Color(0xFFAD1457)),
    ];
    return Drawer(
    child: Column(children: [
        Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
        decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1A5DC8), Color(0xFF0D1B2A)])),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28)),
            const SizedBox(height: 14),
            const Text('Sentinel SVI', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const Text('Sistema de Vigilancia Integral', style: TextStyle(color: Colors.white60, fontSize: 12)),
        ]),
        ),
        Expanded(child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: mods.map((mod) {
            final isCurrent = mod.route == AppRoutes.reportes;
            return ListTile(
            leading: Container(width: 38, height: 38,
                decoration: BoxDecoration(
                color: isCurrent ? mod.color : mod.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
                child: Icon(mod.icon, color: isCurrent ? Colors.white : mod.color, size: 20)),
            title: Text(mod.label, style: TextStyle(
                fontSize: 14, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isCurrent ? _blue : _textDark)),
            trailing: isCurrent ? Container(width: 6, height: 6,
                decoration: BoxDecoration(color: _blue, shape: BoxShape.circle)) : null,
            onTap: () {
                Navigator.pop(context);
                if (!isCurrent) Navigator.pushNamed(context, mod.route);
            },
            );
        }).toList(),
        )),
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
    ]),
    );
}

  // ── HEADER ────────────────────────────────────────────────────
Widget _buildHeader() {
    return Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        const Text('ANÁLISIS OPERATIVO',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                color: _textGray, letterSpacing: 1.2)),
        const SizedBox(height: 6),
        Row(
            children: [
            const Expanded(
                child: Text('Reportes de\nVigilancia',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                        color: _textDark, height: 1.2)),
            ),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                    Icon(Icons.calendar_today_rounded, color: Colors.white, size: 13),
                    SizedBox(width: 6),
                    Text('Últimos 7\ndías',
                        style: TextStyle(color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.w600, height: 1.3)),
                ],
                ),
            ),
            ],
        ),
        ],
    ),
    );
}

  // ── STATS GRID ────────────────────────────────────────────────
Widget _buildStatsGrid() {
    final s = _reportData?['summary'];
    final totalAlerts   = s?['total_incidents']     ?? 0;
    final criticalAlerts = s?['critical_incidents'] ?? 0;
    final totalDevices  = s?['total_devices']        ?? 0;
    final activeDevices = s?['active_devices']       ?? 0;
    final aiAccuracy    = s?['ai_accuracy_pct']      ?? 99.2;

    return GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.55,
    children: [
        _statCard(
        label: 'INCIDENTES',
        value: _loadingReport ? '...' : '$totalAlerts',
        sub: criticalAlerts > 0 ? '↑$criticalAlerts críticas' : 'Sin críticas',
        subColor: criticalAlerts > 0 ? _danger : _success,
        icon: Icons.warning_amber_rounded,
        iconColor: _danger,
        ),
        _statCard(
        label: 'T. RESPUESTA',
        value: '2.4m',
        sub: '↓−15s mejora',
        subColor: _success,
        icon: Icons.timer_rounded,
        iconColor: _blue,
        ),
        _statCard(
        label: 'DISPOSITIVOS',
        value: _loadingReport ? '...' : '$activeDevices/$totalDevices',
        sub: totalDevices > 0 ? '${(activeDevices / totalDevices * 100).round()}% Activos' : '0% Activos',
        subColor: _textGray,
        icon: Icons.videocam_rounded,
        iconColor: _blue,
        ),
        _statCard(
        label: 'IA ACCURACY',
        value: '$aiAccuracy%',
        sub: 'Optimizado',
        subColor: _success,
        icon: Icons.psychology_rounded,
        iconColor: _blue,
        highlight: true,
        ),
    ],
    );
}

Widget _statCard({
    required String label,
    required String value,
    required String sub,
    required Color subColor,
    required IconData icon,
    required Color iconColor,
    bool highlight = false,
}) {
    return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: highlight ? _blueSoft : _card,
        borderRadius: BorderRadius.circular(14),
        border: highlight ? Border.all(color: _blue.withValues(alpha: 0.2)) : null,
        boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))
        ],
    ),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            Text(label,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                    color: _textGray, letterSpacing: 0.8)),
            Icon(icon, color: iconColor, size: 16),
            ],
        ),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 10, color: subColor, fontWeight: FontWeight.w500)),
        ],
    ),
    );
}

  // ── WEEKLY LINE CHART ─────────────────────────────────────────
Widget _buildWeeklyChart() {
    return _chartCard(
    title: 'Actividad Semanal',
    trailing: const Icon(Icons.more_vert_rounded, color: _textGray, size: 20),
    child: SizedBox(
        height: 130,
        child: AnimatedBuilder(
        animation: _lineAnim,
        builder: (_, __) => CustomPaint(
            painter: _LineChartPainter(
            data: _weekData,
            labels: _weekLabels,
            progress: _lineAnim.value,
            lineColor: _blue,
            fillColor: _blue.withValues(alpha: 0.08),
            ),
            size: Size.infinite,
        ),
        ),
    ),
    );
}

  // ── DAILY BAR CHART ───────────────────────────────────────────
Widget _buildDailyBars() {
    final maxVal = _dailyData.reduce(max);
    return _chartCard(
    title: 'Incidentes Diarios',
    trailing: const Icon(Icons.trending_up_rounded, color: _blue, size: 20),
    child: SizedBox(
        height: 120,
        child: Column(
        children: [
            Expanded(
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_dailyData.length, (i) {
                final isMax = _dailyData[i] == maxVal;
                  final h = (_dailyData[i] / maxVal) * 85;
                return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                    AnimatedContainer(
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOut,
                        width: 26,
                        height: h,
                        decoration: BoxDecoration(
                        color: isMax ? _blue : _blue.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                        ),
                    ),
                    ],
                );
                }),
            ),
            ),
            const SizedBox(height: 6),
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _dailyLabels
                .map((l) => Text(l,
                    style: const TextStyle(fontSize: 8, color: _textGray)))
                .toList(),
            ),
        ],
        ),
    ),
    );
}

  // ── HEATMAP ───────────────────────────────────────────────────
Widget _buildHeatmap() {
    return Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(
            children: [
            const Text('Mapa de Calor: Zona A',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textDark)),
            const Spacer(),
            _heatLegend(),
            ],
        ),
        const SizedBox(height: 4),
        const Text('Concentración de incidentes por cuadrante',
            style: TextStyle(fontSize: 11, color: _textGray)),
        const SizedBox(height: 14),
          // Grid
        ...List.generate(_heatmap.length, (row) {
            return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_heatmap[row].length, (col) {
                final v = _heatmap[row][col];
                return Container(
                    width: 30, height: 24,
                    decoration: BoxDecoration(
                      color: _blue.withValues(alpha: 0.1 + v * 0.85),
                    borderRadius: BorderRadius.circular(4),
                    ),
                );
                }),
            ),
            );
        }),
        const SizedBox(height: 12),
        Row(
            children: [
            const Icon(Icons.location_on_rounded, color: _blue, size: 16),
            const SizedBox(width: 4),
            const Expanded(
                child: Text('Campus Principal – Nivel 2',
                    style: TextStyle(fontSize: 12, color: _textGray)),
            ),
            GestureDetector(
                onTap: () {},
                child: Row(
                children: const [
                    Text('Ver mapa completo',
                        style: TextStyle(fontSize: 12, color: _blue, fontWeight: FontWeight.w600)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, color: _blue, size: 14),
                ],
                ),
            ),
            ],
        ),
        ],
    ),
    );
}

Widget _heatLegend() {
    return Row(
    children: [
        const Text('BAJO', style: TextStyle(fontSize: 9, color: _textGray)),
        const SizedBox(width: 4),
        ...List.generate(5, (i) => Container(
        width: 14, height: 14,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
            color: _blue.withValues(alpha: 0.15 + i * 0.17),
            borderRadius: BorderRadius.circular(3),
        ),
        )),
        const SizedBox(width: 4),
        const Text('ALTO', style: TextStyle(fontSize: 9, color: _textGray)),
    ],
    );
}

  // ── ZONAS CRÍTICAS ────────────────────────────────────────────
Widget _buildZonasAnalisis() {
    return Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        const Text('Análisis de Zonas Críticas',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textDark)),
        const SizedBox(height: 14),
        _zonaRow(
            icon: Icons.door_front_door_rounded,
            iconBg: _danger.withValues(alpha: 0.12),
            iconColor: _danger,
            name: 'Entrada Norte',
            count: '24 incidentes detectados',
            badge: 'ALTA\nPRIORIDAD',
            badgeColor: _danger,
        ),
        const SizedBox(height: 10),
        _zonaRow(
            icon: Icons.local_parking_rounded,
            iconBg: _blue.withValues(alpha: 0.1),
            iconColor: _blue,
            name: 'Estacionamiento B',
            count: '8 incidentes detectados',
            badge: 'ESTABLE',
            badgeColor: _success,
        ),
        ],
    ),
    );
}

Widget _zonaRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String name,
    required String count,
    required String badge,
    required Color badgeColor,
}) {
    return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
    ),
    child: Row(
        children: [
        Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textDark)),
                const SizedBox(height: 2),
                Text(count, style: const TextStyle(fontSize: 11, color: _textGray)),
            ],
            ),
        ),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            ),
            child: Text(badge,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: badgeColor, height: 1.3)),
        ),
        ],
    ),
    );
}

 // ── AI INSIGHT ────────────────────────────────────────────────
Widget _buildAIInsight() {
    return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        color: _aiDark,
        borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(
            children: const [
            Icon(Icons.auto_awesome_rounded, color: Colors.white70, size: 18),
            SizedBox(width: 8),
            Text('AI Insight',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
        ),
        const SizedBox(height: 12),
        const Text(
            'Se observa un patrón inusual entre las 02:00 AM y 04:00 AM en la Entrada Norte. '
            'Recomendamos reforzar patrullaje manual.',
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
        ),
        const SizedBox(height: 18),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton(
            onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Protocolo ejecutado')),
                );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _aiDark,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ejecutar Protocolo',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
        ),
        ],
    ),
    );
}

  // ── HELPERS ───────────────────────────────────────────────────
BoxDecoration _cardDecoration() => BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))
        ],
    );

Widget _chartCard({required String title, required Widget child, Widget? trailing}) {
    return Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(
            children: [
            Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textDark)),
            const Spacer(),
            if (trailing != null) trailing,
            ],
        ),
        const SizedBox(height: 16),
        child,
        ],
    ),
    );
}

  // ── BOTTOM NAV ────────────────────────────────────────────────
Widget _buildBottomNav() {
    const navItems = [
    _NavEntry(Icons.dashboard_rounded,            'Dashboard', AppRoutes.dashboard),
    _NavEntry(Icons.map_rounded,                  'Mapa',      AppRoutes.map),
    _NavEntry(Icons.assessment_rounded,           'Reportes',  AppRoutes.reportes),
    _NavEntry(Icons.psychology_rounded,           'IA Hub',    AppRoutes.iaModule),
    _NavEntry(Icons.admin_panel_settings_rounded, 'Admin',     AppRoutes.admin),
    ];
    return Container(
    decoration: BoxDecoration(
        color: _card,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
    ),
    child: SafeArea(child: SizedBox(height: 64,
        child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (i) {
            final selected = i == 2; // Reportes = índice 2
            final entry = navItems[i];
            return GestureDetector(
            onTap: () {
                if (selected) return;
                Navigator.pushNamed(context, entry.route);
            },
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Icon(entry.icon, color: selected ? _blue : _textGray, size: 24),
                const SizedBox(height: 4),
                Text(entry.label, style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? _blue : _textGray)),
                ],
            ),
            );
        }),
        ),
    )),
    );
}
}

class _NavEntry {
  final IconData icon;
  final String label;
  final String route;
  const _NavEntry(this.icon, this.label, this.route);
}

class _RepMod {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _RepMod(this.icon, this.label, this.route, this.color);
}

// ── LINE CHART PAINTER ────────────────────────────────────────────
class _LineChartPainter extends CustomPainter {
final List<double> data;
final List<String> labels;
final double progress;
final Color lineColor;
final Color fillColor;

_LineChartPainter({
    required this.data,
    required this.labels,
    required this.progress,
    required this.lineColor,
    required this.fillColor,
});

@override
void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const double bottomPad = 22;
    const double topPad = 8;
    final double chartH = size.height - bottomPad - topPad;
    final double chartW = size.width;

    final double maxVal = data.reduce(max);
    final double minVal = data.reduce(min);
    final double range = (maxVal - minVal).clamp(1.0, double.infinity);

    List<Offset> pts = [];
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * chartW;
      final y = topPad + chartH * (1 - (data[i] - minVal) / range);
    pts.add(Offset(x, y));
    }

    // Clip progress
    final int lastIdx = ((pts.length - 1) * progress).floor();
    final double frac = ((pts.length - 1) * progress) - lastIdx;
    final List<Offset> visible = [
    ...pts.sublist(0, lastIdx + 1),
    if (lastIdx < pts.length - 1)
        Offset(
          pts[lastIdx].dx + (pts[lastIdx + 1].dx - pts[lastIdx].dx) * frac,
          pts[lastIdx].dy + (pts[lastIdx + 1].dy - pts[lastIdx].dy) * frac,
        ),
    ];

    if (visible.length < 2) return;

    // Fill path
    final fillPath = Path();
    fillPath.moveTo(visible.first.dx, size.height - bottomPad);
    fillPath.lineTo(visible.first.dx, visible.first.dy);
    for (int i = 1; i < visible.length; i++) {
    final cp1 = Offset((visible[i - 1].dx + visible[i].dx) / 2, visible[i - 1].dy);
    final cp2 = Offset((visible[i - 1].dx + visible[i].dx) / 2, visible[i].dy);
    fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, visible[i].dx, visible[i].dy);
    }
    fillPath.lineTo(visible.last.dx, size.height - bottomPad);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor..style = PaintingStyle.fill);

    // Line path
    final linePath = Path();
    linePath.moveTo(visible.first.dx, visible.first.dy);
    for (int i = 1; i < visible.length; i++) {
    final cp1 = Offset((visible[i - 1].dx + visible[i].dx) / 2, visible[i - 1].dy);
    final cp2 = Offset((visible[i - 1].dx + visible[i].dx) / 2, visible[i].dy);
    linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, visible[i].dx, visible[i].dy);
    }
    canvas.drawPath(
    linePath,
    Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Dot at last visible point
    canvas.drawCircle(
    visible.last,
    4,
    Paint()..color = lineColor,
    );
    canvas.drawCircle(
    visible.last,
    2,
    Paint()..color = Colors.white,
    );

    // Labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < labels.length; i++) {
      final x = i / (labels.length - 1) * chartW;
    tp.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 9),
    );
    tp.layout();
    tp.paint(canvas, Offset(x - tp.width / 2, size.height - bottomPad + 6));
    }
}

@override
bool shouldRepaint(covariant _LineChartPainter old) =>
    old.progress != progress || old.data != data;
}