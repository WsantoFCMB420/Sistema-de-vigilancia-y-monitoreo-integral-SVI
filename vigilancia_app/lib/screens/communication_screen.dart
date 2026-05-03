import 'package:flutter/material.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  // ── Paleta idéntica al proyecto ───────────────────────────────────────────
  static const Color _bgColor = Color(0xFFDDE8F5);
  static const Color _primaryBlue = Color(0xFF1A5DC8);
  static const Color _textColor = Color(0xFF1A2340);
  static const Color _labelColor = Color(0xFF6B7A99);
  static const Color _dangerColor = Color(0xFFE53935);
  static const Color _cardColor = Colors.white;

  int _currentIndex = 0; // Dashboard en nav (ajusta según tu router)

  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      sender: 'Marta García',
      text:
          '¿Alguien más vio el camión blanco estacionado cerca del parque? Lleva ahí más de dos horas.',
      time: '10:42 AM',
      isMe: false,
      isAlert: false,
    ),
    _ChatMessage(
      sender: '',
      text: '',
      time: '',
      isMe: false,
      isAlert: true, // tarjeta de alerta del sistema
    ),
    _ChatMessage(
      sender: 'Yo',
      text:
          'Voy a revisar las cámaras perimetrales desde el panel de control. Manténganse en sus casas.',
      time: '10:45 AM',
      isMe: true,
      isAlert: false,
    ),
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildTopBar(),
            ),
            // Header del grupo
            _buildGroupHeader(),
            // Divisor de fecha
            _buildDayDivider('Hoy'),
            // Lista de mensajes
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _messages.length,
                itemBuilder: (ctx, i) => _buildMessageItem(_messages[i]),
              ),
            ),
            // Input bar
            _buildInputBar(),
            // Bottom nav
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ── AppBar (idéntico al Dashboard) ────────────────────────────────────────
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
                color: _textColor,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.search_rounded, color: _textColor),
              onPressed: () {},
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: _primaryBlue.withOpacity(0.15),
              child: const Icon(
                Icons.person_rounded,
                color: _primaryBlue,
                size: 20,
              ),
            ),
          ],
        ),
      ],
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
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _primaryBlue.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: _primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grupo de Seguridad Vecinal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF43A047),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      '12 vecinos activos',
                      style: TextStyle(fontSize: 11, color: _labelColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: _labelColor,
              size: 20,
            ),
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
          const Expanded(
            child: Divider(color: Color(0xFFBDCCE8), thickness: 0.8),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFBDCCE8).withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: _labelColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: Color(0xFFBDCCE8), thickness: 0.8),
          ),
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
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: _primaryBlue.withOpacity(0.15),
            child: Text(
              msg.sender.isNotEmpty ? msg.sender[0] : '?',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    msg.sender,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _primaryBlue,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _textColor,
                      height: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Text(
                    msg.time,
                    style: const TextStyle(fontSize: 10, color: _labelColor),
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryBlue,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(4),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4, top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg.time,
                        style: const TextStyle(
                          fontSize: 10,
                          color: _labelColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.done_all_rounded,
                        size: 13,
                        color: _primaryBlue,
                      ),
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

  // Tarjeta de alerta del sistema
  Widget _buildAlertCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _dangerColor.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: _dangerColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _dangerColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'ALERTA DE SEGURIDAD',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _dangerColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Cámara de la puerta principal detectó actividad inusual. El equipo de vigilancia ha sido notificado.',
            style: TextStyle(fontSize: 12, color: _textColor, height: 1.4),
          ),
          const SizedBox(height: 12),
          // Botones
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Ver Cámara',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Falsa Alarma',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
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
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Adjuntar
          _inputIconBtn(Icons.add_circle_outline_rounded, () {}),
          const SizedBox(width: 4),
          // Cámara
          _inputIconBtn(Icons.camera_alt_outlined, () {}),
          const SizedBox(width: 8),
          // Campo de texto
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
                style: const TextStyle(fontSize: 13, color: _textColor),
                decoration: const InputDecoration(
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
          // Enviar
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FA),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _labelColor, size: 20),
      ),
    );
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        _ChatMessage(
          sender: 'Yo',
          text: text,
          time: _nowTime(),
          isMe: true,
          isAlert: false,
        ),
      );
      _msgCtrl.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _nowTime() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ── Bottom Navigation (idéntica al Dashboard) ─────────────────────────────
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
                      color: selected ? _primaryBlue : const Color(0xFF9E9E9E),
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
                            ? _primaryBlue
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

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem(this.icon, this.label);
}
