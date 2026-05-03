import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  void loadDashboard() async {
    final result = await ApiService.getDashboard();
    setState(() {
      data = result;
    });
  }

  static const Color _bgColor = Color(0xFFDDE8F5);
  static const Color _primaryBlue = Color(0xFF1A5DC8);
  static const Color _cardColor = Colors.white;
  static const Color _labelColor = Color(0xFF6B7A99);
  static const Color _textColor = Color(0xFF1A2340);
  static const Color _dangerColor = Color(0xFFE53935);

  final List<_AlertItem> _alerts = [
    _AlertItem(
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFE53935),
      bgColor: Color(0xFFFDECEC),
      title: 'Intrusión detectada - Sector A',
      subtitle: 'Zona perimetral Norte • Hace 2 min',
    ),
    _AlertItem(
      icon: Icons.visibility_rounded,
      color: Color(0xFFE53935),
      bgColor: Color(0xFFFDECEC),
      title: 'Movimiento Inusual',
      subtitle: 'Pasillo Central Bloque B • Hace 5 min',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 24),
              _buildAlertsSection(),
              const SizedBox(height: 24),
              _buildLiveSection(),
              const SizedBox(height: 24),
              _buildMapSection(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildEmitAlertButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

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
                color: Color(0xFF1A2340),
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Color(0xFF1A2340)),
              onPressed: () {},
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: _primaryBlue.withOpacity(0.15),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF1A5DC8),
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'CÁMARAS ONLINE',
            value: data == null ? '...' : data!['active_devices'].toString(),
            dotColor: const Color(0xFF43A047),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'DESCONECTADOS',
            value: data == null ? '...' : data!['inactive_devices'].toString(),
            dotColor: const Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7A99),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2340),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Alertas Activas',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2340),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '3 CRÍTICAS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE53935),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._alerts.map((alert) => _buildAlertCard(alert)).toList(),
      ],
    );
  }

  Widget _buildAlertCard(_AlertItem alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCDD2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: alert.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(alert.icon, color: alert.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2340),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  alert.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7A99),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF6B7A99),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vigilancia en Vivo',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A2340),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
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
                      color: Color(0xFF1A5DC8),
                      size: 48,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 6),
                      SizedBox(width: 4),
                      Text(
                        'REC  SECTOR A1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Row(
                  children: [
                    _liveChip(Icons.visibility_rounded, '4 cámaras'),
                    const SizedBox(width: 6),
                    _liveChip(Icons.hd_rounded, 'HD'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _liveChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.map_rounded,
                    color: Color(0xFF81C784),
                    size: 40,
                  ),
                ),
                Positioned(
                  top: 30,
                  left: 50,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.psychology_rounded,
                  color: Color(0xFF1A5DC8),
                  size: 28,
                ),
                const SizedBox(height: 6),
                const Text(
                  '98%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A5DC8),
                  ),
                ),
                const Text(
                  'CONFIANZA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7A99),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmitAlertButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: ElevatedButton.icon(
        onPressed: () {
          _showAlertDialog();
        },
        icon: const Icon(Icons.campaign_rounded, size: 20),
        label: const Text(
          'EMITIR ALERTA',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53935),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0xFFE53935).withOpacity(0.4),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  void _showAlertDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emitir Alerta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2340),
              ),
            ),
            const SizedBox(height: 16),
            _alertTypeButton(
              Icons.warning_amber_rounded,
              'Intrusión',
              Color(0xFFE53935),
            ),
            const SizedBox(height: 8),
            _alertTypeButton(
              Icons.local_fire_department_rounded,
              'Emergencia',
              Color(0xFFFF6D00),
            ),
            const SizedBox(height: 8),
            _alertTypeButton(
              Icons.info_rounded,
              'Aviso General',
              Color(0xFF1A5DC8),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _alertTypeButton(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                      color: selected
                          ? const Color(0xFF1A5DC8)
                          : const Color(0xFF9E9E9E),
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
                            ? const Color(0xFF1A5DC8)
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

class _AlertItem {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String subtitle;

  _AlertItem({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.subtitle,
  });
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem(this.icon, this.label);
}
