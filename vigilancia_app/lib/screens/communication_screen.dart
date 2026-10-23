import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart'; // AppRoutes
import '../widgets/theme_toggle_button.dart';
import '../widgets/responsive.dart';
import '../theme/app_colors.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  // ── Paleta idéntica al proyecto ───────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1A5DC8);
  static const Color _dangerColor = Color(0xFFE53935);

  AppColors get _c => AppColors.of(context);
  Color get _bgColor => _c.bg;
  Color get _cardColor => _c.card;
  Color get _textColor => _c.text;
  Color get _labelColor => _c.label;

  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<_ChatMessage> _messages = [];
  bool _loading = true;
  int? _currentUserId;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages(showLoader: true);
    _getCurrentUserId();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _loadMessages(showLoader: false));
  }

  Future<void> _getCurrentUserId() async {
    try {
      final data = await ApiService.getUser();
      if (!mounted) return;
      setState(() => _currentUserId = data['id']);
    } catch (_) {}
  }

  Future<void> _loadMessages({bool showLoader = false}) async {
    if (showLoader) {
      setState(() => _loading = true);
    }
    try {
      final rawMessages = await ApiService.getMessages();
      if (!mounted) return;
      setState(() {
        _messages = rawMessages.map((m) {
          final user = m['user'] as Map<String, dynamic>?;
          return _ChatMessage(
            sender: user?['name'] ?? 'Desconocido',
            text: m['text'] ?? '',
            time: _formatTime(DateTime.parse(m['created_at'])),
            isMe: user?['id'] == _currentUserId,
            isAlert: false,
          );
        }).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (showLoader) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar mensajes: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      await ApiService.sendMessage(text);
      _msgCtrl.clear();
      _loadMessages(); // Recargar lista desde la API
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al enviar mensaje'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: ResponsiveShell(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildTopBar(),
              ),
              _buildGroupHeader(),
              _buildDayDivider('Hoy'),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) => _buildMessageItem(_messages[i]),
                      ),
              ),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
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
                  decoration: BoxDecoration(color: _primaryBlue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
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
            Text('Comunicación',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textColor)),
          ],
        ),
        Row(
          children: [
            const ThemeToggleButton(),
            const SizedBox(width: 4),
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
                final isCurrent = mod.route == AppRoutes.communication;
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
                    Navigator.pop(context);
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

  // ── Header del grupo ──────────────────────────────────────────────────────
  Widget _buildGroupHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: _primaryBlue.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.groups_rounded, color: _primaryBlue, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Grupo de Seguridad Vecinal',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textColor)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF43A047), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('12 vecinos activos', style: TextStyle(fontSize: 11, color: _labelColor)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: _labelColor, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ── Divisor de fecha ──────────────────────────────────────────────────────
  Widget _buildDayDivider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFBDCCE8), thickness: 0.8)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFBDCCE8).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(label, style: TextStyle(fontSize: 11, color: _labelColor, fontWeight: FontWeight.w500)),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFBDCCE8), thickness: 0.8)),
        ],
      ),
    );
  }

  // ── Items de mensaje ──────────────────────────────────────────────────────
  Widget _buildMessageItem(_ChatMessage msg) {
    if (msg.isAlert) return _buildAlertCard();
    if (msg.isMe) return _buildMyMessage(msg);
    return _buildOtherMessage(msg);
  }

  // Mensaje de otro usuario
  Widget _buildOtherMessage(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _primaryBlue.withValues(alpha: 0.15),
            child: Text(
              msg.sender.isNotEmpty ? msg.sender[0] : '?',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _primaryBlue),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(msg.sender, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _primaryBlue)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(msg.text, style: TextStyle(fontSize: 13, color: _textColor, height: 1.4)),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Text(msg.time, style: TextStyle(fontSize: 10, color: _labelColor)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // Mensaje propio (burbuja azul)
  Widget _buildMyMessage(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 40),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _primaryBlue,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(4),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(color: _primaryBlue.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Text(msg.text, style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4)),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4, top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(msg.time, style: TextStyle(fontSize: 10, color: _labelColor)),
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all_rounded, size: 13, color: _primaryBlue),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta de alerta del sistema (sin cambios)
  Widget _buildAlertCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _dangerColor.withValues(alpha: 0.4), width: 1),
        boxShadow: [
          BoxShadow(color: _dangerColor.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: _dangerColor, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('ALERTA DE SEGURIDAD', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _dangerColor, letterSpacing: 0.3)),
            ],
          ),
          const SizedBox(height: 10),
          Text('Cámara de la puerta principal detectó actividad inusual. El equipo de vigilancia ha sido notificado.',
              style: TextStyle(fontSize: 12, color: _textColor, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Ver Cámara', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _dangerColor,
                    side: const BorderSide(color: _dangerColor, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Falsa Alarma', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: Row(
        children: [
          _inputIconBtn(Icons.add_circle_outline_rounded, () {}),
          const SizedBox(width: 4),
          _inputIconBtn(Icons.camera_alt_outlined, () {}),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _msgCtrl,
                style: TextStyle(fontSize: 13, color: _textColor),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: TextStyle(fontSize: 13, color: _labelColor),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: _primaryBlue, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: const Color(0xFFF0F4FA), shape: BoxShape.circle),
        child: Icon(icon, color: _labelColor, size: 20),
      ),
    );
  }


}

// ── Modelos ───────────────────────────────────────────────────────────────────
class _ChatMessage {
  final String sender;
  final String text;
  final String time;
  final bool isMe;
  final bool isAlert;
  const _ChatMessage({
    required this.sender,
    required this.text,
    required this.time,
    required this.isMe,
    required this.isAlert,
  });
}

class _ModuleItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _ModuleItem(this.icon, this.label, this.route, this.color);
}