import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class IAModuleScreen extends StatefulWidget {
const IAModuleScreen({super.key});

@override
State<IAModuleScreen> createState() => _IAModuleScreenState();
}

class _IAModuleScreenState extends State<IAModuleScreen>
    with TickerProviderStateMixin {
  // ── Colores ───────────────────────────────────────────────────
static const Color _bg = Color(0xFFF4F7FB);
static const Color _primaryBlue = Color(0xFF1A5DC8);
static const Color _danger = Color(0xFFE53935);
static const Color _warning = Color(0xFFFF8C00);
static const Color _purple = Color(0xFF7C3AED);
static const Color _textDark = Color(0xFF1A2340);
static const Color _textGray = Color(0xFF6B7A99);
static const Color _cardBg = Colors.white;
static const Color _liveBadge = Color(0xFF16A34A);

  // ── Estado ────────────────────────────────────────────────────
bool _iaActive = true;
bool _alertActive = false;
int _selectedNav = 3; // AI Hub seleccionado
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
    color: _cardBg,
    child: Row(
        children: [
        Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
            color: _primaryBlue,
            borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        const Text(
            'Sentinel Surveillance',
            style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _textDark,
            ),
        ),
        const Spacer(),
        CircleAvatar(
            radius: 18,
            backgroundColor: _primaryBlue.withOpacity(0.15),
            child: const Icon(Icons.person_rounded, color: _primaryBlue, size: 20),
        ),
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
                const Text(
                'Módulo de IA',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                ),
                ),
                const SizedBox(height: 4),
                const Text(
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
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.6),
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
                    color: _danger.withOpacity(_alertBoxAnim.value),
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
                    color: _danger.withOpacity(0.9),
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
                color: Colors.black.withOpacity(0.6),
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
                _primaryBlue.withOpacity(0.8),
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
            const Text(
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
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
    ),
    child: Row(
        children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
            color: (e['color'] as Color).withOpacity(0.12),
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
                        style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                        ),
                    ),
                    ),
                    Text(
                    e['time'],
                    style: const TextStyle(fontSize: 11, color: _textGray),
                    ),
                ],
                ),
                const SizedBox(height: 3),
                Text(
                e['desc'],
                style: const TextStyle(fontSize: 11, color: _textGray, height: 1.3),
                ),
            ],
            ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right_rounded, color: _textGray, size: 20),
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
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3)),
        ],
    ),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        const Text(
            'Carga de Red IA',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textDark),
        ),
        const SizedBox(height: 16),
        _buildBarChart(),
        const SizedBox(height: 14),
        Row(
            children: [
            const Text(
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
                  color: isHighest ? _purple : _primaryBlue.withOpacity(0.4 + _networkLoad[i] * 0.4),
                borderRadius: BorderRadius.circular(6),
                ),
            ),
            const SizedBox(height: 4),
            Text(labels[i], style: const TextStyle(fontSize: 10, color: _textGray)),
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
            backgroundColor: _alertActive ? _danger.withOpacity(0.7) : _danger,
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

  // ── BOTTOM NAV ────────────────────────────────────────────────
Widget _buildBottomNav() {
    final items = [
    {'icon': Icons.grid_view_rounded, 'label': 'Dashboard'},
    {'icon': Icons.map_rounded, 'label': 'Map'},
    {'icon': Icons.videocam_rounded, 'label': 'Devices'},
    {'icon': Icons.psychology_rounded, 'label': 'AI Hub'},
    {'icon': Icons.admin_panel_settings_rounded, 'label': 'Admin'},
    ];

    return Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
        color: _cardBg,
        boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, -2)),
        ],
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
                Stack(
                clipBehavior: Clip.none,
                children: [
                    Icon(
                    items[i]['icon'] as IconData,
                    color: selected ? _primaryBlue : _textGray,
                    size: 24,
                    ),
                    if (i == 3) // Badge en AI Hub
                    Positioned(
                        top: -4,
                        right: -6,
                        child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                            color: _danger,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Center(
                            child: Text('3', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                        ),
                        ),
                    ),
                ],
                ),
                const SizedBox(height: 4),
                Text(
                items[i]['label'] as String,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? _primaryBlue : _textGray,
                ),
                ),
            ],
            ),
        );
        }),
    ),
    );
}
}