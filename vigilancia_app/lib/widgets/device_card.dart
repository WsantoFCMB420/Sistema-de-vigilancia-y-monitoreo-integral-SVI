import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DeviceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final String imageUrl;
  final bool isPtz;
  final String streamUrl;
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
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  Color get _statusColor {
    switch (status) {
      case 'Activo':        return const Color(0xFF2E7D32);
      case 'Inactivo':      return const Color(0xFFE53935);
      case 'Mantenimiento': return const Color(0xFFF57C00);
      default:              return const Color(0xFF6B7A99);
    }
  }

  Color get _statusBg {
    switch (status) {
      case 'Activo':        return const Color(0xFFE8F5E9);
      case 'Inactivo':      return const Color(0xFFFDECEC);
      case 'Mantenimiento': return const Color(0xFFFFF3E0);
      default:              return const Color(0xFFF4F7FB);
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case 'Activo':        return Icons.wifi_rounded;
      case 'Inactivo':      return Icons.wifi_off_rounded;
      case 'Mantenimiento': return Icons.build_rounded;
      default:              return Icons.device_unknown_rounded;
    }
  }

  IconData get _deviceIcon {
    final t = title.toLowerCase();
    if (t.contains('cámara') || t.contains('camara') || t.contains('cam') || streamUrl.isNotEmpty) {
      return Icons.videocam_rounded;
    } else if (t.contains('sensor')) {
      return Icons.sensors_rounded;
    } else if (t.contains('acceso') || t.contains('puerta')) {
      return Icons.door_front_door_rounded;
    } else if (t.contains('alarma')) {
      return Icons.notifications_active_rounded;
    }
    return Icons.devices_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Ícono del dispositivo ────────────────────────────
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A5DC8).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              _deviceIcon,
                              color: const Color(0xFF1A5DC8),
                              size: 24,
                            ),
                          ),
                        )
                      : Icon(_deviceIcon, color: const Color(0xFF1A5DC8), size: 24),
                ),
                const SizedBox(width: 10),

                // ── Nombre y descripción (Expanded con flexible constraints) ─
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
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: c.text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPtz) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A5DC8).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PTZ',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A5DC8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle.isNotEmpty
                            ? subtitle
                            : (streamUrl.isNotEmpty ? streamUrl : 'Sin descripción'),
                        style: TextStyle(
                          fontSize: 11,
                          color: c.label,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // ── Acciones y Estado (Optimizadas para mobile portrait sin clipping) ─
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onEdit != null) ...[
                          GestureDetector(
                            onTap: onEdit,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A5DC8).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.edit_outlined, color: Color(0xFF1A5DC8), size: 15),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (onDelete != null) ...[
                          GestureDetector(
                            onTap: onDelete,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE53935), size: 15),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _statusColor.withValues(alpha: 0.3), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_statusIcon, color: _statusColor, size: 10),
                              const SizedBox(width: 3),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (onTap != null) ...[
                      const SizedBox(height: 4),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Ver feed', style: TextStyle(fontSize: 10, color: Color(0xFF1A5DC8), fontWeight: FontWeight.w600)),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, size: 12, color: Color(0xFF1A5DC8)),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
