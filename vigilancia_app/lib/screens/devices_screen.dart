import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/device_card.dart';
import '../widgets/responsive.dart';
import '../widgets/theme_toggle_button.dart';
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

  static const Color _primaryBlue = Color(0xFF1A5DC8);
  static const Color _dangerColor = Color(0xFFE53935);

  AppColors get _c => AppColors.of(context);

  static const List<_ModuleItem> _allModules = [
    _ModuleItem(Icons.dashboard_rounded,            'Dashboard',    AppRoutes.dashboard,     Color(0xFF1A5DC8)),
    _ModuleItem(Icons.map_rounded,                  'Mapa',         AppRoutes.map,           Color(0xFF00897B)),
    _ModuleItem(Icons.videocam_rounded,             'Cámaras',      AppRoutes.cameraView,    Color(0xFF6D4C41)),
    _ModuleItem(Icons.devices_rounded,              'Dispositivos', AppRoutes.devices,       Color(0xFF5E35B1)),
    _ModuleItem(Icons.warning_amber_rounded,        'Alertas',      AppRoutes.alerts,        Color(0xFFE53935)),
    _ModuleItem(Icons.forum_rounded,                'Comunicación', AppRoutes.communication, Color(0xFF0288D1)),
    _ModuleItem(Icons.psychology_rounded,           'IA Hub',       AppRoutes.iaModule,      Color(0xFF7B1FA2)),
    _ModuleItem(Icons.assessment_rounded,           'Reportes',     AppRoutes.reportes,      Color(0xFF2E7D32)),
    _ModuleItem(Icons.admin_panel_settings_rounded, 'Admin',        AppRoutes.admin,         Color(0xFFAD1457)),
  ];

  @override
  void initState() {
    super.initState();
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
                // Handle
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

                // Tipo de dispositivo
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

                // Si es cámara, campos de video y red
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
                          icon: Icons.smartphone_rounded,
                          label: 'Este dispositivo',
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
                        'Usará la cámara del celular o la webcam del computador. Es la opción de prueba funcional.',
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

                // Descripción / Ubicación
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

                // Estado
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
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _loadDevices();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dispositivo registrado correctamente'),
                            backgroundColor: Color(0xFF1A5DC8),
                          ),
                        );
                      } catch (e) {
                        setSheet(() => saving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dispositivo eliminado'), backgroundColor: Color(0xFF1A5DC8)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                              child: LayoutBuilder(
                                builder: (ctx, constraints) {
                                  final columns = Breakpoints.deviceColumns(context);
                                  return GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisExtent: 96,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 4,
                                ),
                                itemCount: _devices.length,
                                itemBuilder: (ctx, i) {
                                  final d = _devices[i];
                                  return Dismissible(
                                    key: Key('device_${d['id']}'),
                                    direction: columns == 1
                                        ? DismissDirection.endToStart
                                        : DismissDirection.none,
                                    onDismissed: (_) => _deleteDevice(d),
                                    confirmDismiss: (_) async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16)),
                                          title: const Text('¿Eliminar dispositivo?',
                                              style: TextStyle(fontWeight: FontWeight.w700)),
                                          content: Text('Se eliminará "${d['title']}" permanentemente.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancelar'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: _dangerColor,
                                                  foregroundColor: Colors.white),
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
                                          Icon(Icons.delete_outline_rounded,
                                              color: Colors.white, size: 26),
                                          SizedBox(height: 4),
                                          Text('Eliminar',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600)),
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
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.cameraView,
                                          arguments: d,
                                        );
                                      },
                                      onDelete: columns > 1 ? () => _deleteDevice(d) : null,
                                    ),
                                  );
                                },
                                  );
                                },
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
                  color: _primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: _primaryBlue, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            Builder(
              builder: (ctx) => GestureDetector(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
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
            Text('Dispositivos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _c.text)),
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SISTEMAS ACTIVOS',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: _c.label, letterSpacing: 1.0)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Mis Dispositivos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _c.text)),
                if (_devices.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _primaryBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${_devices.length}',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: _showAddDeviceDialog,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _primaryBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
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
              children: _allModules.map((mod) {
                final isCurrent = mod.route == AppRoutes.devices;
                return ListTile(
                  leading: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: isCurrent ? mod.color : mod.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(mod.icon, color: isCurrent ? Colors.white : mod.color, size: 20),
                  ),
                  title: Text(mod.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrent ? _primaryBlue : _c.text,
                      )),
                  trailing: isCurrent
                      ? Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(color: _primaryBlue, shape: BoxShape.circle))
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (!isCurrent) Navigator.pushNamed(context, mod.route);
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: _dangerColor),
            title: const Text('Cerrar sesión',
                style: TextStyle(color: _dangerColor, fontWeight: FontWeight.w600)),
            onTap: () async {
              Navigator.pop(context);
              await ApiService.logout();
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
}

class _ModuleItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _ModuleItem(this.icon, this.label, this.route, this.color);
}