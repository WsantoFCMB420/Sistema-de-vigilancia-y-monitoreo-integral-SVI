import 'package:flutter/material.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  // ── Paleta idéntica al proyecto ───────────────────────────────────────────
  static const Color _bgColor = Color(0xFFDDE8F5);
  static const Color _primaryBlue = Color(0xFF1A5DC8);
  static const Color _textColor = Color(0xFF1A2340);
  static const Color _labelColor = Color(0xFF6B7A99);
  static const Color _dangerColor = Color(0xFFE53935);
  static const Color _cardColor = Colors.white;

  // Estado del formulario
  int _selectedType = 0; // 0=Seguridad, 1=Incendio, 2=Médico, 3=Técnico
  int _selectedPriority = 2; // 0=Baja, 1=Media, 2=Crítica
  final TextEditingController _descCtrl = TextEditingController();

  final List<_IncidentType> _types = [
    _IncidentType('Seguridad', Icons.shield_rounded, Color(0xFF1A5DC8)),
    _IncidentType(
      'Incendio',
      Icons.local_fire_department_rounded,
      Color(0xFFFF6D00),
    ),
    _IncidentType('Médico', Icons.medical_services_rounded, Color(0xFF43A047)),
    _IncidentType('Técnico', Icons.engineering_rounded, Color(0xFF7B1FA2)),
  ];

  final List<_Priority> _priorities = [
    _Priority('Baja', Color(0xFF43A047)),
    _Priority('Media', Color(0xFFFFA000)),
    _Priority('Crítica', Color(0xFFE53935)),
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildSection('TIPO DE INCIDENTE'),
                    const SizedBox(height: 12),
                    _buildTypeGrid(),
                    const SizedBox(height: 20),
                    _buildSection('PRIORIDAD DE RESPUESTA'),
                    const SizedBox(height: 12),
                    _buildPriorityToggle(),
                    const SizedBox(height: 20),
                    _buildSection('UBICACIÓN DEL INCIDENTE'),
                    const SizedBox(height: 12),
                    _buildMapPicker(),
                    const SizedBox(height: 20),
                    _buildSection('DESCRIPCIÓN DE LA SITUACIÓN'),
                    const SizedBox(height: 12),
                    _buildDescriptionField(),
                    const SizedBox(height: 20),
                    _buildHighPriorityWarning(),
                  ],
                ),
              ),
            ),
            _buildEmitButton(),
          ],
        ),
      ),
    );
  }

  // ── AppBar con X ──────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: _cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: _textColor, size: 22),
            onPressed: () => Navigator.maybePop(context),
          ),
          const Expanded(
            child: Text(
              'Emitir Alerta',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
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
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── Header del módulo ─────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MÓDULO DE RESPUESTA RÁPIDA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _primaryBlue,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Configuración de Alerta',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Complete los detalles para notificar de inmediato a los equipos de respuesta y activar protocolos de seguridad.',
            style: TextStyle(fontSize: 12, color: _labelColor, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Etiqueta de sección ───────────────────────────────────────────────────
  Widget _buildSection(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _labelColor,
        letterSpacing: 0.8,
      ),
    );
  }

  // ── Grid de tipos de incidente ────────────────────────────────────────────
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
              color: selected ? t.color.withOpacity(0.1) : _cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? t.color : const Color(0xFFE0E8F5),
                width: selected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(t.icon, color: selected ? t.color : _labelColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  t.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? t.color : _textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Toggle de prioridad ───────────────────────────────────────────────────
  Widget _buildPriorityToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : _labelColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Mapa simulado con marcador ─────────────────────────────────────────────
  Widget _buildMapPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 160,
            child: Stack(
              children: [
                // Fondo del mapa (oscuro, estilo satelital)
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0A1628),
                        Color(0xFF0D2040),
                        Color(0xFF0A1628),
                      ],
                    ),
                  ),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _MapGridPainter(),
                  ),
                ),
                // Marcador de ubicación
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFE53935),
                        size: 36,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Punto de incidente',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Controles del mapa
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Column(
                    children: [
                      _mapBtn(Icons.add),
                      const SizedBox(height: 6),
                      _mapBtn(Icons.remove),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: _labelColor,
            ),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Arrastre el marcador para fijar la ubicación exacta.',
                style: TextStyle(fontSize: 11, color: _labelColor),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mapBtn(IconData icon) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: _textColor),
    );
  }

  // ── Campo de descripción ──────────────────────────────────────────────────
  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E8F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _descCtrl,
        maxLines: 4,
        style: const TextStyle(fontSize: 13, color: _textColor),
        decoration: const InputDecoration(
          hintText:
              'Detalle los hechos observados y el estado actual del sitio...',
          hintStyle: TextStyle(fontSize: 13, color: _labelColor),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(14),
        ),
      ),
    );
  }

  // ── Aviso de alta prioridad ───────────────────────────────────────────────
  Widget _buildHighPriorityWarning() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _dangerColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: _dangerColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acción de Alta Prioridad',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _dangerColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Esta alerta notificará instantáneamente a la central de vigilancia y registrará su ID de operador como responsable de la emisión.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Botón Emitir Alerta ───────────────────────────────────────────────────
  Widget _buildEmitButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
      child: ElevatedButton.icon(
        onPressed: _emitAlert,
        icon: const Icon(Icons.campaign_rounded, size: 20),
        label: const Text(
          'Emitir alerta',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _dangerColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: _dangerColor.withOpacity(0.4),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  void _emitAlert() {
    final type = _types[_selectedType].label;
    final priority = _priorities[_selectedPriority].label;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF43A047),
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Alerta emitida',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
          ],
        ),
        content: Text(
          'Alerta de tipo "$type" con prioridad "$priority" enviada a los equipos de respuesta.',
          style: const TextStyle(fontSize: 13, color: _labelColor, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Aceptar',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Painter del grid del mapa ─────────────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A5DC8).withOpacity(0.12)
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
