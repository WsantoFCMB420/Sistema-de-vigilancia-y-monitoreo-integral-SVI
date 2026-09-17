import 'package:flutter/material.dart';
import '../main.dart'; // Para AppRoutes

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});
  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  static const Color _bg       = Color(0xFFDDE8F5);
  static const Color _blue     = Color(0xFF1A5DC8);
  static const Color _card     = Colors.white;
  static const Color _label    = Color(0xFF6B7A99);
  static const Color _text     = Color(0xFF1A2340);
  static const Color _danger   = Color(0xFFE53935);
  static const Color _success  = Color(0xFF16A34A);

  int _currentIndex = 4;

  static const List<_Mod> _mods = [
    _Mod(Icons.dashboard_rounded,            'Dashboard',    AppRoutes.dashboard,     Color(0xFF1A5DC8)),
    _Mod(Icons.map_rounded,                  'Mapa',         AppRoutes.map,           Color(0xFF00897B)),
    _Mod(Icons.videocam_rounded,             'Cámaras',      AppRoutes.cameraView,    Color(0xFF6D4C41)),
    _Mod(Icons.devices_rounded,              'Dispositivos', AppRoutes.devices,       Color(0xFF5E35B1)),
    _Mod(Icons.warning_amber_rounded,        'Alertas',      AppRoutes.alerts,        Color(0xFFE53935)),
    _Mod(Icons.forum_rounded,                'Comunicación', AppRoutes.communication, Color(0xFF0288D1)),
    _Mod(Icons.psychology_rounded,           'IA Hub',       AppRoutes.iaModule,      Color(0xFF7B1FA2)),
    _Mod(Icons.assessment_rounded,           'Reportes',     AppRoutes.reportes,      Color(0xFF2E7D32)),
    _Mod(Icons.admin_panel_settings_rounded, 'Admin',        AppRoutes.admin,         Color(0xFFAD1457)),
  ];

  final List<Map<String, dynamic>> _users = [
    {'initials': 'JD', 'name': 'Javier Dominguez', 'role': 'Admin',    'active': true,  'color': Color(0xFF1A5DC8)},
    {'initials': 'ML', 'name': 'Marta López',       'role': 'Operador', 'active': true,  'color': Color(0xFF7C3AED)},
  ];

  final List<Map<String, dynamic>> _activity = [
    {'icon': Icons.login_rounded,      'iconColor': Color(0xFF1A5DC8), 'text': 'Javier Dominguez inició sesión en el Panel de Administración', 'meta': 'Hace 12 minutos  •  IP 192.168.1.45'},
    {'icon': Icons.settings_rounded,   'iconColor': Color(0xFF6B7A99), 'text': 'Configuración de Cámara Central actualizada por Marta López',   'meta': 'Hace 45 minutos  •  Operación Exitosa'},
    {'icon': Icons.person_add_rounded, 'iconColor': Color(0xFF16A34A), 'text': 'Nuevo dispositivo registrado por Admin en Zona B',               'meta': 'Hace 1 hora  •  Dispositivo: CAM-012'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _topBar(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildServerCards(),
                    const SizedBox(height: 22),
                    _buildGestionUsuarios(),
                    const SizedBox(height: 22),
                    _buildActividad(),
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

  Widget _topBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: _blue.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.arrow_back_rounded, color: _blue, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Builder(builder: (ctx) => GestureDetector(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: _blue.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.menu_rounded, color: _blue, size: 20),
            ),
          )),
          const SizedBox(width: 10),
          Container(width: 32, height: 32,
            decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18)),
          const SizedBox(width: 8),
          const Text('Panel Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _text)),
        ]),
        CircleAvatar(radius: 18, backgroundColor: _blue.withOpacity(0.15),
          child: const Icon(Icons.person_rounded, color: _blue, size: 20)),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1A5DC8), Color(0xFF0D1B2A)],
          )),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 48, height: 48,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28)),
            const SizedBox(height: 14),
            const Text('Sentinel SVI', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const Text('Sistema de Vigilancia Integral', style: TextStyle(color: Colors.white60, fontSize: 12)),
          ]),
        ),
        Expanded(child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: _mods.map((mod) {
            final isCurrent = mod.route == AppRoutes.admin;
            return ListTile(
              leading: Container(width: 38, height: 38,
                decoration: BoxDecoration(
                  color: isCurrent ? mod.color : mod.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
                child: Icon(mod.icon, color: isCurrent ? Colors.white : mod.color, size: 20)),
              title: Text(mod.label, style: TextStyle(
                fontSize: 14, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isCurrent ? _blue : _text)),
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

  Widget _buildServerCards() {
    return Column(children: [
      _serverCard(icon: Icons.dns_rounded,     label: 'ESTADO DEL SERVIDOR', name: 'Core Sentinel-01',  status: 'En línea',  statusColor: _success),
      const SizedBox(height: 10),
      _serverCard(icon: Icons.storage_rounded, label: 'BASE DE DATOS',       name: 'Surveillance-DB',   status: 'Conectado', statusColor: _success),
    ]);
  }

  Widget _serverCard({required IconData icon, required String label, required String name, required String status, required Color statusColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _blue, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _label, letterSpacing: 0.7)),
          const SizedBox(height: 3),
          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
        ])),
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
        ]),
      ]),
    );
  }

  Widget _buildGestionUsuarios() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Gestión de Usuarios', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _text)),
      const SizedBox(height: 4),
      const Text('Administra accesos, roles y permisos del sistema.', style: TextStyle(fontSize: 12, color: _label)),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showAddUserDialog,
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: const Text('Nuevo Usuario', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _blue, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        )),
      const SizedBox(height: 14),
      ..._users.asMap().entries.map((e) => _buildUserCard(e.value, e.key)).toList(),
    ]);
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        Row(children: [
          CircleAvatar(radius: 22, backgroundColor: (user['color'] as Color).withOpacity(0.15),
            child: Text(user['initials'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: user['color'] as Color))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
            const SizedBox(height: 2),
            Text(user['role'], style: const TextStyle(fontSize: 12, color: _label)),
          ])),
          GestureDetector(
            onTap: () => setState(() => _users[index]['active'] = !_users[index]['active']),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: user['active'] ? _success.withOpacity(0.12) : _danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20)),
              child: Text(user['active'] ? 'Activo' : 'Inactivo',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: user['active'] ? _success : _danger)),
            )),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          GestureDetector(onTap: () => _showManageUserDialog(user),
            child: const Text('Gestionar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _blue))),
          const SizedBox(width: 20),
          GestureDetector(onTap: () => _confirmDelete(index),
            child: const Text('Eliminar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _danger))),
        ]),
      ]),
    );
  }

  Widget _buildActividad() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Actividad Reciente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _text)),
      const SizedBox(height: 14),
      ..._activity.map((a) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: (a['iconColor'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
            child: Icon(a['icon'] as IconData, color: a['iconColor'] as Color, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a['text'], style: const TextStyle(fontSize: 12, color: _text, height: 1.4)),
            const SizedBox(height: 4),
            Text(a['meta'], style: const TextStyle(fontSize: 10, color: _label)),
          ])),
        ]),
      )).toList(),
    ]);
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Nuevo Usuario', style: TextStyle(fontWeight: FontWeight.w700, color: _text)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl,
          decoration: InputDecoration(labelText: 'Nombre completo',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 12),
        TextField(controller: roleCtrl,
          decoration: InputDecoration(labelText: 'Rol (Admin / Operador)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: _label))),
        ElevatedButton(
          onPressed: () {
            if (nameCtrl.text.isNotEmpty) {
              final parts = nameCtrl.text.trim().split(' ');
              final initials = parts.length >= 2 ? '${parts[0][0]}${parts[1][0]}'.toUpperCase() : nameCtrl.text.substring(0, 2).toUpperCase();
              setState(() => _users.add({'initials': initials, 'name': nameCtrl.text.trim(),
                'role': roleCtrl.text.isEmpty ? 'Operador' : roleCtrl.text.trim(), 'active': true, 'color': const Color(0xFF16A34A)}));
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: _blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Agregar', style: TextStyle(color: Colors.white))),
      ],
    ));
  }

  void _showManageUserDialog(Map<String, dynamic> user) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Gestionar: ${user['name']}', style: const TextStyle(fontWeight: FontWeight.w700, color: _text, fontSize: 15)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _dialogOption(Icons.swap_horiz_rounded, 'Cambiar Rol'),
        _dialogOption(Icons.lock_reset_rounded, 'Resetear Contraseña'),
        _dialogOption(Icons.history_rounded,    'Ver Historial'),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context),
        child: const Text('Cerrar', style: TextStyle(color: _label)))],
    ));
  }

  Widget _dialogOption(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: _blue, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 13, color: _text)),
      contentPadding: EdgeInsets.zero,
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label ejecutado')));
      },
    );
  }

  void _confirmDelete(int index) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Confirmar eliminación', style: TextStyle(fontWeight: FontWeight.w700, color: _text)),
      content: Text('¿Deseas eliminar a ${_users[index]['name']}?', style: const TextStyle(color: _label)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: _label))),
        ElevatedButton(
          onPressed: () {
            setState(() => _users.removeAt(index));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario eliminado')));
          },
          style: ElevatedButton.styleFrom(backgroundColor: _danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Eliminar', style: TextStyle(color: Colors.white))),
      ],
    ));
  }

  Widget _buildBottomNav() {
    final items = [
      _Nav(Icons.dashboard_rounded,            'Dashboard', AppRoutes.dashboard),
      _Nav(Icons.map_rounded,                  'Mapa',      AppRoutes.map),
      _Nav(Icons.devices_rounded,              'Devices',   AppRoutes.devices),
      _Nav(Icons.psychology_rounded,           'IA Hub',    AppRoutes.iaModule),
      _Nav(Icons.admin_panel_settings_rounded, 'Admin',     AppRoutes.admin),
    ];
    return Container(
      decoration: BoxDecoration(color: _card,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))]),
      child: SafeArea(child: SizedBox(height: 64,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((e) {
            final sel = e.key == _currentIndex;
            return GestureDetector(
              onTap: () {
                if (e.key == _currentIndex) return;
                setState(() => _currentIndex = e.key);
                Navigator.pushNamed(context, e.value.route);
              },
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(e.value.icon, color: sel ? _blue : const Color(0xFF9E9E9E), size: 24),
                const SizedBox(height: 4),
                Text(e.value.label, style: TextStyle(fontSize: 10,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                  color: sel ? _blue : const Color(0xFF9E9E9E))),
              ]),
            );
          }).toList()),
      )),
    );
  }
}

class _Mod {
  final IconData icon; final String label; final String route; final Color color;
  const _Mod(this.icon, this.label, this.route, this.color);
}

class _Nav {
  final IconData icon; final String label; final String route;
  _Nav(this.icon, this.label, this.route);
}