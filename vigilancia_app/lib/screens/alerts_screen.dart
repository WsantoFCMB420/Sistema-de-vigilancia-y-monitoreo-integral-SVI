import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with SingleTickerProviderStateMixin {
  // ── Paleta idéntica al proyecto ───────────────────────────────────────────
  static const Color _bgColor     = Color(0xFFDDE8F5);
  static const Color _primaryBlue = Color(0xFF1A5DC8);
  static const Color _textColor   = Color(0xFF1A2340);
  static const Color _labelColor  = Color(0xFF6B7A99);
  static const Color _dangerColor = Color(0xFFE53935);
  static const Color _cardColor   = Colors.white;

  late TabController _tabController;

  // Estado del formulario de emisión
  int _selectedType = 0;
  int _selectedPriority = 2;
  final TextEditingController _descCtrl     = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController(text: 'Acceso Perimetral 1');
  int? _selectedDeviceId;
  double _selectedLat = 4.7110;
  double _selectedLng = -74.0721;
  bool _submitting = false;

  // Lista de dispositivos para vincular
  List<dynamic> _devices = [];
  bool _loadingDevices = true;

  // Lista de alertas para gestión
  List<dynamic> _alerts = [];
  bool _loadingAlerts = true;
  String? _alertsError;
  String _filterStatus = 'Todas'; // 'Todas', 'Pendiente', 'En atención', 'Resuelta'

  final List<_IncidentType> _types = [
    _IncidentType('Seguridad', Icons.shield_rounded, const Color(0xFF1A5DC8)),
    _IncidentType('Incendio', Icons.local_fire_department_rounded, const Color(0xFFFF6D00)),
    _IncidentType('Médico', Icons.medical_services_rounded, const Color(0xFF43A047)),
    _IncidentType('Técnico', Icons.engineering_rounded, const Color(0xFF7B1FA2)),
  ];

  final List<_Priority> _priorities = [
    _Priority('Baja', const Color(0xFF43A047)),
    _Priority('Media', const Color(0xFFFFA000)),
    _Priority('Crítica', const Color(0xFFE53935)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _loadDevices();
    _loadAlerts();
  }

  Future<void> _loadDevices() async {
    setState(() => _loadingDevices = true);
    try {
      final list = await ApiService.getDevices();
      if (!mounted) return;
      setState(() {
        _devices = list;
        _loadingDevices = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDevices = false);
    }
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _loadingAlerts = true;
      _alertsError = null;
    });
    try {
      final list = await ApiService.getAlerts();
      if (!mounted) return;
      setState(() {
        _alerts = list;
        _loadingAlerts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _alertsError = e.toString();
        _loadingAlerts = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textColor, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Centro de Alertas',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textColor),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryBlue,
          unselectedLabelColor: _labelColor,
          indicatorColor: _primaryBlue,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Emitir Alerta', icon: Icon(Icons.add_alert_rounded, size: 20)),
            Tab(text: 'Gestión y Ciclo', icon: Icon(Icons.rule_folder_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEmitTab(),
          _buildManagementTab(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1: EMITIR ALERTA
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildEmitTab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),

                _buildSection('TIPO DE INCIDENTE'),
                const SizedBox(height: 10),
                _buildTypeGrid(),
                const SizedBox(height: 20),

                _buildSection('PRIORIDAD DE RESPUESTA'),
                const SizedBox(height: 10),
                _buildPriorityToggle(),
                const SizedBox(height: 20),

                _buildSection('VINCULAR A CÁMARA O DISPOSITIVO'),
                const SizedBox(height: 10),
                _buildDeviceSelector(),
                const SizedBox(height: 20),

                _buildSection('UBICACIÓN Y COORDENADAS GPS'),
                const SizedBox(height: 10),
                _buildMapPicker(),
                const SizedBox(height: 20),

                _buildSection('DESCRIPCIÓN DE LA SITUACIÓN'),
                const SizedBox(height: 10),
                _buildDescriptionField(),
                const SizedBox(height: 20),

                _buildHighPriorityWarning(),
              ],
            ),
          ),
        ),
        _buildEmitButton(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MÓDULO DE RESPUESTA RÁPIDA',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _primaryBlue, letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          const Text(
            'Emisión de Alerta Operativa',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textColor),
          ),
          const SizedBox(height: 6),
          const Text(
            'Asocie la alerta a cámaras, configure coordenadas exactas y notifique instantáneamente al centro de monitoreo.',
            style: TextStyle(fontSize: 12, color: _labelColor, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String label) {
    return Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _labelColor, letterSpacing: 0.8));
  }

  Widget _buildTypeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.4,
      ),
      itemCount: _types.length,
      itemBuilder: (ctx, i) {
        final t = _types[i];
        final selected = _selectedType == i;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? t.color.withValues(alpha: 0.1) : _cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? t.color : const Color(0xFFE0E8F5),
                width: selected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Icon(t.icon, color: selected ? t.color : _labelColor, size: 22),
                const SizedBox(width: 10),
                Text(t.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? t.color : _textColor)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriorityToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: _priorities.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final selected = _selectedPriority == i;
          final isFirst = i == 0;
          final isLast = i == _priorities.length - 1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPriority = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? p.color : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    left: isFirst ? const Radius.circular(12) : Radius.zero,
                    right: isLast ? const Radius.circular(12) : Radius.zero,
                  ),
                ),
                child: Center(
                  child: Text(
                    p.label,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : _labelColor),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeviceSelector() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E8F5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: _loadingDevices
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Cargando dispositivos...', style: TextStyle(fontSize: 13, color: _labelColor)),
                ],
              ),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedDeviceId,
                isExpanded: true,
                hint: const Row(
                  children: [
                    Icon(Icons.videocam_outlined, color: _labelColor, size: 20),
                    SizedBox(width: 10),
                    Text('Alerta General (Sin cámara vinculada)', style: TextStyle(fontSize: 13, color: _labelColor)),
                  ],
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Ninguna (Alerta general)', style: TextStyle(fontSize: 13)),
                  ),
                  ..._devices.map((d) {
                    final isCam = (d['is_ptz'] == true || d['is_ptz'] == 1 || (d['device_type'] ?? '') == 'camera');
                    return DropdownMenuItem<int?>(
                      value: d['id'] as int,
                      child: Row(
                        children: [
                          Icon(isCam ? Icons.videocam_rounded : Icons.devices_rounded, color: _primaryBlue, size: 18),
                          const SizedBox(width: 8),
                          Text('${d['title']} ${isCam ? '(Cámara)' : ''}', style: const TextStyle(fontSize: 13, color: _textColor)),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedDeviceId = val;
                    if (val != null) {
                      final found = _devices.firstWhere((d) => d['id'] == val, orElse: () => null);
                      if (found != null && found['title'] != null) {
                        _locationCtrl.text = found['subtitle']?.toString().isNotEmpty == true
                            ? '${found['title']} (${found['subtitle']})'
                            : found['title'].toString();
                        if (found['latitude'] != null) _selectedLat = (found['latitude'] as num).toDouble();
                        if (found['longitude'] != null) _selectedLng = (found['longitude'] as num).toDouble();
                      }
                    }
                  });
                },
              ),
            ),
    );
  }

  Widget _buildMapPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _locationCtrl,
          style: const TextStyle(fontSize: 13, color: _textColor),
          decoration: InputDecoration(
            hintText: 'Nombre de la ubicación (ej: Pasillo 3, Torre A)',
            hintStyle: const TextStyle(fontSize: 13, color: _labelColor),
            filled: true,
            fillColor: _cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            prefixIcon: const Icon(Icons.place_rounded, color: _dangerColor, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E8F5))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E8F5))),
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: GestureDetector(
            onPanUpdate: (details) {
              // Actualiza coordenadas al interactuar con el mapa
              setState(() {
                _selectedLat = 4.7110 + (details.localPosition.dy - 80) * 0.0001;
                _selectedLng = -74.0721 + (details.localPosition.dx - 150) * 0.0001;
              });
            },
            onTapDown: (details) {
              setState(() {
                _selectedLat = 4.7110 + (details.localPosition.dy - 80) * 0.0001;
                _selectedLng = -74.0721 + (details.localPosition.dx - 150) * 0.0001;
              });
            },
            child: SizedBox(
              height: 150,
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0A1628), Color(0xFF0D2040), Color(0xFF0A1628)],
                      ),
                    ),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _MapGridPainter(),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on_rounded, color: Color(0xFFE53935), size: 36),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'GPS: ${_selectedLat.toStringAsFixed(4)}, ${_selectedLng.toStringAsFixed(4)}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Row(
          children: [
            Icon(Icons.touch_app_rounded, size: 14, color: _labelColor),
            SizedBox(width: 6),
            Expanded(child: Text('Toque o arrastre sobre el radar para ajustar las coordenadas GPS.', style: TextStyle(fontSize: 11, color: _labelColor))),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E8F5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: _descCtrl,
        maxLines: 3,
        style: const TextStyle(fontSize: 13, color: _textColor),
        decoration: const InputDecoration(
          hintText: 'Detalle los hechos observados, personas o vehículos involucrados...',
          hintStyle: TextStyle(fontSize: 13, color: _labelColor),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _buildHighPriorityWarning() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _dangerColor.withValues(alpha: 0.3), width: 1),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: _dangerColor, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Acción de Alta Prioridad', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _dangerColor)),
                SizedBox(height: 4),
                Text(
                  'Esta alerta quedará registrada en el ciclo de vida operativo con estado inicial "Pendiente".',
                  style: TextStyle(fontSize: 12, color: _textColor, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmitButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _submitting ? null : _emitAlert,
        icon: _submitting
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.campaign_rounded, size: 20),
        label: Text(_submitting ? 'Emitiendo alerta...' : 'Emitir Alerta Operativa',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _dangerColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: _dangerColor.withValues(alpha: 0.4),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  void _emitAlert() async {
    final type = _types[_selectedType].label;
    final priority = _priorities[_selectedPriority].label;
    final desc = _descCtrl.text.trim();
    final location = _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.trim() : 'Punto de incidente';

    setState(() => _submitting = true);
    try {
      await ApiService.sendAlert(
        type: type,
        priority: priority,
        location: location,
        description: desc,
        deviceId: _selectedDeviceId,
        latitude: _selectedLat,
        longitude: _selectedLng,
        status: 'Pendiente',
      );
      if (!mounted) return;
      setState(() => _submitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alerta de tipo "$type" con prioridad "$priority" emitida con éxito.'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      _descCtrl.clear();
      _loadAlerts();

      // Cambiar a la pestaña de gestión para ver la alerta emitida
      _tabController.animateTo(1);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al emitir alerta: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2: GESTIÓN Y CICLO DE VIDA DE ALERTAS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildManagementTab() {
    final filtered = _alerts.where((a) {
      if (_filterStatus == 'Todas') return true;
      return (a['status'] ?? 'Pendiente') == _filterStatus;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _loadingAlerts
                ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
                : _alertsError != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: _dangerColor, size: 40),
                            const SizedBox(height: 10),
                            Text('Error: $_alertsError', style: const TextStyle(color: _labelColor)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _loadAlerts, child: const Text('Reintentar')),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, color: const Color(0xFF43A047).withValues(alpha: 0.5), size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  _filterStatus == 'Todas' ? 'Sin alertas registradas' : 'No hay alertas con estado "$_filterStatus"',
                                  style: const TextStyle(color: _labelColor, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) => _buildAlertManagementCard(filtered[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Todas', 'Pendiente', 'En atención', 'Resuelta'];
    return Container(
      color: _cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final selected = _filterStatus == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f),
                selected: selected,
                selectedColor: _primaryBlue,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _textColor,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                backgroundColor: const Color(0xFFF0F4FA),
                onSelected: (_) => setState(() => _filterStatus = f),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAlertManagementCard(dynamic alert) {
    final status = alert['status'] ?? 'Pendiente';
    final priority = alert['priority'] ?? 'Media';
    final deviceName = alert['device_name'];
    final attendedBy = alert['attended_by_name'];
    final isCritical = priority == 'Crítica';

    Color statusColor;
    Color statusBg;
    switch (status) {
      case 'Pendiente':
        statusColor = const Color(0xFFE65100);
        statusBg = const Color(0xFFFFF3E0);
        break;
      case 'En atención':
        statusColor = _primaryBlue;
        statusBg = const Color(0xFFEEF4FF);
        break;
      case 'Resuelta':
        statusColor = const Color(0xFF2E7D32);
        statusBg = const Color(0xFFE8F5E9);
        break;
      case 'Falsa Alarma':
        statusColor = Colors.blueGrey;
        statusBg = const Color(0xFFECEFF1);
        break;
      default:
        statusColor = _labelColor;
        statusBg = const Color(0xFFF4F7FB);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCritical ? _dangerColor.withValues(alpha: 0.3) : const Color(0xFFE4EAF5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Tipo, Prioridad y Estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCritical ? const Color(0xFFFDECEC) : _primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${alert['type']} • $priority',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isCritical ? _dangerColor : _primaryBlue,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Ubicación y Dispositivo
            Row(
              children: [
                const Icon(Icons.place_rounded, size: 16, color: _labelColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    alert['location']?.isNotEmpty == true ? alert['location'] : 'Sin ubicación especificada',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textColor),
                  ),
                ),
              ],
            ),
            if (deviceName != null && deviceName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.videocam_rounded, size: 16, color: _primaryBlue),
                  const SizedBox(width: 6),
                  Text('Vinculada a: $deviceName', style: const TextStyle(fontSize: 12, color: _primaryBlue, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
            if (alert['description']?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(
                alert['description'],
                style: const TextStyle(fontSize: 12, color: _labelColor, height: 1.4),
              ),
            ],
            const SizedBox(height: 10),

            // Metadata: Emisor, Atendido por y Tiempo
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Por: ${alert['user_name'] ?? 'Sistema'}${attendedBy != null ? ' | Atendido por: $attendedBy' : ''}',
                    style: const TextStyle(fontSize: 11, color: _labelColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  alert['created_at'] ?? '',
                  style: const TextStyle(fontSize: 11, color: _labelColor),
                ),
              ],
            ),
            const Divider(height: 18),

            // Botones de acción del ciclo de vida
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'Pendiente')
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(alert['id'], 'En atención'),
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Iniciar Atención', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                if (status == 'En atención') ...[
                  OutlinedButton(
                    onPressed: () => _updateStatus(alert['id'], 'Falsa Alarma'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueGrey,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Falsa Alarma', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(alert['id'], 'Resuelta'),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Resolver', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
                if (status == 'Resuelta' || status == 'Falsa Alarma') ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: _dangerColor, size: 20),
                    tooltip: 'Eliminar del registro',
                    onPressed: () => _deleteAlert(alert['id']),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateStatus(int id, String newStatus) async {
    try {
      await ApiService.updateAlertStatus(id, newStatus);
      _loadAlerts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alerta actualizada a "$newStatus"'), backgroundColor: const Color(0xFF1A5DC8)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _deleteAlert(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar registro de alerta?'),
        content: const Text('Esta acción quitará la alerta del historial.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _dangerColor, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deleteAlert(id);
      _loadAlerts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }
}

// ── Painter del grid del mapa ─────────────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A5DC8).withValues(alpha: 0.15)
      ..strokeWidth = 0.7;
    for (double y = 0; y < size.height; y += size.height / 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += size.width / 6) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Modelos ───────────────────────────────────────────────────────────────────
class _IncidentType {
  final String label;
  final IconData icon;
  final Color color;
  const _IncidentType(this.label, this.icon, this.color);
}

class _Priority {
  final String label;
  final Color color;
  const _Priority(this.label, this.color);
}
