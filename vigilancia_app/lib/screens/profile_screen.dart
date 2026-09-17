import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _bgColor     = Color(0xFFDDE8F5);
  static const Color _primaryBlue = Color(0xFF1A5DC8);
  static const Color _cardColor   = Colors.white;
  static const Color _labelColor  = Color(0xFF6B7A99);
  static const Color _textColor   = Color(0xFF1A2340);
  static const Color _dangerColor = Color(0xFFE53935);

  String _userName = 'Cargando...';
  String _userEmail = '...';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final name = await SessionService.getUserName();
    final email = await SessionService.getUserEmail();
    if (mounted) {
      setState(() {
        _userName = name;
        _userEmail = email;
      });
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión',
            style: TextStyle(fontWeight: FontWeight.w700, color: _textColor)),
        content: const Text('¿Estás seguro de que deseas salir del sistema?',
            style: TextStyle(color: _labelColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: _labelColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _dangerColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: _primaryBlue),
      ),
    );

    await ApiService.logout();
    await SessionService.logout();

    if (!mounted) return;
    Navigator.pop(context); // cerrar modal loading
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('AJUSTES DE CUENTA'),
                  const SizedBox(height: 10),
                  _buildMenuCard([
                    _buildMenuItem(Icons.person_outline_rounded, 'Editar Perfil', true),
                    _buildMenuItem(Icons.lock_outline_rounded, 'Seguridad y Contraseña', true),
                    _buildMenuItem(Icons.notifications_none_rounded, 'Notificaciones', false),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('PREFERENCIAS DEL SISTEMA'),
                  const SizedBox(height: 10),
                  _buildMenuCard([
                    _buildMenuItem(Icons.language_rounded, 'Idioma (Español)', true),
                    _buildMenuItem(Icons.dark_mode_outlined, 'Modo Oscuro', false, trailing: Switch(
                      value: false,
                      onChanged: (v) {},
                      activeColor: _primaryBlue,
                    )),
                  ]),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Cerrar Sesión',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cardColor,
                        foregroundColor: _dangerColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFFFCDD2), width: 1),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
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
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: _primaryBlue, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Mi Perfil',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            color: _primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: _primaryBlue.withOpacity(0.3), width: 2),
          ),
          child: const Center(
            child: Icon(Icons.person_rounded, color: _primaryBlue, size: 45),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _userName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textColor),
        ),
        const SizedBox(height: 4),
        Text(
          _userEmail,
          style: const TextStyle(fontSize: 14, color: _labelColor),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3), width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_rounded, color: Color(0xFF2E7D32), size: 14),
              SizedBox(width: 6),
              Text('Administrador',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: _labelColor, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, bool hasBorder, {Widget? trailing}) {
    return Container(
      decoration: BoxDecoration(
        border: hasBorder
            ? const Border(bottom: BorderSide(color: Color(0xFFF0F4FA), width: 1))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _primaryBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primaryBlue, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textColor)),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: _labelColor, size: 20),
        onTap: trailing != null ? null : () {
          // Placeholder para futuras acciones
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Función en desarrollo')),
          );
        },
      ),
    );
  }
}
