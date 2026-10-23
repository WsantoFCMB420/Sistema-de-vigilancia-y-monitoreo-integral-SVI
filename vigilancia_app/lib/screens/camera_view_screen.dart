import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';
import '../widgets/local_camera_preview.dart';
import '../widgets/theme_toggle_button.dart';

class CameraViewScreen extends StatefulWidget {
  final String cameraId;
  final String cameraName;

  const CameraViewScreen({
    super.key,
    this.cameraId = '04',
    this.cameraName = 'Perimeter North',
  });

  @override
  State<CameraViewScreen> createState() => _CameraViewScreenState();
}

class _CameraViewScreenState extends State<CameraViewScreen> {
  // ── Paleta idéntica al proyecto ───────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1A5DC8);
  static const Color _textColor = Color(0xFF1A2340);
  static const Color _dangerColor = Color(0xFFE53935);

  bool _isPlaying = true;
  bool _isMuted = false;
  double _timeline = 0.72; // posición del scrubber

  // ── Datos dinámicos del dispositivo / cámara ─────────────────────────────
  bool _argsLoaded = false;
  int? _deviceId;
  String _cameraTitle = 'Webcam local';
  String _streamUrl = '';
  String _ipAddress = '';
  bool _isPtz = false;
  String? _ptzFeedback;
  String _activeCameraName = 'Cámara del equipo';
  final GlobalKey<LocalCameraPreviewState> _previewKey =
      GlobalKey<LocalCameraPreviewState>();

  bool get _useLocalCamera =>
      _streamUrl.isEmpty || ApiService.isLocalCamera(_streamUrl);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _deviceId = args['id'] is int ? args['id'] : int.tryParse(args['id']?.toString() ?? '');
        _cameraTitle = args['title'] ?? 'Webcam local';
        _streamUrl = args['stream_url'] ?? '';
        _ipAddress = args['ip_address'] ?? '';
        _isPtz = args['is_ptz'] == true || args['is_ptz'] == 1;
      } else {
        _cameraTitle = 'Webcam local';
        _streamUrl = ApiService.localCameraStream;
        _ipAddress = 'dispositivo-local';
        _isPtz = false;
      }
      _argsLoaded = true;
    }
  }

  void _sendPTZ(String command) async {
    setState(() => _ptzFeedback = 'PTZ: $command...');
    if (_deviceId == null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _ptzFeedback = 'PTZ: $command (simulado)');
      });
      return;
    }

    try {
      await ApiService.sendPTZCommand(_deviceId!, command);
      if (!mounted) return;
      setState(() => _ptzFeedback = 'PTZ: $command ✓');
    } catch (e) {
      if (!mounted) return;
      setState(() => _ptzFeedback = 'Error PTZ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error PTZ: $e'), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildInfoChips(),
            _buildDetectionCards(),
            Expanded(child: _buildCameraFeed()),
            _buildControls(),
            _buildTimeline(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    final displayId = _deviceId != null ? '#$_deviceId' : widget.cameraId;
    return Container(
      color: const Color(0xFF0D1117),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cámara $displayId - $_cameraTitle',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _chip('LIVE', const Color(0xFFE53935)),
                    const SizedBox(width: 6),
                    _chip(_ipAddress.isNotEmpty ? _ipAddress : 'WEBCAM / USB', const Color(0xFF1A5DC8)),
                    const SizedBox(width: 6),
                    if (_isPtz)
                      _chip('PTZ ACTIVO', const Color(0xFF00897B))
                    else
                      _chip('FIJA', const Color(0xFF6B7A99)),
                  ],
                ),
              ],
            ),
          ),
          // REC badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _dangerColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Colors.white, size: 6),
                SizedBox(width: 4),
                Text(
                  'REC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const ThemeToggleButton(),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: _primaryBlue.withValues(alpha: 0.25),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => _showCameraMenu(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final allModules = [
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
                final isCurrent = mod.route == AppRoutes.cameraView;
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

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // ── Chips de info (LIVE / 4K / FPS) ──────────────────────────────────────
  Widget _buildInfoChips() => const SizedBox.shrink(); // ya están en el AppBar

  // ── Cards de detección y red ──────────────────────────────────────────────
  Widget _buildDetectionCards() {
    return Container(
      color: const Color(0xFF0D1117),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: _infoCard(
              label: 'FUENTE',
              icon: Icons.videocam_rounded,
              value: _useLocalCamera ? _activeCameraName : 'Stream de red',
              iconColor: _primaryBlue,
              bgColor: _primaryBlue.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _infoCard(
              label: 'NETWORK',
              icon: Icons.network_check_rounded,
              value: _useLocalCamera ? 'Webcam / USB local' : 'Cámara IP',
              iconColor: const Color(0xFF43A047),
              bgColor: const Color(0xFF43A047).withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String label,
    required IconData icon,
    required String value,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: iconColor.withValues(alpha: 0.8),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveSource() {
    if (_useLocalCamera) {
      return LocalCameraPreview(
        key: _previewKey,
        playing: _isPlaying,
        onCameraSelected: (camera) {
          setState(() => _activeCameraName = camera.name);
        },
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(
              'Esta cámara de red no se puede previsualizar aquí:\n$_streamUrl',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _streamUrl = ApiService.localCameraStream;
                  _ipAddress = 'dispositivo-local';
                  _isPtz = false;
                });
              },
              icon: const Icon(Icons.videocam_rounded),
              label: const Text('Usar webcam / USB de este equipo'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureSnapshot() async {
    if (!_useLocalCamera) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La captura solo está disponible en la cámara local.')),
      );
      return;
    }
    try {
      final file = await _previewKey.currentState?.takePicture();
      if (!mounted) return;
      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo capturar la imagen.')),
        );
        return;
      }
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0D1117),
          title: const Text('Captura guardada', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!kIsWeb)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(file.path), height: 180, fit: BoxFit.cover),
                ),
              const SizedBox(height: 8),
              Text(
                file.path,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al capturar: $e')),
      );
    }
  }

  // ── Feed de la cámara con joystick PTZ y botón ALARM ─────────────────────
  Widget _buildCameraFeed() {
    return Stack(
      children: [
        Positioned.fill(child: _buildLiveSource()),
        if (_ptzFeedback != null)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A5DC8).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _ptzFeedback!,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        if (_isPtz && !_useLocalCamera)
          Positioned(right: 20, bottom: 60, child: _buildPTZJoystick()),
        Positioned(
          left: 0,
          right: 0,
          bottom: 50,
          child: Center(
            child: GestureDetector(
              onTap: _showAlarmDialog,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _dangerColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _dangerColor.withValues(alpha: 0.5),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    Text(
                      'ALARM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 12,
          child: Text(
            '${TimeOfDay.now().format(context)} LIVE',
            style: const TextStyle(
              color: _primaryBlue,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Joystick PTZ ──────────────────────────────────────────────────────────
  Widget _buildPTZJoystick() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centro (Stop)
          GestureDetector(
            onTap: () => _sendPTZ('stop'),
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: _primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pan_tool_rounded, color: Colors.white, size: 14),
            ),
          ),
          // Flechas
          Positioned(top: 8, child: _ptzArrow(Icons.keyboard_arrow_up_rounded, () => _sendPTZ('up'))),
          Positioned(
            bottom: 8,
            child: _ptzArrow(Icons.keyboard_arrow_down_rounded, () => _sendPTZ('down')),
          ),
          Positioned(
            left: 8,
            child: _ptzArrow(Icons.keyboard_arrow_left_rounded, () => _sendPTZ('left')),
          ),
          Positioned(
            right: 8,
            child: _ptzArrow(Icons.keyboard_arrow_right_rounded, () => _sendPTZ('right')),
          ),
        ],
      ),
    );
  }

  Widget _ptzArrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 26),
    );
  }

  // ── Barra de controles ─────────────────────────────────────────────────────
  Widget _buildControls() {
    return Container(
      color: const Color(0xFF0D1117),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _controlBtn(
            _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            onTap: () => setState(() => _isMuted = !_isMuted),
          ),
          _controlBtn(Icons.camera_alt_rounded, onTap: _captureSnapshot),
          _controlBtn(Icons.zoom_out_rounded, onTap: () => _sendPTZ('zoom_out')),
          // Pause/Play — destacado
          GestureDetector(
            onTap: () => setState(() => _isPlaying = !_isPlaying),
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: _primaryBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          _controlBtn(Icons.zoom_in_rounded, onTap: () => _sendPTZ('zoom_in')),
          _controlBtn(Icons.notifications_active_rounded, onTap: _showAlarmDialog),
        ],
      ),
    );
  }

  Widget _controlBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  // ── Timeline scrubber ──────────────────────────────────────────────────────
  Widget _buildTimeline() {
    return Container(
      color: const Color(0xFF0D1117),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: _primaryBlue,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
              thumbColor: _primaryBlue,
              overlayColor: _primaryBlue.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _timeline,
              onChanged: (v) => setState(() => _timeline = v),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '19:45:00',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
              Text(
                '19:50:00',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
              Text(
                '19:55:00',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
              Text(
                '20:00:14',
                style: TextStyle(
                  color: Color(0xFF1A5DC8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Acciones ──────────────────────────────────────────────────────────────
  void _showAlarmDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1117),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emitir Alerta desde "$_cameraTitle"',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Esta alerta quedará vinculada automáticamente a esta cámara.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _alarmOption(
              Icons.warning_amber_rounded,
              'Intrusión / Seguridad',
              'Seguridad',
              'Crítica',
              const Color(0xFFE53935),
            ),
            const SizedBox(height: 8),
            _alarmOption(
              Icons.local_fire_department_rounded,
              'Incendio / Evacuación',
              'Incendio',
              'Crítica',
              const Color(0xFFFF6D00),
            ),
            const SizedBox(height: 8),
            _alarmOption(
              Icons.info_rounded,
              'Aviso General / Sospecha',
              'Seguridad',
              'Media',
              const Color(0xFF1A5DC8),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _alarmOption(
    IconData icon,
    String label,
    String type,
    String priority,
    Color color,
  ) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        try {
          await ApiService.sendAlert(
            type: type,
            priority: priority,
            location: _cameraTitle,
            description: 'Alerta detectada desde la cámara "$_cameraTitle"',
            deviceId: _deviceId,
            status: 'Pendiente',
          );
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF43A047), size: 24),
                  SizedBox(width: 8),
                  Text('Alerta Emitida'),
                ],
              ),
              content: Text('Alerta "$label" vinculada a "$_cameraTitle" enviada correctamente.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al emitir alerta: $e'), backgroundColor: Colors.redAccent),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCameraMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1117),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _menuItem(Icons.download_rounded, 'Descargar grabación'),
            const SizedBox(height: 8),
            _menuItem(Icons.share_rounded, 'Compartir feed'),
            const SizedBox(height: 8),
            _menuItem(Icons.settings_rounded, 'Configuración de cámara'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
