import 'package:flutter/material.dart';

import '../main.dart'; // AppRoutes, SessionService
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/responsive.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? data;
  bool _loading = true;
  String? _error;
  String _userRole = 'viewer';
  String _userName = '';
  List<Map<String, dynamic>> _recentAlerts = [];

  AppColors get _c => AppColors.of(context);
  bool get _isViewer => _userRole == 'viewer';

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() {
      _loading = data == null;
      _error = null;
    });
    try {
      final role = await SessionService.getUserRole();
      final name = await SessionService.getUserName();
      final result = await ApiService.getDashboard();
      if (!mounted) return;
      setState(() {
        _userRole = role;
        _userName = name;
        data = result;
        _recentAlerts = (result['recent_alerts'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } on SessionExpiredException {
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String get _greeting {
    // Hora de Bogotá (UTC-5) sin depender de la zona del equipo.
    final h = DateTime.now().toUtc().subtract(const Duration(hours: 5)).hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String get _firstName {
    final parts = _userName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? '' : parts.first;
  }

  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    final pad = wide ? 28.0 : 16.0;

    return Scaffold(
      backgroundColor: _c.bg,
      drawer: const AppDrawer(currentRoute: AppRoutes.dashboard),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 14, pad, 8),
              child: ResponsiveShell(
                child: AppTopBar(
                  title: _firstName.isEmpty ? 'Panel de control' : '$_greeting, $_firstName',
                  subtitle: 'Resumen del sistema de vigilancia',
                  icon: Icons.space_dashboard_rounded,
                ),
              ),
            ),
            Expanded(child: _buildBody(pad, wide)),
          ],
        ),
      ),
      floatingActionButton: (_isViewer || _loading) ? null : _buildEmitAlertButton(wide),
      floatingActionButtonLocation:
          wide ? FloatingActionButtonLocation.endFloat : FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBody(double pad, bool wide) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text('No se pudo cargar el panel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _c.text)),
              const SizedBox(height: 6),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: _c.label)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: loadDashboard,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final mainColumn = <Widget>[
      _buildStatsGrid(wide),
      const SizedBox(height: 26),
      SectionTitle('Acceso rápido'),
      const SizedBox(height: 12),
      _buildModulesGrid(),
    ];

    final alertsColumn = <Widget>[
      _buildAlertsSection(),
    ];

    final sideColumn = <Widget>[
      if (!_isViewer) ...[
        _buildLiveSection(),
        const SizedBox(height: 18),
      ],
      _buildMapCard(),
    ];

    return RefreshIndicator(
      onRefresh: loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(pad, 8, pad, _isViewer ? 32 : 110),
        child: ResponsiveShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...mainColumn,
              const SizedBox(height: 26),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: Column(children: alertsColumn)),
                    const SizedBox(width: 22),
                    Expanded(flex: 2, child: Column(children: sideColumn)),
                  ],
                )
              else ...[
                ...alertsColumn,
                const SizedBox(height: 22),
                ...sideColumn,
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── KPIs ──────────────────────────────────────────────────────────────
  Widget _buildStatsGrid(bool wide) {
    final d = data ?? const {};
    int n(String k) => (d[k] is num) ? (d[k] as num).toInt() : int.tryParse('${d[k]}') ?? 0;

    final cards = [
      _StatCard(
        label: 'Dispositivos activos',
        value: n('active_devices'),
        icon: Icons.videocam_rounded,
        color: AppColors.success,
        hint: 'de ${n('total_devices')} registrados',
      ),
      _StatCard(
        label: 'Desconectados',
        value: n('inactive_devices'),
        icon: Icons.videocam_off_rounded,
        color: const Color(0xFF8A94A6),
        hint: 'inactivos o en mantenimiento',
      ),
      _StatCard(
        label: 'Alertas activas',
        value: n('total_alerts'),
        icon: Icons.notifications_active_rounded,
        color: AppColors.warning,
        hint: 'pendientes o en atención',
      ),
      _StatCard(
        label: 'Críticas',
        value: n('critical_alerts'),
        icon: Icons.priority_high_rounded,
        color: AppColors.danger,
        hint: 'requieren respuesta',
      ),
    ];

    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 900 ? 4 : 2;
        const spacing = 12.0;
        final itemWidth = (box.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final c in cards) SizedBox(width: itemWidth, child: c)],
        );
      },
    );
  }

  // ── Módulos ───────────────────────────────────────────────────────────
  Widget _buildModulesGrid() {
    final modules = AppModules.visibleFor(_userRole)
        .where((m) => m.route != AppRoutes.dashboard)
        .toList();
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final columns = w >= 1100 ? 8 : (w >= 700 ? 4 : 3);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemCount: modules.length,
          itemBuilder: (context, i) => ModuleTile(
            module: modules[i],
            onTap: () => Navigator.pushNamed(context, modules[i].route),
          ),
        );
      },
    );
  }

  // ── Alertas recientes ─────────────────────────────────────────────────
  Widget _buildAlertsSection() {
    final critical = (data?['critical_alerts'] is num) ? (data!['critical_alerts'] as num).toInt() : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          'Alertas recientes',
          trailing: TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.alerts),
            icon: Icon(
              critical > 0 ? Icons.priority_high_rounded : Icons.arrow_forward_rounded,
              size: 16,
              color: critical > 0 ? AppColors.danger : AppColors.primary,
            ),
            label: Text(
              critical > 0 ? '$critical críticas' : 'Ver todas',
              style: TextStyle(color: critical > 0 ? AppColors.danger : AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_recentAlerts.isEmpty)
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: _c.tint(AppColors.success), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.verified_user_rounded, color: AppColors.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Todo en orden',
                          style: TextStyle(fontWeight: FontWeight.w700, color: _c.text)),
                      Text('No hay alertas activas en este momento.',
                          style: TextStyle(fontSize: 12, color: _c.label)),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (var i = 0; i < _recentAlerts.length && i < 5; i++) ...[
                  if (i > 0) Divider(height: 1, indent: 66, color: _c.border),
                  _buildAlertRow(_recentAlerts[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAlertRow(Map<String, dynamic> alert) {
    final priority = (alert['priority'] ?? 'Media').toString();
    final status = (alert['status'] ?? 'Pendiente').toString();
    final color = priority == 'Crítica'
        ? AppColors.danger
        : (priority == 'Baja' ? AppColors.success : AppColors.warning);
    final location = (alert['location'] ?? '').toString();
    final description = (alert['description'] ?? '').toString();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      onTap: () => Navigator.pushNamed(context, AppRoutes.alerts),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: _c.tint(color), borderRadius: BorderRadius.circular(12)),
        child: Icon(_alertIcon((alert['type'] ?? '').toString()), color: color, size: 20),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text('${alert['type'] ?? 'Alerta'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _c.text)),
          ),
          const SizedBox(width: 8),
          _miniPill(priority, color),
        ],
      ),
      subtitle: Text(
        [
          if (description.isNotEmpty) description else if (location.isNotEmpty) location else 'Sin ubicación',
          status,
          '${alert['created_at'] ?? ''}',
        ].where((s) => s.isNotEmpty).join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: _c.label),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: _c.hint),
    );
  }

  Widget _miniPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }

  IconData _alertIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('incendio')) return Icons.local_fire_department_rounded;
    if (t.contains('médic') || t.contains('medic')) return Icons.medical_services_rounded;
    if (t.contains('técnic') || t.contains('tecnic')) return Icons.engineering_rounded;
    if (t.contains('intrus') || t.contains('robo') || t.contains('seguridad')) return Icons.shield_rounded;
    return Icons.warning_amber_rounded;
  }

  // ── Cámaras (solo admin y operador) ───────────────────────────────────
  Widget _buildLiveSection() {
    final online = (data?['active_devices'] is num) ? (data!['active_devices'] as num).toInt() : 0;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.pushNamed(context, AppRoutes.cameraView),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 170,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B1F44), Color(0xFF1A5DC8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(6)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 7),
                        SizedBox(width: 5),
                        Text('EN VIVO',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.open_in_new_rounded, color: Colors.white70, size: 18),
                ],
              ),
              const Spacer(),
              const Text('Vigilancia en vivo',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                online == 1 ? '1 cámara en línea' : '$online cámaras en línea',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapCard() {
    return AppCard(
      onTap: () => Navigator.pushNamed(context, AppRoutes.map),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: _c.tint(const Color(0xFF00897B)), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.map_rounded, color: Color(0xFF00897B), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mapa de red', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _c.text)),
                const SizedBox(height: 2),
                Text('Ubica tus cámaras y las alertas cercanas',
                    style: TextStyle(fontSize: 12, color: _c.label)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: _c.hint),
        ],
      ),
    );
  }

  // ── Emitir alerta (solo admin y operador) ─────────────────────────────
  Widget _buildEmitAlertButton(bool wide) {
    final button = FloatingActionButton.extended(
      heroTag: 'emit-alert',
      onPressed: _showAlertDialog,
      backgroundColor: AppColors.danger,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.campaign_rounded),
      label: const Text('EMITIR ALERTA', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
    return button;
  }

  void _showAlertDialog() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (sheetCtx) {
        final c = AppColors.of(sheetCtx);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Emitir alerta rápida', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text)),
              const SizedBox(height: 4),
              Text('Se publica con prioridad crítica. Para más detalle usa el módulo de Alertas.',
                  style: TextStyle(fontSize: 12, color: c.label)),
              const SizedBox(height: 16),
              _alertTypeButton(sheetCtx, Icons.warning_amber_rounded, 'Intrusión', AppColors.danger),
              const SizedBox(height: 8),
              _alertTypeButton(sheetCtx, Icons.local_fire_department_rounded, 'Emergencia', const Color(0xFFFF6D00)),
              const SizedBox(height: 8),
              _alertTypeButton(sheetCtx, Icons.info_rounded, 'Aviso General', AppColors.primary),
            ],
          ),
        );
      },
    );
  }

  Widget _alertTypeButton(BuildContext sheetCtx, IconData icon, String label, Color color) {
    final c = AppColors.of(sheetCtx);
    return Material(
      color: c.tint(color),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          Navigator.pop(sheetCtx);
          try {
            await ApiService.sendAlert(type: label, priority: 'Crítica');
            if (!mounted) return;
            showAppSnackBar(context, 'Alerta de $label emitida', icon: Icons.check_circle_rounded);
            loadDashboard();
          } catch (e) {
            if (!mounted) return;
            showAppSnackBar(context, 'Error al emitir alerta', backgroundColor: AppColors.danger);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
              ),
              Icon(Icons.send_rounded, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final String hint;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: c.tint(color), borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: c.text, height: 1.1)),
                const SizedBox(height: 2),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.text)),
                Text(hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: c.label)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
