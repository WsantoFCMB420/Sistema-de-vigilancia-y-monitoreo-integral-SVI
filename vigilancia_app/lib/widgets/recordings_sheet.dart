import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/bogota_time.dart';
import 'playback.dart';
import 'video_player_playback.dart';
import 'web_playback.dart';

/// Lista de grabaciones de una cámara (o de todas las del usuario).
/// Al tocar una se abre el reproductor con la línea de tiempo.
class RecordingsSheet extends StatefulWidget {
  final int? deviceId;
  final String title;
  const RecordingsSheet({super.key, this.deviceId, required this.title});

  static Future<void> show(BuildContext context, {int? deviceId, required String title}) {
    return showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 620),
      builder: (_) => RecordingsSheet(deviceId: deviceId, title: title),
    );
  }

  @override
  State<RecordingsSheet> createState() => _RecordingsSheetState();
}

class _RecordingsSheetState extends State<RecordingsSheet> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getRecordings(deviceId: widget.deviceId);
      if (!mounted) return;
      setState(() {
        _items = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar grabación?'),
        content: const Text('El video se borra del servidor y no se puede recuperar.'),
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
    if (ok != true) return;
    try {
      await ApiService.deleteRecording(item['id'] as int);
      if (!mounted) return;
      setState(() => _items.removeWhere((e) => e['id'] == item['id']));
      showAppSnackBar(context, 'Grabación eliminada');
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.toString().replaceFirst('Exception: ', ''), backgroundColor: AppColors.danger);
    }
  }

  static String formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String formatSize(int bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: c.tint(AppColors.primary), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.video_library_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Grabaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text)),
                      Text(widget.title, style: TextStyle(fontSize: 12, color: c.label)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar',
                  onPressed: _loading ? null : _load,
                  icon: Icon(Icons.refresh_rounded, color: c.label),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody(c)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppColors c) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.danger, size: 40),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: c.label)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 46, color: c.hint),
            const SizedBox(height: 10),
            Text('Aún no hay grabaciones',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
            const SizedBox(height: 6),
            Text('Usa el botón rojo de grabar en la vista en vivo para guardar un clip.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: c.label)),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: c.border),
      itemBuilder: (_, i) {
        final item = _items[i];
        final when = BogotaTime.fromApi(
          iso: item['created_at']?.toString(),
          localDate: item['local_date']?.toString(),
          localTime: item['local_time']?.toString(),
        );
        final seconds = (item['duration_seconds'] as num?)?.toInt() ?? 0;
        final size = (item['size_bytes'] as num?)?.toInt() ?? 0;
        final device = (item['device_name'] ?? '').toString();
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
          ),
          title: Text('${BogotaTime.dayLabel(when)} · ${BogotaTime.hourLabel(when)}',
              style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
          subtitle: Text(
            [formatDuration(seconds), formatSize(size), if (device.isNotEmpty && widget.deviceId == null) device]
                .join(' · '),
            style: TextStyle(fontSize: 12, color: c.label),
          ),
          trailing: IconButton(
            tooltip: 'Eliminar',
            onPressed: () => _delete(item),
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
          ),
          onTap: () => RecordingPlayerDialog.show(
            context,
            url: ApiService.recordingUri((item['url'] ?? '').toString()),
            title: '${BogotaTime.dayLabel(when)} · ${BogotaTime.hourLabel(when)}',
            fallbackDuration: Duration(seconds: seconds),
          ),
        );
      },
    );
  }
}

/// Reproductor de una grabación. Aquí sí va la línea de tiempo para
/// adelantar y retroceder, porque el video ya está grabado.
///
/// El estado (reproduciendo, posición) se consulta cada 250 ms directamente al
/// reproductor, y la duración usa la que guardó la API si el archivo no la trae.
class RecordingPlayerDialog extends StatefulWidget {
  final Uri url;
  final String title;
  final Duration fallbackDuration;
  const RecordingPlayerDialog({
    super.key,
    required this.url,
    required this.title,
    this.fallbackDuration = Duration.zero,
  });

  static Future<void> show(
    BuildContext context, {
    required Uri url,
    required String title,
    Duration fallbackDuration = Duration.zero,
  }) {
    return showDialog(
      context: context,
      builder: (_) => RecordingPlayerDialog(url: url, title: title, fallbackDuration: fallbackDuration),
    );
  }

  @override
  State<RecordingPlayerDialog> createState() => _RecordingPlayerDialogState();
}

class _RecordingPlayerDialogState extends State<RecordingPlayerDialog> {
  late final Playback _video;
  Timer? _poll;
  bool _ready = false;
  bool _playing = false;
  String? _error;
  Duration _position = Duration.zero;
  double? _dragMs; // valor de la barra mientras el usuario la arrastra

  @override
  void initState() {
    super.initState();
    // En web: <video> nativo del navegador. En el celular: video_player.
    _video = createWebPlayback(widget.url) ?? VideoPlayerPlayback(widget.url);
    _video.initialize().then((_) async {
      if (!mounted) return;
      setState(() => _ready = true);
      await _play();
      _poll = Timer.periodic(const Duration(milliseconds: 250), (_) => _refresh());
    }).catchError((Object e) {
      if (mounted) setState(() => _error = 'No se pudo reproducir el video.');
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _video.dispose();
    super.dispose();
  }

  /// Duración válida: la del archivo si es razonable; si no, la de la API.
  Duration get _total {
    final d = _video.duration;
    if (d > Duration.zero && d < const Duration(hours: 6)) return d;
    return widget.fallbackDuration;
  }

  Future<void> _refresh() async {
    if (!mounted || !_ready) return;
    final pos = await _video.position;
    if (!mounted) return;
    final total = _total;
    var playing = _video.isPlaying;
    // Al llegar al final se marca como pausado para mostrar "repetir".
    if (total > Duration.zero && pos >= total - const Duration(milliseconds: 200)) {
      playing = false;
    }
    setState(() {
      _position = pos;
      _playing = playing;
    });
  }

  Future<void> _play() async {
    final total = _total;
    if (total > Duration.zero && _position >= total - const Duration(milliseconds: 200)) {
      await _video.seekTo(Duration.zero);
    }
    await _video.play();
    if (mounted) setState(() => _playing = true);
  }

  Future<void> _pause() async {
    await _video.pause();
    if (mounted) setState(() => _playing = false);
  }

  Future<void> _seek(Duration target) async {
    final total = _total;
    var t = target < Duration.zero ? Duration.zero : target;
    if (total > Duration.zero && t > total) t = total;
    setState(() => _position = t);
    await _video.seekTo(t);
    await _refresh();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final total = _total;
    final maxMs = total.inMilliseconds > 0 ? total.inMilliseconds.toDouble() : 1.0;
    final posMs = (_dragMs ?? _position.inMilliseconds.toDouble()).clamp(0.0, maxMs);
    final shown = Duration(milliseconds: posMs.round());
    final atEnd = total > Duration.zero && _position >= total - const Duration(milliseconds: 200);

    return Dialog(
      backgroundColor: const Color(0xFF0D1117),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
              child: Row(
                children: [
                  const Icon(Icons.video_library_rounded, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: _ready ? _video.aspectRatio : 16 / 9,
              child: _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white70)))
                  : _ready
                      ? GestureDetector(
                          onTap: () => _playing ? _pause() : _play(),
                          child: _video.view(),
                        )
                      : const Center(child: CircularProgressIndicator()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: _playing ? 'Pausar' : (atEnd ? 'Repetir' : 'Reproducir'),
                    onPressed: !_ready ? null : () => _playing ? _pause() : _play(),
                    icon: Icon(
                      _playing ? Icons.pause_rounded : (atEnd ? Icons.replay_rounded : Icons.play_arrow_rounded),
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Retroceder 10 s',
                    onPressed: !_ready ? null : () => _seek(_position - const Duration(seconds: 10)),
                    icon: const Icon(Icons.replay_10_rounded, color: Colors.white70),
                  ),
                  IconButton(
                    tooltip: 'Adelantar 10 s',
                    onPressed: !_ready ? null : () => _seek(_position + const Duration(seconds: 10)),
                    icon: const Icon(Icons.forward_10_rounded, color: Colors.white70),
                  ),
                  Text(_fmt(shown), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: posMs,
                      max: maxMs,
                      activeColor: AppColors.primary,
                      inactiveColor: Colors.white24,
                      onChangeStart: !_ready ? null : (v) => setState(() => _dragMs = v),
                      onChanged: !_ready ? null : (v) => setState(() => _dragMs = v),
                      onChangeEnd: !_ready
                          ? null
                          : (v) async {
                              setState(() => _dragMs = null);
                              await _seek(Duration(milliseconds: v.round()));
                            },
                    ),
                  ),
                  Text(_fmt(total), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
