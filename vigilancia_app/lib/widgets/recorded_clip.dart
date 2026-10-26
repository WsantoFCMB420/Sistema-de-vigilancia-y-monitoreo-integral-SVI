import 'dart:typed_data';

/// Video grabado en el dispositivo, listo para subir a la API.
class RecordedClip {
  final Uint8List bytes;

  /// Extensión del archivo sin punto: webm (navegador) o mp4 (Android).
  final String extension;
  final Duration duration;

  const RecordedClip({
    required this.bytes,
    required this.extension,
    required this.duration,
  });
}
