import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart'; // Para AppRoutes

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _currentIndex = 1;

  static const Color _bgColor = Color(0xFFDDE8F5);
  static const Color _primaryBlue = Color(0xFF1A5DC8);
  static const Color _cardColor = Colors.white;
  static const Color _labelColor = Color(0xFF6B7A99);
  static const Color _textColor = Color(0xFF1A2340);
  static const Color _dangerColor = Color(0xFFE53935);
  static const Color _successColor = Color(0xFF43A047);

  List<_MapNode> _nodes = [];
  bool _loading = true;
  String? _error;
  _MapNode? _selectedNode;

  @override
  void initState() {
    super.initState();
    _loadNodes();
  }

  Future<void> _loadNodes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rawNodes = await ApiService.getMapNodes();
      if (!mounted) return;
      setState(() {
        _nodes = rawNodes.map((n) {
          final lat = (n['lat'] as num).toDouble();
          final lng = (n['lng'] as num).toDouble();
          // Conversión ajustada para Bogotá (lat~4.71, lng~-74.07)
          final x = ((lng + 74.08) * 6).clamp(0.05, 0.95);
          final y = ((4.715 - lat) * 10 + 0.3).clamp(0.1, 0.8);
          return _MapNode(
            label: n['label'] ?? '?',
            x: x,
            y: y,
            isAlert: n['isAlert'] ?? false,
          );
        }).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar nodos: $_error'), backgroundColor: Colors.redAccent),
      );
    }
  }

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

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: _primaryBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.arrow_back_rounded, color: _primaryBlue, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: _primaryBlue, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('Mapa de Red',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textColor)),
          ],
        ),
        CircleAvatar(
          radius: 18,
          backgroundColor: _primaryBlue.withOpacity(0.15),
          child: const Icon(Icons.person_rounded, color: _primaryBlue, size: 20),
        ),
      ],
    );
  }

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
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadNodes,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _MapGridPainter(),
                        ),
                        Positioned(
                          left: constraints.maxWidth * 0.50 - 40,
                          top: constraints.maxHeight * 0.42 - 40,
                          child: Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _primaryBlue.withOpacity(0.15),
                            ),
                            child: Center(
                              child: Container(
                                width: 20, height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _primaryBlue.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ..._nodes.map((node) {
                          return Positioned(
                            left: constraints.maxWidth * node.x - 16,
                            top: constraints.maxHeight * node.y - 16,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedNode = (_selectedNode == node) ? null : node;
                                });
                              },
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
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.85),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.6), width: isSelected ? 2 : 1),
          ),
          child: Icon(node.isAlert ? Icons.warning_rounded : Icons.videocam_rounded, color: Colors.white, size: 16),
        ),
        if (isSelected) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            child: Text('CAM-${node.label}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusCard() {
    final activeCount = _nodes.where((n) => !n.isAlert).length;
    final alertCount = _nodes.where((n) => n.isAlert).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('SYSTEM STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _labelColor, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          _statusRow('Active Nodes', '$activeCount', _textColor),
          const SizedBox(height: 4),
          _statusRow('Alerts', '$alertCount CRITICAL', _dangerColor),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _labelColor, fontWeight: FontWeight.w500)),
        const SizedBox(width: 12),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }

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
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: _cardColor.withOpacity(0.92),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, color: color ?? _textColor, size: 20),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      height: 185,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 10), width: 36, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 130, height: 88, color: const Color(0xFF0D1117),
                      child: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [Color(0xFF0D1B2A), Color(0xFF1A3A5C)]),
                            ),
                            child: const Center(child: Icon(Icons.videocam_rounded, color: _primaryBlue, size: 32)),
                          ),
                          Positioned(
                            top: 6, left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(color: _dangerColor, borderRadius: BorderRadius.circular(4)),
                              child: const Row(
                                children: [
                                  Icon(Icons.circle, color: Colors.white, size: 5),
                                  SizedBox(width: 3),
                                  Text('LIVE  CAM-042', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Main Entrance Alpha', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textColor)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('NORMAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _successColor, letterSpacing: 0.5)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('North-East Perimeter • Station 4', style: TextStyle(fontSize: 11, color: _labelColor)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: 0.82, minHeight: 4, backgroundColor: const Color(0xFFE0E0E0),
                                  valueColor: const AlwaysStoppedAnimation<Color>(_primaryBlue),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('82%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _primaryBlue)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Señal', style: TextStyle(fontSize: 10, color: _labelColor)),
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

  Widget _buildBottomNav() {
    final items = [
      _NavItem(Icons.dashboard_rounded, 'Dashboard', AppRoutes.dashboard),
      _NavItem(Icons.map_rounded, 'Mapa', AppRoutes.map),
      _NavItem(Icons.videocam_rounded, 'Cámaras', AppRoutes.cameraView),
      _NavItem(Icons.psychology_rounded, 'IA Hub', AppRoutes.iaModule),
      _NavItem(Icons.admin_panel_settings_rounded, 'Admin', AppRoutes.admin),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
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
                onTap: () {
                  if (i == _currentIndex) return;
                  setState(() => _currentIndex = i);
                  Navigator.pushNamed(context, item.route);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, color: selected ? _primaryBlue : const Color(0xFF9E9E9E), size: 24),
                    const SizedBox(height: 4),
                    Text(item.label, style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? _primaryBlue : const Color(0xFF9E9E9E))),
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

// ── Painter del grid ─────────────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A5DC8).withOpacity(0.12)
      ..strokeWidth = 0.8;
    for (double y = 0; y < size.height; y += size.height / 10) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += size.width / 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    final diagPaint = Paint()
      ..color = const Color(0xFF1A5DC8).withOpacity(0.07)
      ..strokeWidth = 0.5;
    for (double i = -size.height; i < size.width + size.height; i += 60) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), diagPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Modelos ─────────────────────────────────────────────────────────────
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
  final String route;
  _NavItem(this.icon, this.label, this.route);
}
