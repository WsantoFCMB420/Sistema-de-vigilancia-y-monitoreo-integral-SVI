import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

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

int _selectedNav = 3;
late AnimationController _lineController;
late Animation<double> _lineAnim;

  // Datos gráfica línea semanal
final List<double> _weekData = [12, 18, 14, 32, 22, 16, 28];
final List<String> _weekLabels = ['LUN','MAR','MIE','JUE','VIE','SAB','DOM'];

  // Datos gráfica barras diaria
final List<double> _dailyData = [4, 7, 18, 28, 12, 9, 14, 8];
final List<String> _dailyLabels = ['08:00','10:00','12:00','14:00','16:00','18:00','20:00','22:00'];

  // Mapa de calor (8x6 grid, valores 0..1)
late List<List<double>> _heatmap;

@override
void initState() {
    super.initState();
    final rng = Random(42);
    _heatmap = List.generate(6, (_) => List.generate(8, (_) => rng.nextDouble()));

    _lineController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _lineAnim = CurvedAnimation(parent: _lineController, curve: Curves.easeOut);
    _lineController.forward();
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
                    _buildZonasAnálisis(),
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
        Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        const Text('Sentinel Surveillance',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textDark)),
        const Spacer(),
        CircleAvatar(
            radius: 18,
            backgroundColor: _blue.withOpacity(0.15),
            child: const Icon(Icons.person_rounded, color: _blue, size: 20),
        ),
        ],
    ),
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
        value: '142',
        sub: '↑+12% vs ayer',
        subColor: _danger,
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
        value: '48/50',
        sub: '98% Activos',
        subColor: _textGray,
        icon: Icons.videocam_rounded,
        iconColor: _blue,
        ),
        _statCard(
        label: 'IA ACCURACY',
        value: '99.2%',
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
        border: highlight ? Border.all(color: _blue.withOpacity(0.2)) : null,
        boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
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
            fillColor: _blue.withOpacity(0.08),
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
                        color: isMax ? _blue : _blue.withOpacity(0.25),
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
                fnal v = _heatmap[row][col];
                return Container(
                    width: 30, height: 24,
                    decoration: BoxDecoration(
                      color: _blue.withOpacity(0.1 + v * 0.85),
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
            color: _blue.withOpacity(0.15 + i * 0.17),
            borderRadius: BorderRadius.circular(3),
        ),
        )),
        const SizedBox(width: 4),
        const Text('ALTO', style: TextStyle(fontSize: 9, color: _textGray)),
    ],
    );
}

  // ── ZONAS CRÍTICAS ────────────────────────────────────────────
Widget _buildZonasAnálisis() {
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
            iconBg: _danger.withOpacity(0.12),
            iconColor: _danger,
            name: 'Entrada Norte',
            count: '24 incidentes detectados',
            badge: 'ALTA\nPRIORIDAD',
            badgeColor: _danger,
        ),
        const SizedBox(height: 10),
        _zonaRow(
            icon: Icons.local_parking_rounded,
            iconBg: _blue.withOpacity(0.1),
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
        border: Border.all(color: Colors.black.withOpacity(0.05)),
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
            color: badgeColor.withOpacity(0.12),
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
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))
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
    final items = [
    {'icon': Icons.grid_view_rounded,          'label': 'Dashboard'},
    {'icon': Icons.map_rounded,                'label': 'Map'},
    {'icon': Icons.videocam_rounded,           'label': 'Devices'},
    {'icon': Icons.psychology_rounded,         'label': 'AI Hub'},
    {'icon': Icons.admin_panel_settings_rounded,'label': 'Admin'},
    ];
    return Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
        color: _card,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, -2))],
    ),
    child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
        final selected = i == _selectedNav;
        return GestureDetector(
            onTap: () => setState(() => _selectedNav = i),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                Icon(items[i]['icon'] as IconData,
                    color: selected ? _blue : _textGray, size: 24),
                const SizedBox(height: 4),
                Text(items[i]['label'] as String,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? _blue : _textGray)),
            ],
            ),
        );
        }),
    ),
    );
}
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