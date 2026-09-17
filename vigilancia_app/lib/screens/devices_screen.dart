import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/device_card.dart';
import '../main.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});
  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  List<dynamic> _devices = [];
  bool _loading = true;
  String? _error;

  static const Color _bgColor     = Color(0xFFDDE8F5);
  static const Color _primaryBlue = Color(0xFF1A5DC8);
  static const Color _cardColor   = Colors.white;
  static const Color _labelColor  = Color(0xFF6B7A99);
  static const Color _textColor   = Color(0xFF1A2340);
  static const Color _dangerColor = Color(0xFFE53935);

  static const List<_ModuleItem> _allModules = [
    _ModuleItem(Icons.dashboard_rounded,            'Dashboard',    AppRoutes.dashboard,     Color(0xFF1A5DC8)),
    _ModuleItem(Icons.map_rounded,                  'Mapa',         AppRoutes.map,           Color(0xFF00897B)),
    _ModuleItem(Icons.videocam_rounded,             'Cámaras',      AppRoutes.cameraView,    Color(0xFF6D4C41)),
    _ModuleItem(Icons.devices_rounded,              'Dispositivos', AppRoutes.devices,       Color(0xFF5E35B1)),
    _ModuleItem(Icons.warning_amber_rounded,        'Alertas',      AppRoutes.alerts,        Color(0xFFE53935)),
    _ModuleItem(Icons.forum_rounded,                'Comunicación', AppRoutes.communication, Color(0xFF0288D1)),
    _ModuleItem(Icons.psychology_rounded,           'IA Hub',       AppRoutes.iaModule,      Color(0xFF7B1FA2)),
    _ModuleItem(Icons.assessment_rounded,           'Reportes',     AppRoutes.reportes,      Color(0xFF2E7D32)),
    _ModuleItem(Icons.admin_panel_settings_rounded, 'Admin',        AppRoutes.admin,         Color(0xFFAD1457)),
  ];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() { _loading = true; _error = null; });
    try {
      final devices = await ApiService.getDevices();
      if (!mounted) return;
      setState(() { _devices = devices; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Agregar dispositivo ────────────────────────────────────────
  void _showAddDeviceDialog() {
    final titleCtrl    = TextEditingController();
    final subtitleCtrl = TextEditingController();
    String selectedStatus = 'Activo';
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            24, 20, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.devices_rounded, color: _primaryBlue, size: 20),
                ),
                const SizedBox(width: 10),
                const Text('Nuevo Dispositivo',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textColor)),
              ]),
              const SizedBox(height: 20),

              // Nombre
              const Text('NOMBRE DEL DISPOSITIVO',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: _labelColor, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(fontSize: 14, color: _textColor),
                decoration: _inputDeco('Ej: Cámara Entrada Norte'),
              ),
              const SizedBox(height: 16),

              // Descripción
              const Text('DESCRIPCIÓN / UBICACIÓN',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: _labelColor, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              TextField(
                controller: subtitleCtrl,
                style: const TextStyle(fontSize: 14, color: _textColor),
                decoration: _inputDeco('Ej: Sector A, Pasillo 2'),
              ),
              const SizedBox(height: 16),

              // Estado
              const Text('ESTADO INICIAL',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: _labelColor, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD0DAEA)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButton<String>(
                  value: selectedStatus,
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 14, color: _textColor),
                  items: ['Activo', 'Inactivo', 'Mantenimiento']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setSheet(() => selectedStatus = v!),
                ),
              ),
              const SizedBox(height: 24),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : () async {
                    final name = titleCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ingresa un nombre para el dispositivo')),
                      );
                      return;
                    }
                    setSheet(() => saving = true);
                    try {
                      await ApiService.addDevice(
                        title: name,
                        subtitle: subtitleCtrl.text.trim(),
                        status: selectedStatus,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _loadDevices();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dispositivo agregado correctamente'),
                          backgroundColor: Color(0xFF1A5DC8),
                        ),
                      );
                    } catch (e) {
                      setSheet(() => saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                      );
                    }
                  },
                  icon: saving
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(saving ? 'Guardando...' : 'Guardar Dispositivo',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFADB8CC), fontSize: 14),
    filled: true,
    fillColor: const Color(0xFFEEF4FF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD0DAEA))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD0DAEA))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryBlue, width: 1.5)),
  );

  // ── Eliminar dispositivo ───────────────────────────────────────
  Future<void> _deleteDevice(dynamic device) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar dispositivo',
            style: TextStyle(fontWeight: FontWeight.w700, color: _textColor)),
        content: Text('¿Eliminar "${device['title']}"? Esta acción no se puede deshacer.',
            style: const TextStyle(color: _labelColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: _labelColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _dangerColor, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deleteDevice(device['id']);
      _loadDevices();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dispositivo eliminado'), backgroundColor: Color(0xFF1A5DC8)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildTopBar(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildHeader(),
            ),
            const SizedBox(height: 12),
            Expanded(
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
                                onPressed: _loadDevices,
                                style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : _devices.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadDevices,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _devices.length,
                                itemBuilder: (ctx, i) {
                                  final d = _devices[i];
                                  return Dismissible(
                                    key: Key('device_${d['id']}'),
                                    direction: DismissDirection.endToStart,
                                    onDismissed: (_) => _deleteDevice(d),
                                    confirmDismiss: (_) async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16)),
                                          title: const Text('¿Eliminar dispositivo?',
                                              style: TextStyle(fontWeight: FontWeight.w700)),
                                          content: Text('Se eliminará "${d['title']}" permanentemente.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancelar'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: _dangerColor,
                                                  foregroundColor: Colors.white),
                                              child: const Text('Eliminar'),
                                            ),
                                          ],
                                        ),
                                      );
                                      return confirm ?? false;
                                    },
                                    background: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: _dangerColor,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.delete_outline_rounded,
                                              color: Colors.white, size: 26),
                                          SizedBox(height: 4),
                                          Text('Eliminar',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    child: DeviceCard(
                                      title:    d['title']    ?? '',
                                      subtitle: d['subtitle'] ?? '',
                                      status:   d['status']   ?? 'Activo',
                                      imageUrl: d['imageUrl'] ?? '',
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _primaryBlue.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.devices_rounded, color: _primaryBlue, size: 38),
          ),
          const SizedBox(height: 16),
          const Text('Sin dispositivos registrados',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textColor)),
          const SizedBox(height: 8),
          const Text('Toca el botón + para agregar tu primer dispositivo',
              style: TextStyle(fontSize: 13, color: _labelColor),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddDeviceDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Agregar Dispositivo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
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
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: _primaryBlue, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            Builder(
              builder: (ctx) => GestureDetector(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _primaryBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.menu_rounded, color: _primaryBlue, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: _primaryBlue, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('Dispositivos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textColor)),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: _primaryBlue.withOpacity(0.15),
            child: const Icon(Icons.person_rounded, color: _primaryBlue, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SISTEMAS ACTIVOS',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: _labelColor, letterSpacing: 1.0)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('Mis Dispositivos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textColor)),
                if (_devices.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _primaryBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${_devices.length}',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: _showAddDeviceDialog,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _primaryBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
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
                    color: Colors.white.withOpacity(0.15),
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
                final isCurrent = mod.route == AppRoutes.devices;
                return ListTile(
                  leading: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: isCurrent ? mod.color : mod.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(mod.icon, color: isCurrent ? Colors.white : mod.color, size: 20),
                  ),
                  title: Text(mod.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrent ? _primaryBlue : _textColor,
                      )),
                  trailing: isCurrent
                      ? Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(color: _primaryBlue, shape: BoxShape.circle))
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (!isCurrent) Navigator.pushNamed(context, mod.route);
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: _dangerColor),
            title: const Text('Cerrar sesión',
                style: TextStyle(color: _dangerColor, fontWeight: FontWeight.w600)),
            onTap: () async {
              Navigator.pop(context);
              await ApiService.logout();
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
}

class _ModuleItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _ModuleItem(this.icon, this.label, this.route, this.color);
}