import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/app_shell.dart';
import '../services/api_service.dart';
import '../widgets/responsive.dart';
import '../theme/app_colors.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});
  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  AppColors get _c => AppColors.of(context);
  Color get _bg => _c.bg;
  Color get _card => _c.card;
  Color get _text => _c.text;
  Color get _label => _c.label;
  Color get _input => _c.input;
  Color get _border => _c.border;

  static const Color _blue = Color(0xFF1A5DC8);
  static const Color _danger = Color(0xFFE53935);
  static const Color _success = Color(0xFF16A34A);
  static const Color _warn = Color(0xFFF59E0B);

  List<Map<String, dynamic>> _users = [];
  bool _loadingUsers = true;
  String? _usersError;
  bool _isAdmin = false;
  bool _checkingAdmin = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final role = await SessionService.getUserRole();
    _isAdmin = role == 'admin';
    setState(() {
      _checkingAdmin = false;
    });
    if (_isAdmin) {
      await _loadUsers();
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loadingUsers = true;
      _usersError = null;
    });
    try {
      final users = await ApiService.getUsers();
      setState(() {
        _users = List<Map<String, dynamic>>.from(users);
        _loadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _usersError = e.toString().replaceFirst('Exception: ', '');
        _loadingUsers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAdmin) {
      return Scaffold(
        backgroundColor: _bg,
        body: const Center(
            child: CircularProgressIndicator(color: Color(0xFF1A5DC8))),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded,
                      size: 64, color: Color(0xFFE53935)),
                  const SizedBox(height: 16),
                  Text(
                    'Acceso Denegado (Solo Administradores)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _text),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No tienes permisos para ver el panel de administración.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: _label),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, AppRoutes.dashboard),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A5DC8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Volver al Dashboard',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: ResponsiveShell(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() => const AppTopBar(
        title: 'Panel de administración',
        subtitle: 'Usuarios, roles y estado del servidor',
        icon: Icons.admin_panel_settings_rounded,
      );

  Widget _buildDrawer() => const AppDrawer(currentRoute: AppRoutes.admin);

  Widget _buildServerCards() {
    return Column(children: [
      _serverCard(
          icon: Icons.dns_rounded,
          label: 'SERVIDOR PRINCIPAL',
          name: 'Core Sentinel-01',
          status: 'En línea',
          statusColor: _success),
      const SizedBox(height: 10),
      _serverCard(
          icon: Icons.storage_rounded,
          label: 'BASE DE DATOS',
          name: 'Surveillance-DB',
          status: 'Conectado',
          statusColor: _success),
      const SizedBox(height: 10),
      _serverCard(
          icon: Icons.people_rounded,
          label: 'USUARIOS ACTIVOS',
          name: '${_users.length} registrados',
          status: _isAdmin ? 'Admin' : 'Operador',
          statusColor: _isAdmin ? _blue : _warn),
    ]);
  }

  Widget _serverCard(
      {required IconData icon,
      required String label,
      required String name,
      required String status,
      required Color statusColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _blue, size: 20)),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _label,
                  letterSpacing: 0.7)),
          const SizedBox(height: 3),
          Text(name,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
        ])),
        Row(children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: statusColor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(status,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor)),
        ]),
      ]),
    );
  }

  Widget _buildGestionUsuarios() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Gestión de Usuarios',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: _text)),
          GestureDetector(
            onTap: _loadUsers,
            child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: _blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9)),
                child: Icon(Icons.refresh_rounded, color: _blue, size: 18)),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text('Administra accesos, roles y permisos del sistema.',
          style: TextStyle(fontSize: 12, color: _label)),
      const SizedBox(height: 14),

      // ── Contenido condicional ─────────────────────────────────
      if (_loadingUsers)
        const Center(
            child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: _blue),
        ))
      else if (_usersError != null)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: _danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _danger.withValues(alpha: 0.2))),
          child: Row(children: [
            Icon(Icons.error_outline_rounded, color: _danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(_usersError!,
                    style: const TextStyle(fontSize: 13, color: _danger))),
          ]),
        )
      else
        ..._users.asMap().entries.map((e) => _buildUserCard(e.value, e.key)),
    ]);
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'admin':
        return _blue;
      case 'operator':
        return _warn;
      default:
        return _label;
    }
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'operator':
        return 'Operador';
      default:
        return 'Visitante';
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(1, 2)).toUpperCase();
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    final roleColor = _roleColor(user['role']);
    final roleLabel = _roleLabel(user['role']);
    final initials = _initials(user['name'] ?? '?');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Column(children: [
        Row(children: [
          CircleAvatar(
              radius: 22,
              backgroundColor: roleColor.withValues(alpha: 0.15),
              child: Text(initials,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: roleColor))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(user['name'] ?? '',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _text)),
                const SizedBox(height: 2),
                Text(user['email'] ?? '',
                    style: TextStyle(fontSize: 11, color: _label)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(roleLabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: roleColor)),
          ),
        ]),
        const SizedBox(height: 10),
        Divider(height: 1, color: _border),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(user['created_at'] ?? '',
              style: TextStyle(fontSize: 10, color: _label)),
          Row(children: [
            if (_isAdmin) ...[
              GestureDetector(
                  onTap: () => _showChangeRoleDialog(user, index),
                  child: const Text('Cambiar rol',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _blue))),
              const SizedBox(width: 18),
              GestureDetector(
                  onTap: () => _confirmDelete(user, index),
                  child: const Text('Eliminar',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _danger))),
            ] else
              Text('Sin permisos',
                  style: TextStyle(fontSize: 11, color: _label)),
          ]),
        ]),
      ]),
    );
  }

  void _showChangeRoleDialog(Map<String, dynamic> user, int index) {
    String selectedRole = user['role'] ?? 'viewer';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
                backgroundColor: _card,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Text('Rol de ${user['name']}',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _text,
                        fontSize: 15)),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  _roleOption(
                      ctx,
                      setS,
                      'admin',
                      'Administrador',
                      Icons.admin_panel_settings_rounded,
                      _blue,
                      selectedRole,
                      (v) => selectedRole = v),
                  _roleOption(
                      ctx,
                      setS,
                      'operator',
                      'Operador',
                      Icons.work_rounded,
                      _warn,
                      selectedRole,
                      (v) => selectedRole = v),
                  _roleOption(
                      ctx,
                      setS,
                      'viewer',
                      'Visitante',
                      Icons.visibility_rounded,
                      _label,
                      selectedRole,
                      (v) => selectedRole = v),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancelar', style: TextStyle(color: _label))),
                  ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _changeUserRole(user, index, selectedRole);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      child: const Text('Confirmar',
                          style: TextStyle(color: Colors.white))),
                ],
              )),
    );
  }

  Widget _roleOption(
      BuildContext ctx,
      StateSetter setS,
      String value,
      String label,
      IconData icon,
      Color color,
      String selected,
      ValueChanged<String> onChanged) {
    final isSel = selected == value;
    return GestureDetector(
      onTap: () => setS(() => onChanged(value)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: isSel ? color.withValues(alpha: 0.1) : _input,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSel ? color : _border, width: 1.5)),
        child: Row(children: [
          Icon(icon, color: isSel ? color : _label, size: 20),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? color : _text)),
          const Spacer(),
          if (isSel) Icon(Icons.check_circle_rounded, color: color, size: 18),
        ]),
      ),
    );
  }

  Future<void> _changeUserRole(
      Map<String, dynamic> user, int index, String newRole) async {
    try {
      await ApiService.updateUserRole(user['id'], newRole);
      setState(() => _users[index]['role'] = newRole);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Rol de ${user['name']} actualizado a ${_roleLabel(newRole)}'),
        backgroundColor: _blue,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: _danger,
      ));
    }
  }

  void _confirmDelete(Map<String, dynamic> user, int index) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: _card,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text('Confirmar eliminación',
                  style: TextStyle(fontWeight: FontWeight.w700, color: _text)),
              content: Text(
                  '¿Deseas eliminar a ${user['name']}? Esta acción no se puede deshacer.',
                  style: TextStyle(color: _label)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar', style: TextStyle(color: _label))),
                ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _deleteUser(user, index);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _danger,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: const Text('Eliminar',
                        style: TextStyle(color: Colors.white))),
              ],
            ));
  }

  Future<void> _deleteUser(Map<String, dynamic> user, int index) async {
    try {
      await ApiService.deleteUser(user['id']);
      setState(() => _users.removeAt(index));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${user['name']} eliminado correctamente'),
        backgroundColor: _success,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: _danger,
      ));
    }
  }
}

