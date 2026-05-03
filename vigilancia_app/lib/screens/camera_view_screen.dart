import 'package:flutter/material.dart';

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
  static const Color _labelColor = Color(0xFF6B7A99);
  static const Color _dangerColor = Color(0xFFE53935);
  static const Color _cardColor = Colors.white;
  static const Color _bgColor = Color(0xFFDDE8F5);

  bool _isPlaying = true;
  bool _isMuted = false;
  double _timeline = 0.72; // posición del scrubber

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
      color: const Color(0xFF0D1117),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Camera ${widget.cameraId} - ${widget.cameraName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _chip('LIVE', const Color(0xFFE53935)),
                    const SizedBox(width: 6),
                    _chip('4K ULTRA HD', const Color(0xFF1A5DC8)),
                    const SizedBox(width: 6),
                    _chip('60 FPS', const Color(0xFF43A047)),
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

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
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
              label: 'DETECTIONS',
              icon: Icons.person_rounded,
              value: '2 Humans detected',
              iconColor: _primaryBlue,
              bgColor: _primaryBlue.withOpacity(0.12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _infoCard(
              label: 'NETWORK',
              icon: Icons.network_check_rounded,
              value: 'Latency: 12ms',
              iconColor: const Color(0xFF43A047),
              bgColor: const Color(0xFF43A047).withOpacity(0.12),
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
        border: Border.all(color: iconColor.withOpacity(0.25), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: iconColor.withOpacity(0.8),
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

  // ── Feed de la cámara con joystick PTZ y botón ALARM ─────────────────────
  Widget _buildCameraFeed() {
    return Stack(
      children: [
        // Fondo del video
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A1628), Color(0xFF0D1B2A), Color(0xFF0A1220)],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.videocam_rounded,
              color: Color(0xFF1A3A5C),
              size: 60,
            ),
          ),
        ),
        // Efecto de luces (simulado)
        Positioned(
          top: 30,
          left: 40,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 25,
          right: 60,
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        ),
        // Indicador de personas detectadas (bounding box simulado)
        Positioned(
          left: 60,
          top: 50,
          child: Container(
            width: 28,
            height: 55,
            decoration: BoxDecoration(
              border: Border.all(color: _primaryBlue, width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                color: _primaryBlue,
                child: const Text(
                  'H1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 80,
          top: 45,
          child: Container(
            width: 24,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: _primaryBlue, width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                color: _primaryBlue,
                child: const Text(
                  'H2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Joystick PTZ (centro-derecha)
        Positioned(right: 20, bottom: 60, child: _buildPTZJoystick()),
        // Botón ALARM
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
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _dangerColor.withOpacity(0.5),
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
        // Timestamp
        Positioned(
          bottom: 8,
          left: 12,
          child: Text(
            '20:04:14 LIVE',
            style: TextStyle(
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
        color: Colors.black.withOpacity(0.55),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centro
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
          // Flechas
          Positioned(top: 8, child: _ptzArrow(Icons.keyboard_arrow_up_rounded)),
          Positioned(
            bottom: 8,
            child: _ptzArrow(Icons.keyboard_arrow_down_rounded),
          ),
          Positioned(
            left: 8,
            child: _ptzArrow(Icons.keyboard_arrow_left_rounded),
          ),
          Positioned(
            right: 8,
            child: _ptzArrow(Icons.keyboard_arrow_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget _ptzArrow(IconData icon) {
    return GestureDetector(
      onTap: () {},
      child: Icon(icon, color: Colors.white.withOpacity(0.85), size: 26),
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
          _controlBtn(Icons.camera_alt_rounded, onTap: () {}),
          _controlBtn(Icons.replay_10_rounded, onTap: () {}),
          // Pause/Play — destacado
          GestureDetector(
            onTap: () => setState(() => _isPlaying = !_isPlaying),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
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
          _controlBtn(Icons.forward_10_rounded, onTap: () {}),
          _controlBtn(Icons.zoom_in_rounded, onTap: () {}),
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
          color: Colors.white.withOpacity(0.08),
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
              inactiveTrackColor: Colors.white.withOpacity(0.15),
              thumbColor: _primaryBlue,
              overlayColor: _primaryBlue.withOpacity(0.2),
            ),
            child: Slider(
              value: _timeline,
              onChanged: (v) => setState(() => _timeline = v),
            ),
          ),
          // Timestamps
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
            const Text(
              'Emitir Alerta',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _alarmOption(
              Icons.warning_amber_rounded,
              'Intrusión',
              const Color(0xFFE53935),
            ),
            const SizedBox(height: 8),
            _alarmOption(
              Icons.local_fire_department_rounded,
              'Emergencia',
              const Color(0xFFFF6D00),
            ),
            const SizedBox(height: 8),
            _alarmOption(
              Icons.info_rounded,
              'Aviso General',
              const Color(0xFF1A5DC8),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _alarmOption(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
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
          color: Colors.white.withOpacity(0.06),
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
