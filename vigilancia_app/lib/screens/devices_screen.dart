import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/device_card.dart';
import '../widgets/responsive.dart';
import '../widgets/app_shell.dart';
import '../main.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});
  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  List<dynamic> _devices = [];
  bool _loading = true;
  String? _error;
  bool _isGridMode = true; // true = Mosaico (Grid), false = Lista (List)

  static const Color _primaryBlue = Color(0xFF1A5DC8);
  static const Color _dangerColor = Color(0xFFE53935);

  AppColors get _c => AppColors.of(context);

  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    SessionService.isAdmin().then((v) {
      if (mounted) setState(() => _isAdmin = v);
    });
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() { _loading = true; _error = null; });
    try {
      final devices = await ApiService.getDevices();
      if (!mounted) return;
      setState(() { _devices = devices; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String? _validateNewDevice({
    required String name,
    required String location,
    required String type,
    required String cameraSource,
    required String streamUrl,
    required String ip,
  }) {
    if (name.isEmpty) return 'Ingresa un nombre para el dispositivo.';
    if (location.isEmpty) return 'Ingresa la ubicación o descripción.';
    if (type == 'camera' && cameraSource == 'local') return null;
    if (type == 'camera') {
      if (streamUrl.isEmpty) {
        return 'Indica la URL del stream (RTSP/HTTP) o usa la cámara de este dispositivo.';
      }
      final uri = Uri.tryParse(streamUrl);
      final scheme = uri?.scheme.toLowerCase() ?? '';
      if (uri == null || !['rtsp', 'rtsps', 'http', 'https'].contains(scheme)) {
        return 'La URL debe comenzar por rtsp://, http:// o https://.';
      }
      if (ip.isEmpty) return 'Ingresa la dirección IP o host de la cámara de red.';
    }
    return null;
  }

  // ── Agregar dispositivo ────────────────────────────────────────
  void _showAddDeviceDialog() {
    final titleCtrl     = TextEditingController();
    final subtitleCtrl  = TextEditingController();
    final streamUrlCtrl = TextEditingController();
    final ipCtrl        = TextEditingController();
    final portCtrl      = TextEditingController(text: '554');
    final latCtrl       = TextEditingController(text: '5.3114');
    final lngCtrl       = TextEditingController(text: '-73.8155');
    String selectedStatus = 'Activo';
    String selectedType   = 'camera';
    String cameraSource   = 'local';
    bool isPtz = false;
    bool saving = false;
    String? formError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: BoxDecoration(
            color: _c.sheet,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            24, 20, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.videocam_rounded, color: _primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('Nuevo Dispositivo / Cámara',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _c.text)),
                ]),
                const SizedBox(height: 18),

                Text('NOMBRE DEL DISPOSITIVO *',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: _c.label, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  style: TextStyle(fontSize: 14, color: _c.text),
                  decoration: _inputDeco('Ej: Cámara Perimetral Norte 01'),
                ),
                const SizedBox(height: 14),

                Text('TIPO DE DISPOSITIVO *',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: _c.label, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _c.input,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _c.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: DropdownButton<String>(
                    value: selectedType,
                    isExpanded: true,
                    dropdownColor: _c.card,
                    underline: const SizedBox(),
                    style: TextStyle(fontSize: 14, color: _c.text),
                    items: const [
                      DropdownMenuItem(value: 'camera', child: Text('Cámara de Vigilancia')),
                      DropdownMenuItem(value: 'sensor', child: Text('Sensor de Movimiento / Intrusión')),
                      DropdownMenuItem(value: 'alarm', child: Text('Alarma / Sirena')),
                      DropdownMenuItem(value: 'access', child: Text('Control de Acceso / Puerta')),
                    ],
                    onChanged: (v) => setSheet(() => selectedType = v!),
                  ),
                ),
                const SizedBox(height: 14),

                if (selectedType == 'camera') ...[
                  Text('FUENTE DE VIDEO *',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: _c.label, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _sourceChip(
                          selected: cameraSource == 'local',
                          icon: Icons.videocam_rounded,
                          label: 'Webcam / USB',
                          onTap: () => setSheet(() => cameraSource = 'local'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _sourceChip(
                          selected: cameraSource == 'network',
                          icon: Icons.lan_rounded,
                          label: 'Cámara de red',
                          onTap: () => setSheet(() => cameraSource = 'network'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (cameraSource == 'local')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _primaryBlue.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        'Usará la webcam del portátil o una cámara USB conectada a este equipo.',
                        style: TextStyle(fontSize: 12, color: _c.text, height: 1.35),
                      ),
                    )
                  else ...[
                    Text('URL DEL STREAM (RTSP / HTTP) *',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: _c.label, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: streamUrlCtrl,
                      style: TextStyle(fontSize: 13, color: _c.text),
                      decoration: _inputDeco('rtsp://192.168.1.100:554/live/ch0'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('DIRECCIÓN IP *',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                      color: _c.label, letterSpacing: 0.8)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: ipCtrl,
                                style: TextStyle(fontSize: 13, color: _c.text),
                                decoration: _inputDeco('192.168.1.100'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PUERTO',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                      color: _c.label, letterSpacing: 0.8)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: portCtrl,
                                keyboardType: TextInputType.number,
                                style: TextStyle(fontSize: 13, color: _c.text),
                                decoration: _inputDeco('554'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _c.input,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _c.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.gamepad_rounded, color: _primaryBlue, size: 20),
                            const SizedBox(width: 10),
                            Text('Soporte Pan-Tilt-Zoom (PTZ)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _c.text)),
                          ],
                        ),
                        Switch(
                          value: isPtz,
                          activeThumbColor: _primaryBlue,
                          onChanged: (v) => setSheet(() => isPtz = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                Text('UBICACIÓN / DESCRIPCIÓN *',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: _c.label, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                TextField(
                  controller: subtitleCtrl,
                  style: TextStyle(fontSize: 14, color: _c.text),
                  decoration: _inputDeco('Ej: Sector A, Puerta Principal'),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LATITUD',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                  color: _c.label, letterSpacing: 0.8)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: latCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            style: TextStyle(fontSize: 13, color: _c.text),
                            decoration: _inputDeco('5.3114'),
                            onChanged: (_) => setSheet(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LONGITUD',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                  color: _c.label, letterSpacing: 0.8)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: lngCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            style: TextStyle(fontSize: 13, color: _c.text),
                            decoration: _inputDeco('-73.8155'),
                            onChanged: (_) => setSheet(() {}),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildMiniMapLocationPicker(
                  latCtrl: latCtrl,
                  lngCtrl: lngCtrl,
                  setSheet: setSheet,
                ),
                const SizedBox(height: 14),

                Text('ESTADO INICIAL',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: _c.label, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _c.input,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _c.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    dropdownColor: _c.card,
                    underline: const SizedBox(),
                    style: TextStyle(fontSize: 14, color: _c.text),
                    items: ['Activo', 'Inactivo', 'Mantenimiento']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setSheet(() => selectedStatus = v!),
                  ),
                ),
                if (formError != null) ...[
                  const SizedBox(height: 8),
                  Text(formError!, style: const TextStyle(color: _dangerColor, fontSize: 13)),
                ],
                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: saving ? null : () async {
                      final name = titleCtrl.text.trim();
                      final location = subtitleCtrl.text.trim();
                      final streamUrl = streamUrlCtrl.text.trim();
                      final ip = ipCtrl.text.trim();
                      final lat = double.tryParse(latCtrl.text.trim());
                      final lng = double.tryParse(lngCtrl.text.trim());
                      final error = _validateNewDevice(
                        name: name,
                        location: location,
                        type: selectedType,
                        cameraSource: cameraSource,
                        streamUrl: streamUrl,
                        ip: ip,
                      );
                      if (error != null) {
                        setSheet(() => formError = error);
                        return;
                      }
                      setSheet(() { saving = true; formError = null; });
                      try {
                        final isLocalCamera = selectedType == 'camera' && cameraSource == 'local';
                        final portParsed = isLocalCamera ? null : int.tryParse(portCtrl.text.trim());
                        await ApiService.addDevice(
                          title: name,
                          subtitle: location,
                          status: selectedStatus,
                          streamUrl: isLocalCamera ? ApiService.localCameraStream : streamUrl,
                          ipAddress: isLocalCamera ? 'dispositivo-local' : ip,
                          port: portParsed,
                          isPtz: isLocalCamera ? false : isPtz,
                          deviceType: selectedType,
                          latitude: lat,
                          longitude: lng,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _loadDevices();
                        showAppSnackBar(
                          context,
                          'Dispositivo registrado correctamente',
                          backgroundColor: const Color(0xFF1A5DC8),
                        );
                      } catch (e) {
                        setSheet(() => saving = false);
                        showAppSnackBar(
                          context,
                          'Error: $e',
                          backgroundColor: Colors.redAccent,
                        );
                      }
                    },
                    icon: saving
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(saving ? 'Guardando...' : 'Guardar Dispositivo',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMapLocationPicker({
    required TextEditingController latCtrl,
    required TextEditingController lngCtrl,
    required StateSetter setSheet,
  }) {
    final double initialLat = double.tryParse(latCtrl.text.trim()) ?? 5.3114;
    final double initialLng = double.tryParse(lngCtrl.text.trim()) ?? -73.8155;
    final currentPoint = LatLng(initialLat, initialLng);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UBICACIÓN EN EL MAPA (Toca para colocar pin)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _c.label,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: currentPoint,
              initialZoom: 14.0,
              onTap: (tapPosition, point) {
                setSheet(() {
                  latCtrl.text = point.latitude.toStringAsFixed(6);
                  lngCtrl.text = point.longitude.toStringAsFixed(6);
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.svi.vigilancia',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentPoint,
                    width: 36,
                    height: 36,
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFFE53935),
                      size: 34,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Editar dispositivo ─────────────────────────────────────────
  void _showEditDeviceDialog(dynamic device) {
    final titleCtrl     = TextEditingController(text: device['title'] ?? '');
    final subtitleCtrl  = TextEditingController(text: device['subtitle'] ?? '');
    final streamUrlCtrl = TextEditingController(text: device['stream_url'] ?? '');
    final ipCtrl        = TextEditingController(text: device['ip_address'] ?? '');
    final portCtrl      = TextEditingController(text: '${device['port'] ?? 554}');

    final double? devLat = device['latitude'] is num
        ? (device['latitude'] as num).toDouble()
        : double.tryParse(device['latitude']?.toString() ?? '');
    final double? devLng = device['longitude'] is num
        ? (device['longitude'] as num).toDouble()
        : double.tryParse(device['longitude']?.toString() ?? '');

    final latCtrl       = TextEditingController(text: devLat != null ? '$devLat' : '5.3114');
    final lngCtrl       = TextEditingController(text: devLng != null ? '$devLng' : '-73.8155');

    String selectedStatus = device['status'] ?? 'Activo';
    String selectedType   = device['device_type'] ?? 'camera';
    bool isPtz = device['is_ptz'] == true || device['is_ptz'] == 1;
    bool saving = false;
    String? formError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: BoxDecoration(
            color: _c.sheet,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            24, 20, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_rounded, color: _primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('Editar Dispositivo',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _c.text)),
                ]),
                const SizedBox(height: 18),

                Text('NOMBRE DEL DISPOSITIVO *',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: _c.label, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  style: TextStyle(fontSize: 14, color: _c.text),
                  decoration: _inputDeco('Ej: Cámara Perimetral Norte 01'),
                ),
                const SizedBox(height: 14),

                Text('UBICACIÓN / DESCRIPCIÓN *',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: _c.label, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                TextField(
                  controller: subtitleCtrl,
                  style: TextStyle(fontSize: 14, color: _c.text),
                  decoration: _inputDeco('Ej: Sector A, Puerta Principal'),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LATITUD',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                  color: _c.label, letterSpacing: 0.8)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: latCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            style: TextStyle(fontSize: 13, color: _c.text),
                            decoration: _inputDeco('5.3114'),
                            onChanged: (_) => setSheet(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LONGITUD',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                  color: _c.label, letterSpacing: 0.8)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: lngCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            style: TextStyle(fontSize: 13, color: _c.text),
                            decoration: _inputDeco('-73.8155'),
                            onChanged: (_) => setSheet(() {}),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildMiniMapLocationPicker(
                  latCtrl: latCtrl,
                  lngCtrl: lngCtrl,
                  setSheet: setSheet,
                ),
                const SizedBox(height: 14),

                if (selectedType == 'camera') ...[
                  Text('URL DEL STREAM (RTSP / HTTP)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: _c.label, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: streamUrlCtrl,
                    style: TextStyle(fontSize: 13, color: _c.text),
                    decoration: _inputDeco('rtsp://192.168.1.100:554/live/ch0'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DIRECCIÓN IP',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                    color: _c.label, letterSpacing: 0.8)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: ipCtrl,
                              style: TextStyle(fontSize: 13, color: _c.text),
                              decoration: _inputDeco('192.168.1.100'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PUERTO',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                    color: _c.label, letterSpacing: 0.8)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: portCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 13, color: _c.text),
                              decoration: _inputDeco('554'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _c.input,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _c.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.gamepad_rounded, color: _primaryBlue, size: 20),
                            const SizedBox(width: 10),
                            Text('Soporte Pan-Tilt-Zoom (PTZ)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _c.text)),
                          ],
                        ),
                        Switch(
                          value: isPtz,
                          activeThumbColor: _primaryBlue,
                          onChanged: (v) => setSheet(() => isPtz = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                Text('ESTADO',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: _c.label, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _c.input,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _c.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    dropdownColor: _c.card,
                    underline: const SizedBox(),
                    style: TextStyle(fontSize: 14, color: _c.text),
                    items: ['Activo', 'Inactivo', 'Mantenimiento']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setSheet(() => selectedStatus = v!),
                  ),
                ),
                if (formError != null) ...[
                  const SizedBox(height: 8),
                  Text(formError!, style: const TextStyle(color: _dangerColor, fontSize: 13)),
                ],
                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: saving ? null : () async {
                      final name = titleCtrl.text.trim();
                      if (name.isEmpty) {
                        setSheet(() => formError = 'Ingresa un nombre para el dispositivo.');
                        return;
                      }
                      setSheet(() { saving = true; formError = null; });
                      try {
                        final lat = double.tryParse(latCtrl.text.trim());
                        final lng = double.tryParse(lngCtrl.text.trim());
                        await ApiService.updateDevice(
                          device['id'],
                          title: name,
                          subtitle: subtitleCtrl.text.trim(),
                          status: selectedStatus,
                          streamUrl: streamUrlCtrl.text.trim(),
                          ipAddress: ipCtrl.text.trim(),
                          port: int.tryParse(portCtrl.text.trim()),
                          isPtz: isPtz,
                          deviceType: selectedType,
                          latitude: lat,
                          longitude: lng,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _loadDevices();
                        showAppSnackBar(
                          context,
                          'Dispositivo actualizado correctamente',
                          backgroundColor: const Color(0xFF1A5DC8),
                        );
                      } catch (e) {
                        setSheet(() => saving = false);
                        showAppSnackBar(
                          context,
                          'Error: $e',
                          backgroundColor: Colors.redAccent,
                        );
                      }
                    },
                    icon: saving
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(saving ? 'Guardando...' : 'Actualizar Dispositivo',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: _c.hint, fontSize: 14),
    filled: true,
    fillColor: _c.input,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _c.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _c.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryBlue, width: 1.5)),
  );

  Widget _sourceChip({
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? _primaryBlue.withValues(alpha: 0.12) : _c.input,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? _primaryBlue : _c.border, width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? _primaryBlue : _c.label),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? _primaryBlue : _c.text,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Eliminar dispositivo ───────────────────────────────────────
  Future<void> _deleteDevice(dynamic device) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar dispositivo',
            style: TextStyle(fontWeight: FontWeight.w700, color: _c.text)),
        content: Text('¿Eliminar "${device['title']}"? Esta acción no se puede deshacer.',
            style: TextStyle(color: _c.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: _c.label)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _dangerColor, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deleteDevice(device['id']);
      _loadDevices();
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Dispositivo eliminado',
        backgroundColor: const Color(0xFF1A5DC8),
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Error: $e',
        backgroundColor: Colors.redAccent,
      );
    }
  }

  Widget _buildDeviceItem(dynamic d, bool isMultiColumn) {
    return Dismissible(
      key: Key('device_${d['id']}'),
      direction: isMultiColumn
          ? DismissDirection.endToStart
          : DismissDirection.none,
      onDismissed: (_) => _deleteDevice(d),
      confirmDismiss: (_) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('¿Eliminar dispositivo?', style: TextStyle(fontWeight: FontWeight.w700)),
            content: Text('Se eliminará "${d['title']}" permanentemente.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: _dangerColor, foregroundColor: Colors.white),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _dangerColor,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text('Eliminar', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: DeviceCard(
        title:     d['title']    ?? '',
        subtitle:  d['subtitle'] ?? '',
        status:    d['status']   ?? 'Activo',
        imageUrl:  d['imageUrl'] ?? '',
        isPtz:     d['is_ptz'] == true || d['is_ptz'] == 1,
        streamUrl: d['stream_url'] ?? '',
        owner:     _isAdmin && d['is_mine'] != true ? d['owner_name']?.toString() : null,
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.cameraView,
            arguments: d,
          );
        },
        onDelete: () => _deleteDevice(d),
        onEdit: () => _showEditDeviceDialog(d),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _c.bg,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: ResponsiveShell(
          child: Column(
            children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: _buildTopBar(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildHeader(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: _dangerColor),
                              const SizedBox(height: 16),
                              Text(_error!, style: TextStyle(color: _c.label)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadDevices,
                                style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : _devices.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadDevices,
                              child: _isGridMode
                                  ? LayoutBuilder(
                                      builder: (ctx, constraints) {
                                        final columns = Breakpoints.deviceColumns(context);
                                        return GridView.builder(
                                          padding: const EdgeInsets.symmetric(horizontal: 20),
                                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: columns,
                                            mainAxisExtent: 104,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 4,
                                          ),
                                          itemCount: _devices.length,
                                          itemBuilder: (ctx, i) => _buildDeviceItem(_devices[i], columns > 1),
                                        );
                                      },
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      itemCount: _devices.length,
                                      itemBuilder: (ctx, i) => _buildDeviceItem(_devices[i], false),
                                    ),
                            ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _primaryBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.devices_rounded, color: _primaryBlue, size: 38),
          ),
          const SizedBox(height: 16),
          Text('Sin dispositivos registrados',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _c.text)),
          const SizedBox(height: 8),
          Text('Toca el botón + para agregar tu primer dispositivo',
              style: TextStyle(fontSize: 13, color: _c.label),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddDeviceDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Agregar Dispositivo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() => AppTopBar(
        title: 'Dispositivos',
        subtitle: _isAdmin ? 'Todos los dispositivos del sistema' : 'Cámaras y equipos que registraste',
        icon: Icons.devices_other_rounded,
      );

  Widget _buildHeader() {
    final active = _devices.where((d) => d['status'] == 'Activo').length;
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _countChip(Icons.devices_rounded, '${_devices.length} registrados', AppColors.primary),
              _countChip(Icons.wifi_rounded, '$active activos', AppColors.success),
            ],
          ),
        ),
        IconButton(
          tooltip: _isGridMode ? 'Ver como lista' : 'Ver como mosaico',
          onPressed: () => setState(() => _isGridMode = !_isGridMode),
          style: IconButton.styleFrom(
            backgroundColor: _c.tint(AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: Icon(
            _isGridMode ? Icons.view_list_rounded : Icons.grid_view_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _showAddDeviceDialog,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(isWideLayout(context) ? 'Agregar dispositivo' : 'Agregar'),
        ),
      ],
    );
  }

  Widget _countChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _c.text)),
        ],
      ),
    );
  }

  Widget _buildDrawer() => const AppDrawer(currentRoute: AppRoutes.devices);
}

