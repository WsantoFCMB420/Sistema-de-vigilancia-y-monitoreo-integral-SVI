import 'package:flutter/material.dart';

class AdminPanelScreen extends StatefulWidget {
const AdminPanelScreen({super.key});
@override
State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  // ── Colores ───────────────────────────────────────────────────
static const Color _bg        = Color(0xFFF4F7FB);
static const Color _blue      = Color(0xFF1A5DC8);
static const Color _blueSoft  = Color(0xFFEEF4FF);
static const Color _textDark  = Color(0xFF1A2340);
static const Color _textGray  = Color(0xFF6B7A99);
static const Color _card      = Colors.white;
static const Color _success   = Color(0xFF16A34A);
static const Color _danger    = Color(0xFFE53935);

  int _selectedNav = 4; // Admin seleccionado

  // Lista de usuarios (mutable para agregar/eliminar)
final List<Map<String, dynamic>> _users = [
    {'initials': 'JD', 'name': 'Javier Dominguez', 'role': 'Admin',    'active': true,  'color': Color(0xFF1A5DC8)},
    {'initials': 'ML', 'name': 'Marta López',       'role': 'Operador', 'active': true,  'color': Color(0xFF7C3AED)},
];

final List<Map<String, dynamic>> _activity = [
    {
    'icon': Icons.login_rounded,
    'iconColor': Color(0xFF1A5DC8),
    'text': 'Javier Dominguez inició sesión en el Panel de Administración',
    'meta': 'Hace 12 minutos  •  IP 192.168.1.45',
    },
    {
    'icon': Icons.settings_rounded,
    'iconColor': Color(0xFF6B7A99),
    'text': 'Configuración de Cámara Central actualizada por Marta López',
    'meta': 'Hace 45 minutos  •  Operación Exitosa',
    },
    {
    'icon': Icons.person_add_rounded,
    'iconColor': Color(0xFF16A34A),
    'text': 'Nuevo dispositivo registrado por Admin en Zona B',
    'meta': 'Hace 1 hora  •  Dispositivo: CAM-012',
    },
];

@override
Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: _bg,
    body: SafeArea(
        child: Column(
        children: [
            _buildTopBar(),
            Expanded(
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const SizedBox(height: 16),
                    _buildServerCards(),
                    const SizedBox(height: 22),
                    _buildGestionUsuarios(),
                    const SizedBox(height: 22),
                    _buildActividadReciente(),
                    const SizedBox(height: 20),
                ],
                ),
            ),
            ),
            _buildBottomNav(),
        ],
        ),
    ),
    );
}

  // ── TOP BAR ───────────────────────────────────────────────────
Widget _buildTopBar() {
    return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    color: _card,
    child: Row(
        children: [
        Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        const Text('Sentinel Surveillance',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textDark)),
        const Spacer(),
        CircleAvatar(
            radius: 18,
            backgroundColor: _blue.withOpacity(0.15),
            child: const Icon(Icons.person_rounded, color: _blue, size: 20),
        ),
        ],
    ),
    );
}

  // ── SERVER STATUS CARDS ───────────────────────────────────────
Widget _buildServerCards() {
    return Column(
    children: [
        _serverCard(
        icon: Icons.dns_rounded,
        label: 'ESTADO DEL SERVIDOR',
        name: 'Core Sentinel-01',
        status: 'En línea',
        statusColor: _success,
        ),
        const SizedBox(height: 10),
        _serverCard(
        icon: Icons.storage_rounded,
        label: 'BASE DE DATOS',
        name: 'Surveillance-DB',
        status: 'Conectado',
        statusColor: _success,
        ),
    ],
    );
}

Widget _serverCard({
    required IconData icon,
    required String label,
    required String name,
    required String status,
    required Color statusColor,
}) {
    return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
        ],
    ),
    child: Row(
        children: [
        Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
            color: _blueSoft,
            borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _blue, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(label,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: _textGray, letterSpacing: 0.7)),
                const SizedBox(height: 3),
                Text(name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: _textDark)),
            ],
            ),
        ),
        Row(
            children: [
            Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(status,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
            ],
        ),
        ],
    ),
    );
}

  // ── GESTIÓN DE USUARIOS ───────────────────────────────────────
Widget _buildGestionUsuarios() {
    return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
        const Text('Gestión de Usuarios',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 4),
        const Text('Administra accesos, roles y permisos del sistema.',
            style: TextStyle(fontSize: 12, color: _textGray)),
        const SizedBox(height: 14),

        // Botón nuevo usuario
        SzedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
            onPressed: _showAddUserDialog,
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('Nuevo Usuario',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
            backgroundColor: _blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
        ),
        ),
        const SizedBox(height: 14),

        // Lista de usuarios
        ..._users.asMap().entries.map((e) => _buildUserCard(e.value, e.key)).toList(),
    ],
    );
}

Widget _buildUserCard(Map<String, dynamic> user, int index) {
    return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
        ],
    ),
    child: Column(
        children: [
        Row(
            children: [
              // Avatar con iniciales
            CircleAvatar(
                radius: 22,
                backgroundColor: (user['color'] as Color).withOpacity(0.15),
                child: Text(
                user['initials'],
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: user['color'] as Color),
                ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(user['name'],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                            color: _textDark)),
                    const SizedBox(height: 2),
                    Text(user['role'],
                        style: const TextStyle(fontSize: 12, color: _textGray)),
                ],
                ),
            ),
              // Badge activo/inactivo
            GestureDetector(
                onTap: () => setState(() => _users[index]['active'] = !_users[index]['active']),
                child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                    color: user['active']
                        ? _success.withOpacity(0.12)
                        : _danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                    user['active'] ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: user['active'] ? _success : _danger),
                ),
                ),
            ),
            ],
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        const SizedBox(height: 8),
        Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
            GestureDetector(
                onTap: () => _showManageUserDialog(user),
                child: const Text('Gestionar',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: _blue)),
            ),
            const SizedBox(width: 20),
            GestureDetector(
                onTap: () => _confirmDelete(index),
                child: const Text('Eliminar',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: _danger)),
            ),
            ],
        ),
        ],
    ),
    );
}

  // ── ACTIVIDAD RECIENTE ────────────────────────────────────────
Widget _buildActividadReciente() {
    return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
        const Text('Actividad Reciente',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textDark)),
        const SizedBox(height: 14),
        ..._activity.map((a) => _buildActivityItem(a)).toList(),
    ],
    );
}

Widget _buildActivityItem(Map<String, dynamic> a) {
    return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
        ],
    ),
    child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
            color: (a['iconColor'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(a['icon'] as IconData, color: a['iconColor'] as Color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(a['text'],
                    style: const TextStyle(fontSize: 12, color: _textDark, height: 1.4)),
                const SizedBox(height: 4),
                Text(a['meta'],
                    style: const TextStyle(fontSize: 10, color: _textGray)),
            ],
            ),
        ),
        ],
    ),
    );
}

  // ── DIALOGS ───────────────────────────────────────────────────
void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    showDialog(
    context: context,
    builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nuevo Usuario',
            style: TextStyle(fontWeight: FontWeight.w700, color: _textDark)),
        content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            ),
            const SizedBox(height: 12),
            TextField(
            controller: roleCtrl,
            decoration: InputDecoration(
                labelText: 'Rol (Admin / Operador)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            ),
        ],
        ),
        actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: _textGray)),
        ),
        ElevatedButton(
            onPressed: () {
            if (nameCtrl.text.isNotEmpty) {
                final parts = nameCtrl.text.trim().split(' ');
                final initials = parts.length >= 2
                    ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                    : nameCtrl.text.substring(0, 2).toUpperCase();
                setState(() {
                _users.add({
                    'initials': initials,
                    'name': nameCtrl.text.trim(),
                    'role': roleCtrl.text.isEmpty ? 'Operador' : roleCtrl.text.trim(),
                    'active': true,
                    'color': const Color(0xFF16A34A),
                });
                });
            }
            Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
            backgroundColor: _blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Agregar', style: TextStyle(color: Colors.white)),
        ),
        ],
    ),
    );
}

void _showManageUserDialog(Map<String, dynamic> user) {
    showDialog(
    context: context,
    builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Gestionar: ${user['name']}',
            style: const TextStyle(fontWeight: FontWeight.w700, color: _textDark, fontSize: 15)),
        content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            _dialogOption(Icons.swap_horiz_rounded, 'Cambiar Rol'),
            _dialogOption(Icons.lock_reset_rounded, 'Resetear Contraseña'),
            _dialogOption(Icons.history_rounded, 'Ver Historial'),
        ],
        ),
        actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: _textGray)),
        ),
        ],
    ),
    );
}

Widget _dialogOption(IconData icon, String label) {
    return ListTile(
    leading: Icon(icon, color: _blue, size: 22),
    title: Text(label, style: const TextStyle(fontSize: 13, color: _textDark)),
    contentPadding: EdgeInsets.zero,
    onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label ejecutado')),
        );
    },
    );
}

void _confirmDelete(int index) {
    showDialog(
    context: context,
    builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar eliminación',
            style: TextStyle(fontWeight: FontWeight.w700, color: _textDark)),
        content: Text('¿Deseas eliminar a ${_users[index]['name']}?',
            style: const TextStyle(color: _textGray)),
        actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: _textGray)),
        ),
        ElevatedButton(
            onPressed: () {
            setState(() => _users.removeAt(index));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Usuario eliminado')),
                );
            },
            style: ElevatedButton.styleFrom(
            backgroundColor: _danger,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
        ),
        ],
    ),
    );
}

  // ── BOTTOM NAV ────────────────────────────────────────────────
Widget _buildBottomNav() {
    final items = [
    {'icon': Icons.grid_view_rounded,           'label': 'Dashboard'},
    {'icon': Icons.map_rounded,                 'label': 'Map'},
    {'icon': Icons.videocam_rounded,            'label': 'Devices'},
    {'icon': Icons.psychology_rounded,          'label': 'AI Hub'},
    {'icon': Icons.admin_panel_settings_rounded,'label': 'Admin'},
    ];
    return Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
        color: _card,
        boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, -2))
        ],
    ),
    child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
        final sel = i == _selectedNav;
        return GestureDetector(
            onTap: () => setState(() => _selectedNav = i),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                Icon(items[i]['icon'] as IconData,
                    color: sel ? _blue : _textGray, size: 24),
                const SizedBox(height: 4),
                Text(items[i]['label'] as String,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel ? _blue : _textGray)),
            ],
            ),
        );
        }),
    ),
    );
}
}