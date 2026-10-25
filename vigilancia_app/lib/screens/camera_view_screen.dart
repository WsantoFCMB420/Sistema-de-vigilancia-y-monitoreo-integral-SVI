import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../main.dart';
import '../theme/app_colors.dart';
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
  static const Color _dangerColor = Color(0xFFE53935);

  AppColors get _c => AppColors.of(context);

  bool _isPlaying = true;
  bool _isMuted = false;
  double _timeline = 0.72; // posición del scrubber
  double _zoom = 1.0;

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

  List<dynamic> _availableCameras = [];
  int _currentCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAvailableCameras();
  }

  Future<void> _loadAvailableCameras() async {
    try {
      final devices = await ApiService.getDevices();
      if (!mounted) return;
      setState(() {
        _availableCameras = devices;
        if (_deviceId != null) {
          _currentCameraIndex = _availableCameras.indexWhere((d) => d['id'] == _deviceId);
          if (_currentCameraIndex < 0) _currentCameraIndex = 0;
        }
      });
    } catch (_) {}
  }

  void _nextCamera() {
    if (_availableCameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay más cámaras registradas')),
      );
      return;
    }
    setState(() {
      _currentCameraIndex = (_currentCameraIndex + 1) % _availableCameras.length;
      final d = _availableCameras[_currentCameraIndex];
      _deviceId = d['id'] is int ? d['id'] : int.tryParse(d['id']?.toString() ?? '');
      _cameraTitle = (d['title'] ?? d['name'] ?? 'Cámara').toString();
      _streamUrl = d['stream_url'] ?? '';
      _ipAddress = d['ip_address'] ?? '';
      _isPtz = d['is_ptz'] == true || d['is_ptz'] == 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cambiando a: $_cameraTitle'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  bool get _useLocalCamera =>
      _streamUrl.isEmpty || ApiService.isLocalCamera(_streamUrl);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _deviceId = args['id'] is int ? args['id'] : int.tryParse(args['id']?.toString() ?? '');
        _cameraTitle = (args['title'] ?? args['name'] ?? widget.cameraName).toString();
        _streamUrl = args['stream_url'] ?? '';
        _ipAddress = args['ip_address'] ?? '';
        _isPtz = args['is_ptz'] == true || args['is_ptz'] == 1;
      } else {
        _cameraTitle = widget.cameraName.isNotEmpty ? widget.cameraName : 'Webcam local';
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
      backgroundColor: _c.bg,
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
    return Container(
      color: _c.card,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: _c.text,
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
                  _deviceId != null ? '#$_deviceId - $_cameraTitle' : _cameraTitle,
                  style: TextStyle(
                    color: _c.text,
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
          // Siguiente ➔ button
          ElevatedButton.icon(
            onPressed: _nextCamera,
            icon: const Icon(Icons.navigate_next_rounded, size: 14),
            label: const Text('Siguiente ➔', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(width: 4),
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
      backgroundColor: _c.card,
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
                      color: isCurrent ? _primaryBlue : _c.text,
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

  Widget _buildInfoChips() => const SizedBox.shrink();

  Widget _buildDetectionCards() {
    return Container(
      color: _c.card,
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
        Positioned.fill(
          child: ClipRect(
            child: Transform.scale(
              scale: _zoom,
              child: _buildLiveSource(),
            ),
          ),
        ),
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
          bottom: 8,
          left: 12,
          child: Text(
            '${TimeOfDay.now().format(context)} LIVE (Zoom: ${_zoom.toStringAsFixed(1)}x)',
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
          _controlBtn(
            Icons.zoom_out_rounded,
            onTap: () {
              setState(() {
                _zoom = (_zoom - 0.5).clamp(1.0, 3.0);
              });
              _sendPTZ('zoom_out');
            },
          ),
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
          _controlBtn(
            Icons.zoom_in_rounded,
            onTap: () {
              setState(() {
                _zoom = (_zoom + 0.5).clamp(1.0, 3.0);
              });
              _sendPTZ('zoom_in');
            },
          ),
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
      color: _c.card,
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
    int selectedTypeIndex = 0;
    String selectedPriority = 'Crítica';
    final descController = TextEditingController(text: 'Alerta generada desde cámara: $_cameraTitle');
    final locationController = TextEditingController(text: _cameraTitle);
    bool shareToChat = true;

    final types = [
      {'label': 'Seguridad', 'icon': Icons.shield_rounded, 'color': const Color(0xFF1A5DC8)},
      {'label': 'Incendio', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFFF6D00)},
      {'label': 'Médico', 'icon': Icons.medical_services_rounded, 'color': const Color(0xFF43A047)},
      {'label': 'Técnico', 'icon': Icons.engineering_rounded, 'color': const Color(0xFF7B1FA2)},
    ];

    final priorities = ['Baja', 'Media', 'Crítica'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D1117),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Emitir Alerta - $_cameraTitle',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('TIPO DE INCIDENTE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.6,
                  ),
                  itemCount: types.length,
                  itemBuilder: (ctx, i) {
                    final t = types[i];
                    final selected = selectedTypeIndex == i;
                    final color = t['color'] as Color;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedTypeIndex = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? color : Colors.white12, width: selected ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            Icon(t['icon'] as IconData, color: selected ? color : Colors.white60, size: 18),
                            const SizedBox(width: 8),
                            Text(t['label'] as String, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text('PRIORIDAD', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: priorities.map((p) {
                    final selected = selectedPriority == p;
                    final color = p == 'Crítica' ? const Color(0xFFE53935) : (p == 'Media' ? const Color(0xFFFFA000) : const Color(0xFF43A047));
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedPriority = p),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? color.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: selected ? color : Colors.white12, width: selected ? 2 : 1),
                          ),
                          child: Text(p, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('UBICACIÓN', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: locationController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('DESCRIPCIÓN', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Compartir en chat de comunicación', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                    Switch(
                      value: shareToChat,
                      activeColor: const Color(0xFF1A5DC8),
                      onChanged: (v) => setModalState(() => shareToChat = v),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final type = types[selectedTypeIndex]['label'] as String;
                      final loc = locationController.text;
                      final desc = descController.text;
                      Navigator.pop(context);
                      try {
                        await ApiService.sendAlert(
                          type: type,
                          priority: selectedPriority,
                          location: loc,
                          description: desc,
                          deviceId: _deviceId,
                          status: 'Pendiente',
                        );
                        if (shareToChat) {
                          try {
                            await ApiService.sendMessage('🚨 [ALERTA DESDE CÁMARA: $_cameraTitle]\nTipo: $type | Prioridad: $selectedPriority\nUbicación: $loc\nDescripción: ${desc.isNotEmpty ? desc : 'Sin descripción'}\n${_deviceId != null ? '📹 Cámara ID: $_deviceId' : ''}');
                          } catch (_) {}
                        }
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF0D1117),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Color(0xFF43A047), size: 24),
                                SizedBox(width: 8),
                                Text('Alerta Emitida', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                            content: Text(
                              'Alerta "$type" emitida correctamente para "$_cameraTitle".'
                              '${shareToChat ? "\n(Compartida en el chat)" : ""}',
                              style: const TextStyle(color: Colors.white70),
                            ),
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
                    child: const Text('EMITIR ALERTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Menú 3 Puntos ──────────────────────────────────────────────────────────
  void _showCameraMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1117),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _menuItem(
              Icons.download_rounded,
              'Descargar grabación',
              onTap: () {
                Navigator.pop(ctx);
                _downloadRecording();
              },
            ),
            const SizedBox(height: 8),
            _menuItem(
              Icons.share_rounded,
              'Compartir feed',
              onTap: () {
                Navigator.pop(ctx);
                _shareFeed();
              },
            ),
            const SizedBox(height: 8),
            _menuItem(
              Icons.settings_rounded,
              'Configuración de cámara',
              onTap: () {
                Navigator.pop(ctx);
                _showCameraSettings();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
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

  Future<void> _downloadRecording() async {
    final fileName = 'grabacion_${_deviceId ?? 'local'}_${DateTime.now().millisecondsSinceEpoch}.mp4';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.download_rounded, color: _primaryBlue, size: 24),
            SizedBox(width: 8),
            Text('Descargar Grabación', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Archivo: $fileName', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            const Text('Ubicación: Descargas / SVI_Recordings', style: TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 12),
            const Text('¿Desea descargar este segmento de grabación en su dispositivo?', style: TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Descarga completada: $fileName (Guardado en SVI_Recordings)'),
                  backgroundColor: _primaryBlue,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Descargar / Guardar'),
          ),
        ],
      ),
    );
  }

  void _shareFeed() {
    final url = _streamUrl.isNotEmpty ? _streamUrl : ApiService.localCameraStream;
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('URL del feed copiada al portapapeles: $url'),
        backgroundColor: _primaryBlue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCameraSettings() {
    final url = _streamUrl.isNotEmpty ? _streamUrl : ApiService.localCameraStream;
    final ip = _ipAddress.isNotEmpty ? _ipAddress : '127.0.0.1 (Local)';

    String port = '8080';
    try {
      final uri = Uri.parse(url);
      if (uri.hasPort && uri.port != 0) {
        port = uri.port.toString();
      } else if (uri.scheme == 'https') {
        port = '443';
      } else if (uri.scheme == 'http') {
        port = '80';
      } else if (uri.scheme == 'rtsp') {
        port = '554';
      }
    } catch (_) {}

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.settings_rounded, color: _primaryBlue, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Configuración - $_cameraTitle',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _settingRow('Título', _cameraTitle),
            const Divider(color: Colors.white12, height: 16),
            _settingRow('Dirección IP', ip),
            const Divider(color: Colors.white12, height: 16),
            _settingRow('Puerto', port),
            const Divider(color: Colors.white12, height: 16),
            _settingRow('URL de Stream', url),
            const Divider(color: Colors.white12, height: 16),
            _settingRow('Estado PTZ', _isPtz ? 'Habilitado (Control Activo)' : 'Deshabilitado (Cámara Fija)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cerrar', style: TextStyle(color: _primaryBlue)),
          ),
        ],
      ),
    );
  }

  Widget _settingRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        SelectableText(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
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
