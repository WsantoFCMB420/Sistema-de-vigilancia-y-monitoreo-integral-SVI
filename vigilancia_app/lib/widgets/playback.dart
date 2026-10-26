import 'package:flutter/widgets.dart';

/// Reproductor mínimo que usa el diálogo de grabaciones.
/// En web se usa un <video> nativo del navegador; en Android, video_player.
abstract class Playback {
  Future<void> initialize();
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<Duration> get position;

  /// Duración del archivo; Duration.zero si el archivo no la informa.
  Duration get duration;
  bool get isPlaying;
  double get aspectRatio;
  Widget view();
  void dispose();
}
