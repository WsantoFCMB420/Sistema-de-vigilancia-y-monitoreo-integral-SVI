import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart'; // AppRoutes, SessionService
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/bogota_time.dart';
import '../widgets/app_shell.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  AppColors get _c => AppColors.of(context);

  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  List<_ChatListItem> _chatItems = [];
  int _participants = 0;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  int? _currentUserId;
  int _lastMessageId = 0;
  Timer? _pollTimer;

  // Caché en memoria: al volver al módulo los mensajes aparecen al instante
  // y se actualizan en segundo plano.
  static List<_ChatListItem> _cachedItems = [];
  static int _cachedParticipants = 0;
  static int _cachedLastId = 0;
  static int? _cachedForUser;

  @override
  void initState() {
    super.initState();
    _currentUserId = SessionService.cachedUserId;
    if (_cachedForUser == _currentUserId && _cachedItems.isNotEmpty) {
      _chatItems = _cachedItems;
      _participants = _cachedParticipants;
      _lastMessageId = _cachedLastId;
      _loading = false;
      _scrollToBottom(animate: false);
    }
    _initData();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _loadMessages(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await _loadMessages(silent: !_loading);
  }

  bool get _isNearBottom {
    if (!_scrollCtrl.hasClients) return true;
    final pos = _scrollCtrl.position;
    return pos.maxScrollExtent - pos.pixels < 120;
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final target = _scrollCtrl.position.maxScrollExtent;
      if (animate) {
        _scrollCtrl.animateTo(target, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      } else {
        _scrollCtrl.jumpTo(target);
      }
    });
  }

  Future<void> _loadMessages({bool silent = false}) async {
    try {
      if (_currentUserId == null || _currentUserId == 0) {
        _currentUserId = await SessionService.getUserId();
      }
      final raw = await ApiService.getMessages();
      if (!mounted) return;

      final items = <_ChatListItem>[];
      final senders = <int>{};
      String? lastDate;
      var lastId = 0;

      for (final m in raw.whereType<Map>()) {
        final msg = Map<String, dynamic>.from(m);
        final user = msg['user'] is Map ? Map<String, dynamic>.from(msg['user'] as Map) : null;
        final userId = user?['id'] is int ? user!['id'] as int : int.tryParse('${user?['id'] ?? msg['user_id']}');
        if (userId != null) senders.add(userId);

        final id = msg['id'] is int ? msg['id'] as int : int.tryParse('${msg['id']}') ?? 0;
        if (id > lastId) lastId = id;

        final when = BogotaTime.fromApi(
          iso: msg['created_at']?.toString(),
          localDate: msg['local_date']?.toString(),
          localTime: msg['local_time']?.toString(),
        );
        final dateLabel = BogotaTime.dayLabel(when);
        if (dateLabel != lastDate) {
          items.add(_ChatListItem.divider(dateLabel));
          lastDate = dateLabel;
        }

        final text = (msg['text'] ?? '').toString();
        items.add(_ChatListItem.message(_ChatMessage(
          sender: (user?['name'] ?? 'Desconocido').toString(),
          senderRole: (user?['role'] ?? '').toString(),
          text: text,
          time: BogotaTime.hourLabel(when),
          isMe: userId != null && userId == _currentUserId,
          alert: _AlertInfo.tryParse(text),
        )));
      }

      final hasNew = lastId != _lastMessageId;
      if (silent && !hasNew) return;
      final stickToBottom = _isNearBottom || _loading;

      setState(() {
        _chatItems = items;
        _participants = senders.length;
        _lastMessageId = lastId;
        _loading = false;
        _error = null;
      });
      _cachedItems = items;
      _cachedParticipants = senders.length;
      _cachedLastId = lastId;
      _cachedForUser = _currentUserId;
      if (stickToBottom) _scrollToBottom(animate: !silent || _chatItems.length < 60);
    } on SessionExpiredException {
      return;
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ApiService.sendMessage(text);
      _msgCtrl.clear();
      await _loadMessages(silent: true);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'No se pudo enviar el mensaje', backgroundColor: AppColors.danger);
    } finally {
      if (mounted) setState(() => _sending = false);
      _inputFocus.requestFocus();
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    final pad = wide ? 28.0 : 12.0;
    return Scaffold(
      backgroundColor: _c.bg,
      drawer: const AppDrawer(currentRoute: AppRoutes.communication),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 14, wide ? 28 : 16, 12),
              child: const AppTopBar(
                title: 'Comunicación',
                subtitle: 'Canal de seguridad • Hora de Bogotá (UTC-5)',
                icon: Icons.forum_rounded,
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 0, pad, wide ? 20 : 0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _c.card,
                        borderRadius: wide
                            ? BorderRadius.circular(22)
                            : const BorderRadius.vertical(top: Radius.circular(22)),
                        border: Border.all(color: _c.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _buildGroupHeader(),
                          Divider(height: 1, color: _c.border),
                          Expanded(
                            child: ColoredBox(color: _c.cardAlt, child: _buildMessages()),
                          ),
                          _buildInputBar(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: _c.tint(AppColors.primary), shape: BoxShape.circle),
            child: const Icon(Icons.groups_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Grupo de Seguridad Vecinal',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _c.text)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _participants == 1 ? '1 participante' : '$_participants participantes',
                      style: TextStyle(fontSize: 12, color: _c.label),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => _loadMessages(),
            icon: Icon(Icons.refresh_rounded, color: _c.label),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _chatItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.danger, size: 40),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: _c.label)),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => _loadMessages(), child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    if (_chatItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, color: _c.hint, size: 44),
            const SizedBox(height: 10),
            Text('Aún no hay mensajes. Escribe el primero.', style: TextStyle(color: _c.label)),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      itemCount: _chatItems.length,
      itemBuilder: (_, i) {
        final item = _chatItems[i];
        if (item.isDivider) return _buildDayDivider(item.dividerText ?? '');
        final msg = item.message!;
        if (msg.alert != null) return _buildAlertCard(msg);
        return _buildBubble(msg);
      },
    );
  }

  Widget _buildDayDivider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _c.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _c.border),
          ),
          child: Text(label, style: TextStyle(fontSize: 11, color: _c.label, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final me = msg.isMe;
    final roleColor = RoleAccess.color(msg.senderRole);
    final bubble = Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 8),
      decoration: BoxDecoration(
        color: me ? AppColors.primary : _c.card,
        border: me ? null : Border.all(color: _c.border),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(me ? 18 : 6),
          topRight: Radius.circular(me ? 6 : 18),
          bottomLeft: const Radius.circular(18),
          bottomRight: const Radius.circular(18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!me)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(msg.sender,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: roleColor)),
            ),
          Text(msg.text,
              style: TextStyle(fontSize: 14, height: 1.35, color: me ? Colors.white : _c.text)),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.bottomRight,
            widthFactor: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(msg.time,
                    style: TextStyle(fontSize: 10, color: me ? Colors.white70 : _c.label)),
                if (me) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all_rounded, size: 13, color: Colors.white70),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: me ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!me) ...[
            CircleAvatar(
              radius: 15,
              backgroundColor: roleColor.withValues(alpha: 0.15),
              child: Text(
                msg.sender.isNotEmpty ? msg.sender[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: roleColor),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: bubble),
          ),
          if (me) const SizedBox(width: 4),
        ],
      ),
    );
  }

  /// Mensajes que publica el backend al emitir una alerta.
  Widget _buildAlertCard(_ChatMessage msg) {
    final a = msg.alert!;
    final color = a.priority == 'Crítica'
        ? AppColors.danger
        : (a.priority == 'Baja' ? AppColors.success : AppColors.warning);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _c.tint(color),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9)),
                      child: const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ALERTA • ${a.type.toUpperCase()}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.4)),
                          Text('${msg.sender} • ${msg.time}', style: TextStyle(fontSize: 11, color: _c.label)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                      child: Text(a.priority,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (a.location.isNotEmpty) _alertLine(Icons.place_outlined, a.location),
                if (a.device.isNotEmpty) _alertLine(Icons.videocam_outlined, a.device),
                if (a.detail.isNotEmpty) _alertLine(Icons.notes_rounded, a.detail),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => navigateToModule(context, AppRoutes.alerts),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Ver en Alertas'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _alertLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: _c.label),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: _c.text, height: 1.3))),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: _c.card,
        border: Border(top: BorderSide(color: _c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                focusNode: _inputFocus,
                minLines: 1,
                maxLines: 4,
                maxLength: 500,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: TextStyle(fontSize: 14, color: _c.text),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje…',
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: _c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: _c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 46,
              height: 46,
              child: IconButton.filled(
                tooltip: 'Enviar',
                onPressed: _sending ? null : _sendMessage,
                style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                icon: _sending
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modelos ──────────────────────────────────────────────────────────────
class _ChatListItem {
  final bool isDivider;
  final String? dividerText;
  final _ChatMessage? message;
  const _ChatListItem.divider(this.dividerText)
      : isDivider = true,
        message = null;
  const _ChatListItem.message(this.message)
      : isDivider = false,
        dividerText = null;
}

class _ChatMessage {
  final String sender;
  final String senderRole;
  final String text;
  final String time;
  final bool isMe;
  final _AlertInfo? alert;
  const _ChatMessage({
    required this.sender,
    required this.senderRole,
    required this.text,
    required this.time,
    required this.isMe,
    this.alert,
  });
}

/// Datos de un mensaje automático "[ALERTA OPERATIVA] Tipo: … | Prioridad: … | …".
class _AlertInfo {
  final String type;
  final String priority;
  final String location;
  final String device;
  final String detail;
  const _AlertInfo(this.type, this.priority, this.location, this.device, this.detail);

  static _AlertInfo? tryParse(String text) {
    if (!text.contains('[ALERTA OPERATIVA]')) return null;
    final body = text.substring(text.indexOf('[ALERTA OPERATIVA]') + '[ALERTA OPERATIVA]'.length);
    final fields = <String, String>{};
    for (final part in body.split('|')) {
      final i = part.indexOf(':');
      if (i < 0) continue;
      fields[part.substring(0, i).trim().toLowerCase()] = part.substring(i + 1).trim();
    }
    return _AlertInfo(
      fields['tipo'] ?? 'Alerta',
      fields['prioridad'] ?? 'Media',
      fields['ubicación'] ?? fields['ubicacion'] ?? '',
      fields['cámara/dispositivo'] ?? '',
      fields['detalle'] ?? '',
    );
  }
}
