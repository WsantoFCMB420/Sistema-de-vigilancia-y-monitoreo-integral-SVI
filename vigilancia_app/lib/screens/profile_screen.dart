import 'package:flutter/material.dart';

import '../main.dart'; // AppRoutes, SessionService
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/responsive.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppColors get _c => AppColors.of(context);

  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;
  bool _editing = false;
  bool _saving = false;
  bool _argsRead = false;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    // "Editar perfil" desde el menú abre la pantalla en modo edición.
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['edit'] == true) _editing = true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = _profile == null;
      _error = null;
    });
    try {
      final data = await ApiService.getProfile();
      if (!mounted) return;
      setState(() {
        _profile = data;
        _nameCtrl.text = (data['name'] ?? '').toString();
        _phoneCtrl.text = (data['phone'] ?? '').toString();
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

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final updated = await ApiService.updateProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      final user = updated['user'];
      if (user is Map) {
        await SessionService.updateName((user['name'] ?? _nameCtrl.text.trim()).toString());
      }
      if (!mounted) return;
      setState(() {
        if (user is Map) _profile = Map<String, dynamic>.from(user);
        _editing = false;
        _saving = false;
      });
      showAppSnackBar(context, 'Perfil actualizado', backgroundColor: AppColors.success, icon: Icons.check_rounded);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, e.toString().replaceFirst('Exception: ', ''), backgroundColor: AppColors.danger);
    }
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _nameCtrl.text = (_profile?['name'] ?? '').toString();
      _phoneCtrl.text = (_profile?['phone'] ?? '').toString();
    });
  }

  Future<void> _changePassword() async {
    final pass = TextEditingController();
    final confirm = TextEditingController();
    final key = GlobalKey<FormState>();
    bool busy = false;
    bool obscure = true;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialog) => AlertDialog(
          title: const Text('Cambiar contraseña'),
          content: SizedBox(
            width: 380,
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: pass,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setDialog(() => obscure = !obscure),
                        icon: Icon(obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirm,
                    obscureText: obscure,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar contraseña',
                      prefixIcon: Icon(Icons.lock_reset_rounded),
                    ),
                    validator: (v) => v != pass.text ? 'Las contraseñas no coinciden' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (!(key.currentState?.validate() ?? false)) return;
                      setDialog(() => busy = true);
                      try {
                        await ApiService.updateProfile(password: pass.text, passwordConfirmation: confirm.text);
                        if (!dialogCtx.mounted) return;
                        Navigator.pop(dialogCtx);
                        if (!mounted) return;
                        showAppSnackBar(context, 'Contraseña actualizada', backgroundColor: AppColors.success);
                      } catch (e) {
                        setDialog(() => busy = false);
                        if (!mounted) return;
                        showAppSnackBar(context, e.toString().replaceFirst('Exception: ', ''),
                            backgroundColor: AppColors.danger);
                      }
                    },
              child: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    pass.dispose();
    confirm.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    final pad = wide ? 28.0 : 16.0;
    return Scaffold(
      backgroundColor: _c.bg,
      drawer: const AppDrawer(currentRoute: AppRoutes.profile),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 14, pad, 12),
              child: const AppTopBar(
                title: 'Mi perfil',
                subtitle: 'Datos de tu cuenta',
                icon: Icons.manage_accounts_rounded,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _profile == null
                      ? _buildError()
                      : SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(pad, 4, pad, 32),
                          child: ResponsiveShell(maxWidth: 760, child: _buildContent()),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 46),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: _c.label)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final p = _profile ?? const {};
    final name = (p['name'] ?? '').toString();
    final email = (p['email'] ?? '').toString();
    final phone = (p['phone'] ?? '').toString();
    final role = (p['role'] ?? 'viewer').toString();
    final roleColor = RoleAccess.color(role);
    final initials = UserSnapshot(name, email, role).initials;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Encabezado
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Container(
                height: 84,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF0B1F44)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: _c.card, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: roleColor.withValues(alpha: 0.16),
                        child: Text(initials,
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: roleColor)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(name.isEmpty ? 'Usuario' : name,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _c.text)),
                    const SizedBox(height: 2),
                    Text(email, style: TextStyle(fontSize: 13, color: _c.label)),
                    const SizedBox(height: 10),
                    RoleChip(role: role),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Datos / edición
        AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Información personal',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _c.text)),
                    ),
                    if (!_editing)
                      TextButton.icon(
                        onPressed: () => setState(() => _editing = true),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Editar'),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_editing) ...[
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().length < 3) ? 'Escribe tu nombre' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) => (v != null && v.trim().length > 20) ? 'Máximo 20 caracteres' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: email,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Correo (no se puede cambiar)',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : _cancelEdit,
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _saveProfile,
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Guardar cambios'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  _infoRow(Icons.person_outline_rounded, 'Nombre', name),
                  _infoRow(Icons.mail_outline_rounded, 'Correo', email),
                  _infoRow(Icons.phone_outlined, 'Teléfono', phone.isEmpty ? 'Sin registrar' : phone),
                  _infoRow(Icons.badge_outlined, 'Rol', RoleAccess.label(role), last: true),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Seguridad
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              ListTile(
                leading: _leadingIcon(Icons.lock_outline_rounded, AppColors.primary),
                title: Text('Cambiar contraseña',
                    style: TextStyle(fontWeight: FontWeight.w700, color: _c.text)),
                subtitle: Text('Actualiza la clave de acceso', style: TextStyle(color: _c.label, fontSize: 12)),
                trailing: Icon(Icons.chevron_right_rounded, color: _c.hint),
                onTap: _changePassword,
              ),
              Divider(height: 1, indent: 68, color: _c.border),
              ListTile(
                leading: _leadingIcon(Icons.logout_rounded, AppColors.danger),
                title: const Text('Cerrar sesión',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger)),
                subtitle: Text('Salir de este dispositivo', style: TextStyle(color: _c.label, fontSize: 12)),
                onTap: () => performLogout(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _leadingIcon(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: _c.tint(color), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: _c.border)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _c.label),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(fontSize: 13, color: _c.label)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _c.text)),
          ),
        ],
      ),
    );
  }
}
