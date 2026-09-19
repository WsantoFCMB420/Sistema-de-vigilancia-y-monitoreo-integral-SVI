import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart'; // Para AppRoutes

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.getDashboard();
      if (!mounted) return;
      setState(() {
        data = result;
        _recentAlerts = (result['recent_alerts'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $_error'), backgroundColor: Colors.redAccent),
      );
    }
  }

  static const Color _bgColor = Color(0xFFDDE8F5);
  static const Color _primaryBlue = Color(0xFF1A5DC8);
  static const Color _cardColor = Colors.white;
  static const Color _labelColor = Color(0xFF6B7A99);
  static const Color _textColor = Color(0xFF1A2340);
  static const Color _dangerColor = Color(0xFFE53935);

  List<Map<String, dynamic>> _recentAlerts = [];

  // ── Todos los módulos del sistema ─────────────────────────────────────────
  static const List<_ModuleItem> _allModules = [
    _ModuleItem(Icons.dashboard_rounded,         'Dashboard',      AppRoutes.dashboard,     Color(0xFF1A5DC8)),
    _ModuleItem(Icons.map_rounded,               'Mapa',           AppRoutes.map,           Color(0xFF00897B)),
    _ModuleItem(Icons.videocam_rounded,          'Cámaras',        AppRoutes.cameraView,    Color(0xFF6D4C41)),
    _ModuleItem(Icons.devices_rounded,           'Dispositivos',   AppRoutes.devices,       Color(0xFF5E35B1)),
    _ModuleItem(Icons.warning_amber_rounded,     'Alertas',        AppRoutes.alerts,        Color(0xFFE53935)),
    _ModuleItem(Icons.forum_rounded,             'Comunicación',   AppRoutes.communication, Color(0xFF0288D1)),
    _ModuleItem(Icons.psychology_rounded,        'IA Hub',         AppRoutes.iaModule,      Color(0xFF7B1FA2)),
    _ModuleItem(Icons.assessment_rounded,        'Reportes',       AppRoutes.reportes,      Color(0xFF2E7D32)),
    _ModuleItem(Icons.admin_panel_settings_rounded, 'Admin',       AppRoutes.admin,         Color(0xFFAD1457)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: _dangerColor),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(color: _labelColor)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: loadDashboard,
                          style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: loadDashboard,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopBar(),
                          const SizedBox(height: 20),
                          _buildStatsRow(),
                          const SizedBox(height: 24),
                          _buildModulesGrid(),
                          const SizedBox(height: 24),
                          _buildAlertsSection(),
                          const SizedBox(height: 24),
                          _buildLiveSection(),
                          const SizedBox(height: 24),
                          _buildMapSection(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
      ),
      floatingActionButton: _buildEmitAlertButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Builder(
              builder: (ctx) => GestureDetector(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: _primaryBlue, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Sentinel Surveillance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textColor)),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: _dangerColor),
              onPressed: () async {
                await ApiService.logout();
                await SessionService.logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
              },
            ),
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
    );
  }

  // ── Drawer – todos los módulos ────────────────────────────────────────────
  // helper para icono por tipo de alerta
  IconData _alertIcon(String type) {
    switch (type.toLowerCase()) {
      case 'seguridad':  return Icons.shield_rounded;
      case 'incendio':   return Icons.local_fire_department_rounded;
      case 'médico':     return Icons.medical_services_rounded;
      case 'técnico':    return Icons.engineering_rounded;
      default:           return Icons.warning_amber_rounded;
    }
  }

  Widget _buildDrawer() {
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
              children: _allModules.map((mod) {
                final isCurrent = mod.route == AppRoutes.dashboard;
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
                      color: isCurrent ? _primaryBlue : _textColor,
                    ),
                  ),
                  trailing: isCurrent
                      ? Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(color: _primaryBlue, shape: BoxShape.circle),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context); // cierra drawer
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
            leading: const Icon(Icons.logout_rounded, color: _dangerColor),
            title: const Text('Cerrar sesión', style: TextStyle(color: _dangerColor, fontWeight: FontWeight.w600)),
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

  // ── Stats ────────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    if (data == null) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'CÁMARAS ONLINE',
            value: data!['active_devices'].toString(),
            dotColor: const Color(0xFF43A047),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'DESCONECTADOS',
            value: data!['inactive_devices'].toString(),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _labelColor, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: _textColor)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Grid de todos los módulos ─────────────────────────────────────────────
  Widget _buildModulesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Acceso Rápido',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textColor)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: _allModules.length,
          itemBuilder: (context, index) {
            final mod = _allModules[index];
            final isCurrent = mod.route == AppRoutes.dashboard;
            return GestureDetector(
              onTap: () {
                if (!isCurrent) Navigator.pushNamed(context, mod.route);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isCurrent ? mod.color : _cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCurrent ? mod.color : const Color(0xFFE4EAF5),
                    width: isCurrent ? 0 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isCurrent ? Colors.white.withValues(alpha: 0.2) : mod.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(mod.icon, color: isCurrent ? Colors.white : mod.color, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mod.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isCurrent ? Colors.white : _textColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Alertas ───────────────────────────────────────────────────────────────
  Widget _buildAlertsSection() {
    final criticalCount = data?['critical_alerts'] ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Alertas Recientes',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textColor)),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.alerts),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: criticalCount > 0 ? const Color(0xFFFDECEC) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  criticalCount > 0 ? '$criticalCount CRÍTICAS' : 'Ver todas',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: criticalCount > 0 ? _dangerColor : const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentAlerts.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardColor, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: const Row(children: [
              Icon(Icons.check_circle_outline_rounded, color: Color(0xFF43A047), size: 22),
              SizedBox(width: 10),
              Text('Sin alertas recientes', style: TextStyle(color: Color(0xFF43A047), fontWeight: FontWeight.w600)),
            ]),
          )
        else
          ..._recentAlerts.take(3).map((alert) => _buildApiAlertCard(alert)),
      ],
    );
  }

  Widget _buildApiAlertCard(Map<String, dynamic> alert) {
    final priority = alert['priority'] ?? 'Media';
    final isDanger = priority == 'Crítica';
    final cardBg   = isDanger ? const Color(0xFFFDECEC) : _cardColor;
    final cardBorder = isDanger ? const Color(0xFFFFCDD2) : const Color(0xFFE4EAF5);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: isDanger ? const Color(0xFFFDECEC) : _primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_alertIcon(alert['type'] ?? ''),
              color: isDanger ? _dangerColor : _primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${alert['type']} • ${alert['priority']}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textColor)),
            const SizedBox(height: 3),
            Text(
              '${alert['location']?.isNotEmpty == true ? alert['location'] : 'Sin ubicación'} • ${alert['created_at']}',
              style: const TextStyle(fontSize: 11, color: _labelColor),
            ),
          ],
        )),
        const Icon(Icons.chevron_right_rounded, color: _labelColor, size: 20),
      ]),
    );
  }



  // ── Vigilancia en Vivo ────────────────────────────────────────────────────
  Widget _buildLiveSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Vigilancia en Vivo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textColor)),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.cameraView),
              child: Text('Ver todas →',
                  style: TextStyle(fontSize: 12, color: _primaryBlue, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.cameraView),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
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
                      child: Icon(Icons.videocam_rounded, color: _primaryBlue, size: 48),
                    ),
                  ),
                ),
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _dangerColor, borderRadius: BorderRadius.circular(6)),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 6),
                        SizedBox(width: 4),
                        Text('REC  SECTOR A1',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12, right: 12,
                  child: Row(
                    children: [
                      _liveChip(Icons.visibility_rounded, '4 cámaras'),
                      const SizedBox(width: 6),
                      _liveChip(Icons.hd_rounded, 'HD'),
                    ],
                  ),
                ),
                const Positioned.fill(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 20),
                        Icon(Icons.play_circle_outline_rounded, color: Colors.white54, size: 40),
                        SizedBox(height: 6),
                        Text('Toca para ver en vivo',
                            style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _liveChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Mapa + IA ──────────────────────────────────────────────────────────────
  Widget _buildMapSection() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.map),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.map_rounded, color: Color(0xFF81C784), size: 40)),
                  Positioned(
                    top: 30, left: 50,
                    child: Container(
                      width: 12, height: 12,
                      decoration: const BoxDecoration(color: _dangerColor, shape: BoxShape.circle),
                    ),
                  ),
                  Positioned(
                    bottom: 10, left: 0, right: 0,
                    child: Center(
                      child: Text('Ver Mapa',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.iaModule),
            child: Container(
              height: 120,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.psychology_rounded, color: _primaryBlue, size: 28),
                  SizedBox(height: 6),
                  Text('98%',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _primaryBlue)),
                  Text('IA CONFIANZA',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _labelColor, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── FAB Emitir Alerta ──────────────────────────────────────────────────────
  Widget _buildEmitAlertButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: ElevatedButton.icon(
        onPressed: _showAlertDialog,
        icon: const Icon(Icons.campaign_rounded, size: 20),
        label: const Text('EMITIR ALERTA',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _dangerColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: _dangerColor.withValues(alpha: 0.4),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  void _showAlertDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Emitir Alerta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textColor)),
            const SizedBox(height: 16),
            _alertTypeButton(Icons.warning_amber_rounded, 'Intrusión', _dangerColor),
            const SizedBox(height: 8),
            _alertTypeButton(Icons.local_fire_department_rounded, 'Emergencia', const Color(0xFFFF6D00)),
            const SizedBox(height: 8),
            _alertTypeButton(Icons.info_rounded, 'Aviso General', _primaryBlue),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _alertTypeButton(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        try {
          await ApiService.sendAlert(type: label, priority: 'Crítica');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Alerta de $label emitida'), backgroundColor: _primaryBlue),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al emitir alerta'), backgroundColor: _dangerColor),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Modelos ───────────────────────────────────────────────────────────────────

class _ModuleItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _ModuleItem(this.icon, this.label, this.route, this.color);
}