import 'package:flutter/material.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _currentIndex = 1;

  // ── Paleta idéntica al Dashboard ──────────────────────────────────────────
  static const Color _bgColor = Color(0xFFDDE8F5);
  static const Color _primaryBlue = Color(0xFF1A5DC8);
  static const Color _cardColor = Colors.white;
  static const Color _labelColor = Color(0xFF6B7A99);
  static const Color _textColor = Color(0xFF1A2340);
  static const Color _dangerColor = Color(0xFFE53935);
  static const Color _successColor = Color(0xFF43A047);

  // Nodos del mapa (simulados)
  final List<_MapNode> _nodes = [
    _MapNode(label: 'A1', x: 0.22, y: 0.35, isAlert: true),
    _MapNode(label: 'B2', x: 0.55, y: 0.25, isAlert: false),
    _MapNode(label: 'C3', x: 0.70, y: 0.55, isAlert: false),
    _MapNode(label: 'D4', x: 0.38, y: 0.65, isAlert: true),
    _MapNode(label: 'E5', x: 0.80, y: 0.30, isAlert: false),
  ];

  _MapNode? _selectedNode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildTopBar(),
            ),
            Expanded(
              child: Stack(
                children: [
                  _buildMap(),
                  Positioned(top: 12, left: 16, child: _buildStatusCard()),
                  Positioned(top: 12, right: 16, child: _buildMapControls()),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomPanel(),
                  ),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _primaryBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Sentinel Surveillance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.search_rounded, color: _textColor),
              onPressed: () {},
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: _primaryBlue.withOpacity(0.15),
              child: const Icon(
                Icons.person_rounded,
                color: _primaryBlue,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Mapa simulado ──────────────────────────────────────────────────────────
  Widget _buildMap() {
    return Container(
      margin: const EdgeInsets.only(bottom: 180),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1B2A), Color(0xFF0A2540), Color(0xFF0D1B2A)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Grid de líneas del mapa
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _MapGridPainter(),
              ),
              // Punto central de brillo
              Positioned(
                left: constraints.maxWidth * 0.50 - 40,
                top: constraints.maxHeight * 0.42 - 40,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primaryBlue.withOpacity(0.15),
                  ),
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _primaryBlue.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
              ),
              // Nodos
              ..._nodes.map((node) {
                return Positioned(
                  left: constraints.maxWidth * node.x - 16,
                  top: constraints.maxHeight * node.y - 16,
                  child: GestureDetector(
                    onTap: () => setState(
                      () => _selectedNode = _selectedNode == node ? null : node,
                    ),
                    child: _buildMapNodeWidget(node),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapNodeWidget(_MapNode node) {
    final isSelected = _selectedNode == node;
    final color = node.isAlert ? _dangerColor : _primaryBlue;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Icon(
            node.isAlert ? Icons.warning_rounded : Icons.videocam_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
        if (isSelected) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'CAM-${node.label}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Tarjeta de estado del sistema ─────────────────────────────────────────
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'SYSTEM STATUS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _labelColor,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          _statusRow('Active Nodes', '1,248', _textColor),
          const SizedBox(height: 4),
          _statusRow('Alerts', '3 CRITICAL', _dangerColor),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: _labelColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ── Controles del mapa (zoom + location) ──────────────────────────────────
  Widget _buildMapControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _mapControlBtn(Icons.add, () {}),
        const SizedBox(height: 6),
        _mapControlBtn(Icons.remove, () {}),
        const SizedBox(height: 12),
        _mapControlBtn(Icons.my_location_rounded, () {}, color: _primaryBlue),
      ],
    );
  }

  Widget _mapControlBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _cardColor.withOpacity(0.92),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color ?? _textColor, size: 20),
      ),
    );
  }

  // ── Panel inferior con cámara en vivo + info ──────────────────────────────
  Widget _buildBottomPanel() {
    return Container(
      height: 185,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Miniatura de cámara en vivo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 130,
                      height: 88,
                      color: const Color(0xFF0D1117),
                      child: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF0D1B2A), Color(0xFF1A3A5C)],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.videocam_rounded,
                                color: _primaryBlue,
                                size: 32,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _dangerColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: Colors.white,
                                    size: 5,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'LIVE  CAM-042',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Info de ubicación
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Main Entrance Alpha',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'NORMAL',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: _successColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'North-East Perimeter • Station 4',
                          style: TextStyle(fontSize: 11, color: _labelColor),
                        ),
                        const SizedBox(height: 10),
                        // Barra de progreso de señal
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: 0.82,
                                  minHeight: 4,
                                  backgroundColor: const Color(0xFFE0E0E0),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        _primaryBlue,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '82%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Señal',
                          style: TextStyle(fontSize: 10, color: _labelColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Bottom Navigation (idéntica al Dashboard) ─────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      _NavItem(Icons.dashboard_rounded, 'Dashboard'),
      _NavItem(Icons.map_rounded, 'Map'),
      _NavItem(Icons.videocam_rounded, 'Devices'),
      _NavItem(Icons.psychology_rounded, 'AI Hub'),
      _NavItem(Icons.admin_panel_settings_rounded, 'Admin'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final selected = i == _currentIndex;
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      color: selected ? _primaryBlue : const Color(0xFF9E9E9E),
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected
                            ? _primaryBlue
                            : const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Painter del grid del mapa ─────────────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A5DC8).withOpacity(0.12)
      ..strokeWidth = 0.8;

    // Líneas horizontales
    for (double y = 0; y < size.height; y += size.height / 10) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Líneas verticales
    for (double x = 0; x < size.width; x += size.width / 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Líneas diagonales (efecto mapa de red)
    final diagPaint = Paint()
      ..color = const Color(0xFF1A5DC8).withOpacity(0.07)
      ..strokeWidth = 0.5;
    for (double i = -size.height; i < size.width + size.height; i += 60) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        diagPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Modelos ───────────────────────────────────────────────────────────────────
class _MapNode {
  final String label;
  final double x;
  final double y;
  final bool isAlert;
  const _MapNode({
    required this.label,
    required this.x,
    required this.y,
    required this.isAlert,
  });
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem(this.icon, this.label);
}
