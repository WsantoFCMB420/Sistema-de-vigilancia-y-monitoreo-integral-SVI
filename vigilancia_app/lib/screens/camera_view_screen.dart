import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../main.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/local_camera_preview.dart';
import '../widgets/recordings_sheet.dart';
import '../widgets/app_shell.dart';
import '../widgets/theme_toggle_button.dart';

class CameraViewScreen extends StatefulWidget {
  final String cameraId;
  final String cameraName;

  const CameraViewScreen({
    super.key,
    this.cameraId = '',
    this.cameraName = '',
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

  // Grabación de clips (solo cámara local: webcam o celular)
  static const int _maxRecordSeconds = 60;
  bool _isRecording = false;
  bool _uploading = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
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

  /// true cuando el usuario ya eligió una cámara (o llegó con una desde otro módulo).
  bool _hasSelection = false;

  /// true si la cámara pedida no pertenece al usuario (no está en su lista).
  bool _accessDenied = false;

  /// true cuando ya se consultó la lista de cámaras del usuario.
  bool _camerasLoaded = false;

  bool get _showingFeed => _hasSelection && !_accessDenied;

  @override
  void initState() {
    super.initState();
    _loadAvailableCameras();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    super.dispose();
  }

  // ── Grabación ────────────────────────────────────────────────────────────
  Future<void> _toggleRecording() async {
    if (_uploading) return;
    if (_isRecording) {
      await _stopAndUpload();
      return;
    }
    if (!_useLocalCamera) {
      showAppSnackBar(context,
          'Las cámaras IP (RTSP) no se pueden grabar desde la app; solo la cámara de este equipo o del celular.',
          backgroundColor: Colors.orange);
      return;
    }
    final preview = _previewKey.currentState;
    if (preview == null || !preview.canRecord) {
      showAppSnackBar(context, 'Este navegador o dispositivo no permite grabar video.',
          backgroundColor: Colors.orange);
      return;
    }
    try {
      await preview.startRecording();
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordSeconds++);
        if (_recordSeconds >= _maxRecordSeconds) _stopAndUpload();
      });
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'No se pudo iniciar la grabación: $e', backgroundColor: _dangerColor);
    }
  }

  Future<void> _stopAndUpload() async {
    _recordTimer?.cancel();
    _recordTimer = null;
    if (!_isRecording) return;
    setState(() {
      _isRecording = false;
      _uploading = true;
    });
    try {
      final clip = await _previewKey.currentState?.stopRecording();
      if (clip == null || clip.bytes.isEmpty) {
        throw Exception('No se obtuvo video de la cámara');
      }
      await ApiService.uploadRecording(
        bytes: clip.bytes,
        extension: clip.extension,
        deviceId: _deviceId,
        durationSeconds: clip.duration.inSeconds,
      );
      if (!mounted) return;
      showAppSnackBar(context, 'Grabación guardada (${clip.duration.inSeconds} s)',
          icon: Icons.check_circle_rounded);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.toString().replaceFirst('Exception: ', ''), backgroundColor: _dangerColor);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _loadAvailableCameras() async {
    try {
      final devices = await ApiService.getDevices();
      if (!mounted) return;
      setState(() {
        _availableCameras = devices;
        _camerasLoaded = true;
        if (_deviceId != null) {
          final idx = _availableCameras.indexWhere((d) => '${d['id']}' == '$_deviceId');
          if (idx < 0) {
            // La API solo devuelve los dispositivos del usuario (o todos si es admin).
            // Si no está en la lista, el usuario no tiene acceso a esa cámara.
            _accessDenied = true;
            _currentCameraIndex = 0;
          } else {
            _accessDenied = false;
            _currentCameraIndex = idx;
            final d = _availableCameras[idx];
            _cameraTitle = (d['title'] ?? _cameraTitle).toString();
            _streamUrl = (d['stream_url'] ?? '').toString();
            _ipAddress = (d['ip_address'] ?? '').toString();
            _isPtz = d['is_ptz'] == true || d['is_ptz'] == 1;
          }
        }
      });
      // Sin cámara elegida: abre el selector solo si el usuario tiene cámaras.
      if (!_hasSelection && devices.isNotEmpty) _showCameraSelectionGrid();
    } catch (_) {
      if (mounted) setState(() => _camerasLoaded = true);
    }
  }

  bool _blockedByRecording() {
    if (!_isRecording && !_uploading) return false;
    showAppSnackBar(context, 'Termina la grabación antes de cambiar de cámara.',
        backgroundColor: Colors.orange);
    return true;
  }

  void _nextCamera() {
    if (_blockedByRecording()) return;
    if (_availableCameras.isEmpty) {
      showAppSnackBar(context, 'No hay más cámaras registradas',
          backgroundColor: Colors.orange);
      return;
    }
    setState(() {
      _currentCameraIndex =
          (_currentCameraIndex + 1) % _availableCameras.length;
      final d = _availableCameras[_currentCameraIndex];
      _deviceId =
          d['id'] is int ? d['id'] : int.tryParse(d['id']?.toString() ?? '');
      _cameraTitle = (d['title'] ?? d['name'] ?? 'Cámara').toString();
      _streamUrl = d['stream_url'] ?? '';
      _ipAddress = d['ip_address'] ?? '';
      _isPtz = d['is_ptz'] == true || d['is_ptz'] == 1;
      _hasSelection = true;
      _accessDenied = false;
    });
    showAppSnackBar(context, 'Cambiando a: $_cameraTitle',
        backgroundColor: _primaryBlue);
  }

  bool get _useLocalCamera =>
      _hasSelection &&
      !_accessDenied &&
      (_streamUrl.isEmpty || ApiService.isLocalCamera(_streamUrl));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _deviceId = args['id'] is int
            ? args['id']
            : int.tryParse(args['id']?.toString() ?? '');
        _cameraTitle =
            (args['title'] ?? args['name'] ?? widget.cameraName).toString();
        _streamUrl = args['stream_url'] ?? '';
        _ipAddress = args['ip_address'] ?? '';
        _isPtz = args['is_ptz'] == true || args['is_ptz'] == 1;
        _hasSelection = true;
      } else if (widget.cameraName.isNotEmpty) {
        _cameraTitle = widget.cameraName;
        _streamUrl = ApiService.localCameraStream;
        _ipAddress = 'dispositivo-local';
        _isPtz = false;
        _hasSelection = true;
      } else {
        // Sin cámara elegida: no se abre ninguna fuente hasta que el usuario
        // escoja una de SUS cámaras.
        _cameraTitle = 'Selecciona una cámara';
        _streamUrl = '';
        _ipAddress = '';
        _isPtz = false;
        _hasSelection = false;
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
      showAppSnackBar(context, 'Error PTZ: $e', backgroundColor: _dangerColor);
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
            if (_showingFeed) _buildDetectionCards(),
            // El área de video siempre es oscura (como un reproductor),
            // así el texto se lee igual en modo claro y oscuro.
            Expanded(
              child: ColoredBox(
                color: const Color(0xFF0D1117),
                child: _buildCameraFeed(),
              ),
            ),
            if (_showingFeed) _buildControls(),
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
          const AppMenuButton(),
          const SizedBox(width: 6),
          Expanded(
            child: InkWell(
              onTap: _showCameraSelectionGrid,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _deviceId != null
                                ? '#$_deviceId - $_cameraTitle'
                                : _cameraTitle,
                            style: TextStyle(
                              color: _c.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down_rounded,
                            color: _c.text, size: 20),
                      ],
                    ),
                    if (_showingFeed) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _chip('LIVE', const Color(0xFFE53935)),
                        const SizedBox(width: 6),
                        _chip(
                            _ipAddress.isNotEmpty ? _ipAddress : 'WEBCAM / USB',
                            const Color(0xFF1A5DC8)),
                        const SizedBox(width: 6),
                        if (_isPtz)
                          _chip('PTZ ACTIVO', const Color(0xFF00897B))
                        else
                          _chip('FIJA', const Color(0xFF6B7A99)),
                      ],
                    ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Selector de cámaras / siguiente / indicador REC
          if (isWideLayout(context))
            FilledButton.tonalIcon(
              onPressed: _showCameraSelectionGrid,
              icon: const Icon(Icons.grid_view_rounded, size: 18),
              label: const Text('Mis cámaras'),
            )
          else
            IconButton(
              tooltip: 'Mis cámaras',
              onPressed: _showCameraSelectionGrid,
              icon: const Icon(Icons.grid_view_rounded, color: _primaryBlue),
            ),
          IconButton(
            tooltip: 'Grabaciones',
            onPressed: _showRecordings,
            icon: const Icon(Icons.video_library_rounded, color: _primaryBlue),
          ),
          if (_showingFeed && _availableCameras.length > 1) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Siguiente cámara',
              onPressed: _nextCamera,
              icon: const Icon(Icons.skip_next_rounded, color: _primaryBlue),
            ),
          ],
          if (_showingFeed) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _dangerColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 6),
                  SizedBox(width: 4),
                  Text('EN VIVO',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
          const SizedBox(width: 4),
          const ThemeToggleButton(),
          const SizedBox(width: 4),
          const ProfileMenuButton(),
          IconButton(
            tooltip: 'Más opciones',
            icon: Icon(
              Icons.more_vert_rounded,
              color: _c.text,
              size: 20,
            ),
            onPressed: () => _showCameraMenu(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() => const AppDrawer(currentRoute: AppRoutes.cameraView);

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
        border:
            Border.all(color: iconColor.withValues(alpha: 0.25), width: 0.8),
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
    if (!_hasSelection || _accessDenied) {
      final noCameras = _camerasLoaded && _availableCameras.isEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _accessDenied ? Icons.lock_rounded : Icons.videocam_outlined,
                color: Colors.white38,
                size: 52,
              ),
              const SizedBox(height: 4),
              const SizedBox(height: 12),
              Text(
                _accessDenied
                    ? 'No tienes acceso a esta cámara'
                    : (noCameras ? 'Aún no tienes cámaras registradas' : 'Elige una cámara'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                _accessDenied
                    ? 'Solo puedes ver las cámaras que registraste.'
                    : (noCameras
                        ? 'Registra una cámara en Dispositivos para verla aquí en vivo.'
                        : 'Selecciona una de tus cámaras para ver la transmisión.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 18),
              if (!_camerasLoaded)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white70),
                )
              else if (noCameras)
                FilledButton.icon(
                  onPressed: () => navigateToModule(context, AppRoutes.devices),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Registrar dispositivo'),
                )
              else
                FilledButton.icon(
                  onPressed: _showCameraSelectionGrid,
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('Mis cámaras'),
                ),
            ],
          ),
        ),
      );
    }
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
            const Icon(Icons.videocam_off_rounded,
                color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(
              'Esta cámara de red no se puede previsualizar aquí:\n$_streamUrl',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _deviceId = null;
                  _cameraTitle = 'Cámara de este equipo';
                  _streamUrl = ApiService.localCameraStream;
                  _ipAddress = 'dispositivo-local';
                  _isPtz = false;
                  _hasSelection = true;
                  _accessDenied = false;
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
      showAppSnackBar(
        context,
        'La captura solo está disponible en la cámara local.',
        backgroundColor: Colors.orange,
      );
      return;
    }
    try {
      final file = await _previewKey.currentState?.takePicture();
      if (!mounted) return;
      if (file == null) {
        showAppSnackBar(
          context,
          'No se pudo capturar la imagen.',
          backgroundColor: _dangerColor,
        );
        return;
      }
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0D1117),
          title: const Text('Captura guardada',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!kIsWeb)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(file.path),
                      height: 180, fit: BoxFit.cover),
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
      showAppSnackBar(
        context,
        'Error al capturar: $e',
        backgroundColor: _dangerColor,
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
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        if (_isPtz && !_useLocalCamera)
          Positioned(right: 20, bottom: 60, child: _buildPTZJoystick()),
        if (_showingFeed)
        Positioned(
          bottom: 8,
          left: 12,
          child: Text(
            '${TimeOfDay.now().format(context)} EN VIVO (Zoom: ${_zoom.toStringAsFixed(1)}x)',
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
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.8),
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
              child: const Icon(Icons.pan_tool_rounded,
                  color: Colors.white, size: 14),
            ),
          ),
          // Flechas
          Positioned(
              top: 8,
              child: _ptzArrow(
                  Icons.keyboard_arrow_up_rounded, () => _sendPTZ('up'))),
          Positioned(
            bottom: 8,
            child: _ptzArrow(
                Icons.keyboard_arrow_down_rounded, () => _sendPTZ('down')),
          ),
          Positioned(
            left: 8,
            child: _ptzArrow(
                Icons.keyboard_arrow_left_rounded, () => _sendPTZ('left')),
          ),
          Positioned(
            right: 8,
            child: _ptzArrow(
                Icons.keyboard_arrow_right_rounded, () => _sendPTZ('right')),
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
          _buildRecordButton(),
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
          _controlBtn(Icons.notifications_active_rounded,
              onTap: _showAlarmDialog),
        ],
      ),
    );
  }

  Widget _buildRecordButton() {
    final label = _uploading
        ? 'Subiendo…'
        : (_isRecording
            ? '${(_recordSeconds ~/ 60).toString().padLeft(2, '0')}:${(_recordSeconds % 60).toString().padLeft(2, '0')}'
            : 'Grabar');
    return Tooltip(
      message: _isRecording ? 'Detener y guardar' : 'Grabar clip (máx. 60 s)',
      child: InkWell(
        onTap: _uploading ? null : _toggleRecording,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isRecording ? _dangerColor : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_uploading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else
                Icon(
                  _isRecording ? Icons.stop_rounded : Icons.fiber_manual_record_rounded,
                  color: _isRecording ? Colors.white : _dangerColor,
                  size: 18,
                ),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
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


  // ── Acciones ──────────────────────────────────────────────────────────────
  void _showAlarmDialog() {
    int selectedTypeIndex = 0;
    String selectedPriority = 'Crítica';
    final descController = TextEditingController(
        text: 'Alerta generada desde cámara: $_cameraTitle');
    final locationController = TextEditingController(text: _cameraTitle);
    bool shareToChat = true;

    final types = [
      {
        'label': 'Seguridad',
        'icon': Icons.shield_rounded,
        'color': const Color(0xFF1A5DC8)
      },
      {
        'label': 'Incendio',
        'icon': Icons.local_fire_department_rounded,
        'color': const Color(0xFFFF6D00)
      },
      {
        'label': 'Médico',
        'icon': Icons.medical_services_rounded,
        'color': const Color(0xFF43A047)
      },
      {
        'label': 'Técnico',
        'icon': Icons.engineering_rounded,
        'color': const Color(0xFF7B1FA2)
      },
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
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
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
                const Text('TIPO DE INCIDENTE',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: selected ? color : Colors.white12,
                              width: selected ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            Icon(t['icon'] as IconData,
                                color: selected ? color : Colors.white60,
                                size: 18),
                            const SizedBox(width: 8),
                            Text(t['label'] as String,
                                style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text('PRIORIDAD',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: priorities.map((p) {
                    final selected = selectedPriority == p;
                    final color = p == 'Crítica'
                        ? const Color(0xFFE53935)
                        : (p == 'Media'
                            ? const Color(0xFFFFA000)
                            : const Color(0xFF43A047));
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedPriority = p),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: selected ? color : Colors.white12,
                                width: selected ? 2 : 1),
                          ),
                          child: Text(p,
                              style: TextStyle(
                                  color:
                                      selected ? Colors.white : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('UBICACIÓN',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: locationController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('DESCRIPCIÓN',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Compartir en chat de comunicación',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    Switch(
                      value: shareToChat,
                      activeThumbColor: const Color(0xFF1A5DC8),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                          shareToChat: shareToChat,
                        );
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF0D1117),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            title: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    color: Color(0xFF43A047), size: 24),
                                SizedBox(width: 8),
                                Text('Alerta Emitida',
                                    style: TextStyle(color: Colors.white)),
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
                        showAppSnackBar(
                          context,
                          'Error al emitir alerta: $e',
                          backgroundColor: Colors.redAccent,
                        );
                      }
                    },
                    child: const Text('EMITIR ALERTA',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Modal Grid de Selección de Cámaras ──────────────────────────────────────
  void _showCameraSelectionGrid() async {
    if (_availableCameras.isEmpty) {
      try {
        final devices = await ApiService.getDevices();
        if (mounted) {
          setState(() {
            _availableCameras = devices;
          });
        }
      } catch (_) {}
    }

    if (!mounted) return;
    if (_availableCameras.isEmpty) {
      showAppSnackBar(context, 'Aún no tienes cámaras registradas. Agrégalas en Dispositivos.',
          backgroundColor: Colors.orange);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: _c.card,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _primaryBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.grid_view_rounded,
                              color: _primaryBlue, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Seleccionar Cámara',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _c.text,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: _c.label),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_availableCameras.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No hay cámaras registradas',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: _availableCameras.length,
                      itemBuilder: (context, index) {
                        final camera = _availableCameras[index];
                        final isSelected = camera['id'] == _deviceId;
                        final title = (camera['title'] ??
                                camera['name'] ??
                                'Cámara ${index + 1}')
                            .toString();
                        final ip = (camera['ip_address'] ?? '').toString();
                        final isPtz =
                            camera['is_ptz'] == true || camera['is_ptz'] == 1;

                        return InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            _selectCamera(camera, index);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primaryBlue.withValues(alpha: 0.15)
                                  : _c.input,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? _primaryBlue : _c.border,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: isSelected
                                          ? _primaryBlue
                                          : _primaryBlue.withValues(
                                              alpha: 0.12),
                                      child: Icon(
                                        Icons.videocam_rounded,
                                        size: 16,
                                        color: isSelected
                                            ? Colors.white
                                            : _primaryBlue,
                                      ),
                                    ),
                                    if (isPtz)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00897B)
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'PTZ',
                                          style: TextStyle(
                                            color: Color(0xFF00897B),
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _c.text,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  ip.isNotEmpty ? ip : 'Local / USB',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _c.label,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _selectCamera(dynamic camera, int index) {
    if (_blockedByRecording()) return;
    setState(() {
      _currentCameraIndex = index;
      _deviceId = camera['id'] is int
          ? camera['id']
          : int.tryParse(camera['id']?.toString() ?? '');
      _cameraTitle = (camera['title'] ?? camera['name'] ?? 'Cámara').toString();
      _streamUrl = camera['stream_url'] ?? '';
      _ipAddress = camera['ip_address'] ?? '';
      _isPtz = camera['is_ptz'] == true || camera['is_ptz'] == 1;
      _hasSelection = true;
      _accessDenied = false;
    });
    showAppSnackBar(
      context,
      'Cámara seleccionada: $_cameraTitle',
      backgroundColor: _primaryBlue,
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
              Icons.video_library_rounded,
              'Ver grabaciones',
              onTap: () {
                Navigator.pop(ctx);
                _showRecordings();
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

  /// Grabaciones de la cámara. Aquí (y no en la vista en vivo) va la línea de
  /// tiempo para adelantar o retroceder, porque solo aplica a video grabado.
  void _showRecordings() {
    RecordingsSheet.show(
      context,
      deviceId: _deviceId,
      title: _deviceId != null ? _cameraTitle : 'Todas mis grabaciones',
    );
  }

  void _shareFeed() {
    final url =
        _streamUrl.isNotEmpty ? _streamUrl : ApiService.localCameraStream;
    Clipboard.setData(ClipboardData(text: url));
    showAppSnackBar(
      context,
      'URL del feed copiada al portapapeles: $url',
      backgroundColor: _primaryBlue,
    );
  }

  void _showCameraSettings() {
    final url =
        _streamUrl.isNotEmpty ? _streamUrl : ApiService.localCameraStream;
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
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
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
            _settingRow(
                'Estado PTZ',
                _isPtz
                    ? 'Habilitado (Control Activo)'
                    : 'Deshabilitado (Cámara Fija)'),
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
          style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
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

