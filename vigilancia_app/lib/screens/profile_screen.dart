import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/responsive.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppColors get _c => AppColors.of(context);
  Color get _bg    => _c.bg;
  Color get _card  => _c.card;
  Color get _label => _c.label;
  Color get _text  => _c.text;
  Color get _input => _c.input;
  Color get _border => _c.border;

  static const Color _blue   = Color(0xFF1A5DC8);
  static const Color _danger = Color(0xFFE53935);

  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;
  bool _editing = false;
  bool _saving  = false;

  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getProfile();
      setState(() {
        _profile = data;
        _nameCtrl.text  = data['name'] ?? '';
        _phoneCtrl.text = data['phone'] ?? '';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error   = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final updated = await ApiService.updateProfile(
        name:  _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      setState(() {
        _profile  = updated['user'];
        _editing  = false;
        _saving   = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Perfil actualizado correctamente'),
        backgroundColor: Color(0xFF16A34A),
      ));
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: _danger,
      ));
    }
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(1, 2)).toUpperCase();
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'admin':    return 'Administrador';
      case 'operator': return 'Operador';
      default:         return 'Visitante';
    }
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'admin':    return _blue;
      case 'operator': return const Color(0xFFF59E0B);
      default:         return _label;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: ResponsiveShell(
          maxWidth: 700,
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _blue))
                  : _error != null
                    ? _buildError()
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_rounded, color: _blue, size: 22),
              ),
            ),
          ),
          Text('Mi Perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _text)),
          Row(
            children: [
              const ThemeToggleButton(),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() { _editing = !_editing; if (!_editing) _loadProfile(); }),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: _blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_editing ? Icons.close_rounded : Icons.edit_rounded, color: _blue, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    const allModules = [
      _ModuleItem(Icons.dashboard_rounded, 'Dashboard', AppRoutes.dashboard, Color(0xFF1A5DC8)),
      _ModuleItem(Icons.map_rounded, 'Mapa', AppRoutes.map, Color(0xFF00897B)),
      _ModuleItem(Icons.videocam_rounded, 'Cámaras', AppRoutes.cameraView, Color(0xFF6D4C41)),
      _ModuleItem(Icons.devices_rounded, 'Dispositivos', AppRoutes.devices, Color(0xFF5E35B1)),
      _ModuleItem(Icons.warning_amber_rounded, 'Alertas', AppRoutes.alerts, Color(0xFFE53935)),
      _ModuleItem(Icons.forum_rounded, 'Comunicación', AppRoutes.communication, Color(0xFF0288D1)),
      _ModuleItem(Icons.psychology_rounded, 'IA Hub', AppRoutes.iaModule, Color(0xFF7B1FA2)),
      _ModuleItem(Icons.assessment_rounded, 'Reportes', AppRoutes.reportes, Color(0xFF2E7D32)),
      _ModuleItem(Icons.admin_panel_settings_rounded, 'Admin', AppRoutes.admin, Color(0xFFAD1457)),
    ];
    return Drawer(
      backgroundColor: _card,
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
              children: allModules.map((mod) {
                return ListTile(
                  leading: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: mod.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(mod.icon, color: mod.color, size: 20),
                  ),
                  title: Text(
                    mod.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _text,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, mod.route);
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: _danger),
            title: const Text('Cerrar sesión', style: TextStyle(color: _danger, fontWeight: FontWeight.w600)),
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

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline_rounded, color: _danger, size: 48),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: _danger, fontSize: 14), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _loadProfile,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    );
  }

  Widget _buildContent() {
    final p = _profile!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(children: [
        // ── Avatar + Nombre ─────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: _c.isDark ? const Color(0x4D000000) : const Color(0x0D000000),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: [
            Stack(children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: _roleColor(p['role']).withValues(alpha: 0.15),
                child: Text(_initials(p['name']),
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _roleColor(p['role']))),
              ),
              if (_editing) Positioned(bottom: 0, right: 0,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: _blue, shape: BoxShape.circle,
                    border: Border.fromBorderSide(BorderSide(color: _card, width: 2))),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14))),
            ]),
            const SizedBox(height: 14),
            Text(p['name'] ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _text)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _roleColor(p['role']).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20)),
              child: Text(_roleLabel(p['role']),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _roleColor(p['role']))),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // ── Campos ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: _c.isDark ? const Color(0x33000000) : const Color(0x0A000000),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(children: [
            _buildInfoRow(Icons.person_rounded, 'NOMBRE COMPLETO', _editing
              ? _buildEditField(_nameCtrl, 'Tu nombre')
              : Text(p['name'] ?? '–', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text))),
            Divider(height: 24, color: _border),
            _buildInfoRow(Icons.email_rounded, 'CORREO ELECTRÓNICO',
              Text(p['email'] ?? '–', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text))),
            Divider(height: 24, color: _border),
            _buildInfoRow(Icons.phone_rounded, 'TELÉFONO', _editing
              ? _buildEditField(_phoneCtrl, '+57 300 000 0000')
              : Text(p['phone'] ?? 'No registrado', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p['phone'] != null ? _text : _label))),
          ]),
        ),

        if (_editing) ...[
          const SizedBox(height: 16),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _saving
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Guardar cambios', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            )),
        ],

        const SizedBox(height: 16),

        // ── Cerrar sesión ─────────────────────────────────────────
        SizedBox(width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await ApiService.logout();
              await SessionService.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
            },
            icon: const Icon(Icons.logout_rounded, color: _danger, size: 18),
            label: const Text('Cerrar sesión', style: TextStyle(color: _danger, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: _danger, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          )),
      ]),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, Widget content) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: _blue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: _blue, size: 18)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _label, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        content,
      ])),
    ]);
  }

  Widget _buildEditField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: TextStyle(fontSize: 14, color: _text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _c.hint, fontSize: 13),
        filled: true,
        fillColor: _input,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _blue, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _border)),
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
