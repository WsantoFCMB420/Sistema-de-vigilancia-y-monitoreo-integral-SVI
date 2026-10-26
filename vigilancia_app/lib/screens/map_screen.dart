import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../main.dart'; // AppRoutes, SessionService
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _ubateCenter = LatLng(5.3114, -73.8155);
  static const double _minZoom = 3;
  static const double _maxZoom = 18;

  AppColors get _c => AppColors.of(context);

  final MapController _mapController = MapController();
  bool _mapReady = false;

  List<_MapNode> _nodes = [];
  bool _loading = true;
  String? _error;
  _MapNode? _selected;
  LatLng? _myPosition;
  bool _locating = false;
  String _role = 'viewer';
  _NodeFilter _filter = _NodeFilter.all;
  Timer? _refreshTimer;

  bool get _canManage => _role == 'admin' || _role == 'operator';

  @override
  void initState() {
    super.initState();
    SessionService.getUserRole().then((r) {
      if (mounted) setState(() => _role = r);
    });
    _loadNodes();
    // Actualización silenciosa: no muestra el cargador ni mueve el mapa.
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadNodes(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadNodes({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final raw = await ApiService.getMapNodes();
      if (!mounted) return;
      final nodes = raw
          .whereType<Map>()
          .map((n) => _MapNode.fromJson(Map<String, dynamic>.from(n)))
          .whereType<_MapNode>()
          .toList();
      setState(() {
        _nodes = nodes;
        _loading = false;
        _error = null;
        if (_selected != null) {
          _selected = _nodes.where((n) => n.key == _selected!.key).firstOrNull;
        }
      });
    } on SessionExpiredException {
      return;
    } catch (e) {
      if (!mounted) return;
      if (silent) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<_MapNode> get _visibleNodes {
    switch (_filter) {
      case _NodeFilter.devices:
        return _nodes.where((n) => !n.isAlert).toList();
      case _NodeFilter.alerts:
        return _nodes.where((n) => n.isAlert).toList();
      case _NodeFilter.all:
        return _nodes;
    }
  }

  LatLng get _initialCenter {
    final devices = _nodes.where((n) => !n.isAlert);
    if (devices.isNotEmpty) return devices.first.point;
    if (_nodes.isNotEmpty) return _nodes.first.point;
    return _ubateCenter;
  }

  // ── Controles del mapa ──────────────────────────────────────────────────
  void _zoomBy(double delta) {
    if (!_mapReady) return;
    final camera = _mapController.camera;
    final next = (camera.zoom + delta).clamp(_minZoom, _maxZoom).toDouble();
    _mapController.move(camera.center, next);
  }

  void _focus(_MapNode node, {bool openDetails = true}) {
    setState(() => _selected = node);
    if (_mapReady) {
      final zoom = _mapController.camera.zoom < 15 ? 15.0 : _mapController.camera.zoom;
      _mapController.move(node.point, zoom);
    }
    if (openDetails) _showNodeDetails(node);
  }

  Future<void> _goToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _toast('Activa la ubicación del dispositivo o del navegador.', AppColors.warning);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _toast('Permiso de ubicación denegado.', AppColors.danger);
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _toast('El permiso de ubicación está bloqueado. Actívalo en los ajustes.', AppColors.danger);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      final here = LatLng(position.latitude, position.longitude);
      setState(() => _myPosition = here);
      if (_mapReady) _mapController.move(here, 16);
      _toast('Mapa centrado en tu ubicación.', AppColors.primary);
    } on TimeoutException {
      _toast('No se obtuvo la ubicación a tiempo. Intenta de nuevo.', AppColors.warning);
    } catch (e) {
      _toast('No se pudo obtener la ubicación: $e', AppColors.danger);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _toast(String msg, Color color) {
    if (!mounted) return;
    showAppSnackBar(context, msg, backgroundColor: color);
  }

  // ── Acciones sobre alertas (sin recargar el módulo) ─────────────────────
  Future<void> _changeAlertStatus(_MapNode node, String status) async {
    try {
      await ApiService.updateAlertStatus(node.id, status);
      if (!mounted) return;
      setState(() {
        final updated = node.copyWith(status: status);
        final i = _nodes.indexWhere((n) => n.key == node.key);
        if (i >= 0) _nodes[i] = updated;
        if (_selected?.key == node.key) _selected = updated;
      });
      _toast('Alerta marcada como "$status".', AppColors.primary);
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), AppColors.danger);
    }
  }

  Future<void> _deleteAlert(_MapNode node) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar alerta?'),
        content: Text('Se quitará "${node.label}" del mapa y del historial.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deleteAlert(node.id);
      if (!mounted) return;
      setState(() {
        _nodes.removeWhere((n) => n.key == node.key);
        if (_selected?.key == node.key) _selected = null;
      });
      _toast('Alerta eliminada.', AppColors.primary);
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), AppColors.danger);
    }
  }

  void _openCamera(_MapNode node) {
    Navigator.pushNamed(context, AppRoutes.cameraView, arguments: <String, dynamic>{
      'id': node.id,
      'title': node.label,
      'stream_url': node.streamUrl,
      'ip_address': node.ipAddress,
      'is_ptz': node.isPtz,
    });
  }

  // ══════════════════════════════════════════════════════════════════════
  // UI
  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    return Scaffold(
      backgroundColor: _c.bg,
      drawer: const AppDrawer(currentRoute: AppRoutes.map),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 14, wide ? 28 : 16, 12),
              child: AppTopBar(
                title: 'Mapa de red',
                subtitle: 'Cámaras y alertas en el Valle de Ubaté',
                icon: Icons.map_rounded,
                actions: [
                  IconButton(
                    tooltip: 'Actualizar',
                    onPressed: _loading ? null : () => _loadNodes(),
                    icon: Icon(Icons.refresh_rounded, color: _c.text),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(wide ? 28 : 12, 0, wide ? 28 : 12, wide ? 24 : 12),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildMapCard()),
                          const SizedBox(width: 20),
                          SizedBox(width: 340, child: _buildSidePanel()),
                        ],
                      )
                    : _buildMapCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard() {
    final wide = isWideLayout(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: DecoratedBox(
        decoration: BoxDecoration(color: _c.card, border: Border.all(color: _c.border)),
        child: Stack(
          children: [
            Positioned.fill(child: _buildMapBody()),
            Positioned(top: 12, left: 12, right: 64, child: _buildFilterBar()),
            Positioned(top: 12, right: 12, child: _buildMapControls()),
            if (!wide)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _selected != null ? _buildSelectedCard(_selected!) : _buildSummaryCard(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 46, color: AppColors.danger),
              const SizedBox(height: 12),
              Text('No se pudo cargar el mapa',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _c.text)),
              const SizedBox(height: 6),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: _c.label)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _loadNodes(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _initialCenter,
        initialZoom: 14,
        minZoom: _minZoom,
        maxZoom: _maxZoom,
        onMapReady: () => _mapReady = true,
        onTap: (_, __) {
          if (_selected != null) setState(() => _selected = null);
        },
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.svi.vigilancia',
          maxZoom: _maxZoom,
        ),
        MarkerLayer(
          markers: [
            for (final node in _visibleNodes)
              Marker(
                point: node.point,
                width: 46,
                height: 46,
                child: _MarkerPin(
                  node: node,
                  selected: _selected?.key == node.key,
                  onTap: () => _focus(node),
                ),
              ),
            if (_myPosition != null)
              Marker(
                point: _myPosition!,
                width: 26,
                height: 26,
                child: const _MyLocationDot(),
              ),
          ],
        ),
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [TextSourceAttribution('OpenStreetMap')],
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    Widget chip(_NodeFilter f, String label, IconData icon) {
      final selected = _filter == f;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Material(
          color: selected ? AppColors.primary : _c.card.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _filter = f),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 15, color: selected ? Colors.white : _c.label),
                  const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : _c.text,
                      )),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(_NodeFilter.all, 'Todo', Icons.layers_rounded),
          chip(_NodeFilter.devices, 'Cámaras', Icons.videocam_rounded),
          chip(_NodeFilter.alerts, 'Alertas', Icons.warning_amber_rounded),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    Widget btn(IconData icon, String tooltip, VoidCallback? onTap, {Widget? child}) {
      return Material(
        color: _c.card,
        elevation: 3,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Tooltip(
            message: tooltip,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Center(child: child ?? Icon(icon, size: 21, color: _c.text)),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.add_rounded, 'Acercar', () => _zoomBy(1)),
        const SizedBox(height: 6),
        btn(Icons.remove_rounded, 'Alejar', () => _zoomBy(-1)),
        const SizedBox(height: 14),
        btn(
          Icons.my_location_rounded,
          'Mi ubicación',
          _goToMyLocation,
          child: _locating
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location_rounded, size: 21, color: AppColors.primary),
        ),
        const SizedBox(height: 6),
        btn(Icons.center_focus_strong_rounded, 'Centrar en los nodos', () {
          if (_mapReady) _mapController.move(_initialCenter, 14);
        }),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final cams = _nodes.where((n) => !n.isAlert).length;
    final alerts = _nodes.where((n) => n.isAlert && n.isOpen).length;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _summaryStat(Icons.videocam_rounded, '$cams', 'Cámaras', AppColors.primary),
          Container(width: 1, height: 34, color: _c.border, margin: const EdgeInsets.symmetric(horizontal: 14)),
          _summaryStat(Icons.warning_amber_rounded, '$alerts', 'Alertas activas',
              alerts > 0 ? AppColors.danger : AppColors.success),
          const Spacer(),
          Text('Toca un punto', style: TextStyle(fontSize: 11, color: _c.label)),
        ],
      ),
    );
  }

  Widget _summaryStat(IconData icon, String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: _c.tint(color), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _c.text)),
            Text(label, style: TextStyle(fontSize: 10, color: _c.label)),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedCard(_MapNode node) {
    final color = node.color;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      onTap: () => _showNodeDetails(node),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: _c.tint(color), borderRadius: BorderRadius.circular(12)),
            child: Icon(node.icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(node.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _c.text)),
                const SizedBox(height: 2),
                Text(
                  node.isAlert
                      ? (node.description.isNotEmpty ? node.description : '${node.priority} • ${node.status}')
                      : (node.description.isNotEmpty ? node.description : node.status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: _c.label),
                ),
              ],
            ),
          ),
          if (!node.isAlert)
            IconButton(
              tooltip: 'Ver cámara',
              onPressed: () => _openCamera(node),
              icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 30),
            )
          else
            IconButton(
              tooltip: 'Ver detalle',
              onPressed: () => _showNodeDetails(node),
              icon: Icon(Icons.chevron_right_rounded, color: _c.label),
            ),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    final list = _visibleNodes;
    final alerts = _nodes.where((n) => n.isAlert && n.isOpen).length;
    final cams = _nodes.where((n) => !n.isAlert).length;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(
              children: [
                Expanded(child: _summaryStat(Icons.videocam_rounded, '$cams', 'Cámaras', AppColors.primary)),
                Expanded(
                  child: _summaryStat(Icons.warning_amber_rounded, '$alerts', 'Alertas activas',
                      alerts > 0 ? AppColors.danger : AppColors.success),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _c.border),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _loading ? 'Cargando…' : 'No hay elementos para mostrar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _c.label),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (_, i) {
                      final node = list[i];
                      final selected = _selected?.key == node.key;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ListTile(
                          selected: selected,
                          selectedTileColor: _c.tint(AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                                color: _c.tint(node.color), borderRadius: BorderRadius.circular(10)),
                            child: Icon(node.icon, color: node.color, size: 19),
                          ),
                          title: Text(node.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _c.text)),
                          subtitle: Text(
                            node.isAlert ? '${node.priority} • ${node.status}' : node.status,
                            style: TextStyle(fontSize: 11, color: _c.label),
                          ),
                          onTap: () => _focus(node),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Detalle de un punto (alerta o cámara) ──────────────────────────────
  void _showNodeDetails(_MapNode node) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (sheetCtx) {
        final c = AppColors.of(sheetCtx);
        final color = node.color;

        Widget row(IconData icon, String label, String value) {
          if (value.trim().isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: c.label),
                const SizedBox(width: 10),
                SizedBox(
                  width: 96,
                  child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.label)),
                ),
                Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: c.text))),
              ],
            ),
          );
        }

        final canDelete = node.isAlert && (_canManage || node.isMine);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: c.tint(color), borderRadius: BorderRadius.circular(14)),
                    child: Icon(node.icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(node.isAlert ? 'Alerta #${node.id}' : 'Dispositivo #${node.id}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.label)),
                        Text(node.label,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(node.status, color),
                  if (node.isAlert) _pill('Prioridad ${node.priority}', _priorityColor(node.priority)),
                ],
              ),
              const SizedBox(height: 18),
              if (node.isAlert) ...[
                Text('DESCRIPCIÓN',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.label, letterSpacing: 0.8)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.cardAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: Text(
                    node.description.isNotEmpty ? node.description : 'Sin descripción registrada.',
                    style: TextStyle(fontSize: 14, color: c.text, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),
                row(Icons.place_outlined, 'Ubicación', node.location),
                row(Icons.videocam_outlined, 'Cámara', node.deviceName),
                row(Icons.person_outline_rounded, 'Reportada por', node.userName),
                row(Icons.schedule_rounded, 'Fecha', node.createdAt),
              ] else ...[
                row(Icons.info_outline_rounded, 'Descripción', node.description),
                row(Icons.lan_outlined, 'IP / host', node.ipAddress),
                row(Icons.control_camera_rounded, 'PTZ', node.isPtz ? 'Sí' : 'No'),
              ],
              row(Icons.my_location_outlined, 'Coordenadas',
                  '${node.lat.toStringAsFixed(5)}, ${node.lng.toStringAsFixed(5)}'),
              const SizedBox(height: 8),
              if (!node.isAlert)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _openCamera(node);
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Ver cámara en vivo'),
                  ),
                ),
              if (node.isAlert && _canManage && node.isOpen) ...[
                Text('CAMBIAR ESTADO',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.label, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (node.status != 'En atención')
                      _statusButton(sheetCtx, node, 'En atención', AppColors.warning, Icons.directions_run_rounded),
                    _statusButton(sheetCtx, node, 'Resuelta', AppColors.success, Icons.check_circle_rounded),
                    _statusButton(sheetCtx, node, 'Falsa Alarma', const Color(0xFF607D8B), Icons.block_rounded),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (node.isAlert)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          navigateToModule(context, AppRoutes.alerts);
                        },
                        icon: const Icon(Icons.list_alt_rounded, size: 18),
                        label: const Text('Ir a Alertas'),
                      ),
                    ),
                    if (canDelete) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
                          ),
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            _deleteAlert(node);
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: const Text('Eliminar'),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusButton(BuildContext sheetCtx, _MapNode node, String status, Color color, IconData icon) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.14),
        foregroundColor: color,
        minimumSize: const Size(0, 40),
      ),
      onPressed: () {
        Navigator.pop(sheetCtx);
        _changeAlertStatus(node, status);
      },
      icon: Icon(icon, size: 18),
      label: Text(status),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }

  static Color _priorityColor(String p) {
    switch (p) {
      case 'Crítica':
        return AppColors.danger;
      case 'Baja':
        return AppColors.success;
      default:
        return AppColors.warning;
    }
  }
}

// ── Widgets del mapa ─────────────────────────────────────────────────────
class _MarkerPin extends StatelessWidget {
  final _MapNode node;
  final bool selected;
  final VoidCallback onTap;
  const _MarkerPin({required this.node, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = node.color;
    final size = selected ? 40.0 : 34.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: selected ? 3 : 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: selected ? 14 : 8, spreadRadius: selected ? 2 : 0),
            ],
          ),
          child: Icon(node.icon, color: Colors.white, size: selected ? 20 : 17),
        ),
      ),
    );
  }
}

class _MyLocationDot extends StatelessWidget {
  const _MyLocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2979FF),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: const Color(0xFF2979FF).withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 4)],
      ),
    );
  }
}

// ── Modelos ──────────────────────────────────────────────────────────────
enum _NodeFilter { all, devices, alerts }

class _MapNode {
  final int id;
  final bool isAlert;
  final String label;
  final double lat;
  final double lng;
  final String status;
  final String priority;
  final String description;
  final String location;
  final String deviceName;
  final String userName;
  final String createdAt;
  final bool isMine;
  final String streamUrl;
  final String ipAddress;
  final bool isPtz;

  const _MapNode({
    required this.id,
    required this.isAlert,
    required this.label,
    required this.lat,
    required this.lng,
    required this.status,
    this.priority = 'Media',
    this.description = '',
    this.location = '',
    this.deviceName = '',
    this.userName = '',
    this.createdAt = '',
    this.isMine = false,
    this.streamUrl = '',
    this.ipAddress = '',
    this.isPtz = false,
  });

  /// Devuelve null si el punto no tiene id o coordenadas válidas.
  static _MapNode? fromJson(Map<String, dynamic> n) {
    final id = n['id'] is int ? n['id'] as int : int.tryParse('${n['id']}');
    final lat = n['lat'] is num ? (n['lat'] as num).toDouble() : double.tryParse('${n['lat']}');
    final lng = n['lng'] is num ? (n['lng'] as num).toDouble() : double.tryParse('${n['lng']}');
    if (id == null || lat == null || lng == null) return null;
    final isAlert = n['isAlert'] == true || n['type'] == 'alert';
    String str(String k) => (n[k] ?? '').toString();
    return _MapNode(
      id: id,
      isAlert: isAlert,
      label: str('label').isEmpty ? (isAlert ? 'Alerta' : 'Dispositivo') : str('label'),
      lat: lat,
      lng: lng,
      status: str('status').isEmpty ? (isAlert ? 'Pendiente' : 'Activo') : str('status'),
      priority: str('priority').isEmpty ? 'Media' : str('priority'),
      description: str('description'),
      location: str('location'),
      deviceName: str('device_name'),
      userName: str('user_name'),
      createdAt: str('created_at'),
      isMine: n['is_mine'] == true,
      streamUrl: str('stream_url'),
      ipAddress: str('ip_address'),
      isPtz: n['is_ptz'] == true || n['is_ptz'] == 1,
    );
  }

  String get key => '${isAlert ? 'a' : 'd'}$id';
  LatLng get point => LatLng(lat, lng);
  bool get isOpen => status == 'Pendiente' || status == 'En atención';

  IconData get icon => isAlert ? Icons.warning_rounded : Icons.videocam_rounded;

  Color get color {
    if (!isAlert) {
      return status == 'Activo' ? AppColors.primary : const Color(0xFF8A94A6);
    }
    switch (status) {
      case 'En atención':
        return AppColors.warning;
      case 'Resuelta':
      case 'Falsa Alarma':
        return AppColors.success;
      default:
        return AppColors.danger;
    }
  }

  _MapNode copyWith({String? status}) => _MapNode(
        id: id,
        isAlert: isAlert,
        label: label,
        lat: lat,
        lng: lng,
        status: status ?? this.status,
        priority: priority,
        description: description,
        location: location,
        deviceName: deviceName,
        userName: userName,
        createdAt: createdAt,
        isMine: isMine,
        streamUrl: streamUrl,
        ipAddress: ipAddress,
        isPtz: isPtz,
      );
}
