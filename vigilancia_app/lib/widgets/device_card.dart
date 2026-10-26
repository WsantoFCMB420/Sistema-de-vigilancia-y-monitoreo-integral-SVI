import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DeviceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final String imageUrl;
  final bool isPtz;
  final String streamUrl;

  /// Nombre de quien registró el dispositivo (solo se muestra al admin).
  final String? owner;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const DeviceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.imageUrl,
    this.isPtz = false,
    this.streamUrl = '',
    this.owner,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  Color get _statusColor {
    switch (status) {
      case 'Activo':
        return AppColors.success;
      case 'Inactivo':
        return AppColors.danger;
      case 'Mantenimiento':
        return AppColors.warning;
      default:
        return const Color(0xFF6B7A99);
    }
  }

  IconData get _deviceIcon {
    final t = title.toLowerCase();
    if (t.contains('sensor')) return Icons.sensors_rounded;
    if (t.contains('acceso') || t.contains('puerta')) return Icons.door_front_door_rounded;
    if (t.contains('alarma')) return Icons.notifications_active_rounded;
    if (t.contains('cámara') || t.contains('camara') || t.contains('cam') || streamUrl.isNotEmpty) {
      return Icons.videocam_rounded;
    }
    return Icons.devices_rounded;
  }

  bool get _isLocal => streamUrl.startsWith('local://');

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final statusColor = _statusColor;
    final details = subtitle.isNotEmpty
        ? subtitle
        : (_isLocal ? 'Cámara del equipo' : (streamUrl.isNotEmpty ? streamUrl : 'Sin descripción'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.border),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                // Ícono con indicador de estado
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: c.tint(AppColors.primary),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Icon(_deviceIcon, color: AppColors.primary, size: 24),
                              ),
                            )
                          : Icon(_deviceIcon, color: AppColors.primary, size: 24),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.card, width: 2.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.text),
                            ),
                          ),
                          if (isPtz) ...[
                            const SizedBox(width: 6),
                            _tag('PTZ', AppColors.primary, c),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: c.label),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _tag(status, statusColor, c),
                          if (owner != null && owner!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.person_outline_rounded, size: 13, color: c.hint),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                owner!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: c.hint),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    tooltip: 'Opciones',
                    icon: Icon(Icons.more_vert_rounded, color: c.label),
                    onSelected: (v) {
                      if (v == 'edit') onEdit?.call();
                      if (v == 'delete') onDelete?.call();
                    },
                    itemBuilder: (_) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('Editar'),
                          ]),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                            SizedBox(width: 10),
                            Text('Eliminar', style: TextStyle(color: AppColors.danger)),
                          ]),
                        ),
                    ],
                  )
                else if (onTap != null)
                  Icon(Icons.chevron_right_rounded, color: c.hint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, Color color, AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.tint(color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
