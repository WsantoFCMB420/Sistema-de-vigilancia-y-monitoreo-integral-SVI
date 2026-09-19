import 'package:flutter/material.dart';

class DeviceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final String imageUrl;
  final bool isPtz;
  final String streamUrl;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4EAF5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ── Ícono del dispositivo ────────────────────────────
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A5DC8).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              _deviceIcon,
                              color: const Color(0xFF1A5DC8),
                              size: 26,
                            ),
                          ),
                        )
                      : Icon(_deviceIcon, color: const Color(0xFF1A5DC8), size: 26),
                ),
                const SizedBox(width: 14),

                // ── Nombre y descripción ─────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A2340),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPtz) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A5DC8).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PTZ',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A5DC8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle.isNotEmpty
                            ? subtitle
                            : (streamUrl.isNotEmpty ? streamUrl : 'Sin descripción'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7A99),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // ── Badge de estado ──────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onDelete != null) ...[
                          GestureDetector(
                            onTap: onDelete,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE53935), size: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _statusBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _statusColor.withValues(alpha: 0.3), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_statusIcon, color: _statusColor, size: 11),
                              const SizedBox(width: 4),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
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
                          Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF1A5DC8)),
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