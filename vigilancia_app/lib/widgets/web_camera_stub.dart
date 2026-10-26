import 'recorded_clip.dart';

/// Versión para Android, iOS y escritorio: la webcam del navegador no aplica.
class WebCameraSession {
  final String viewId;
  const WebCameraSession._(this.viewId);

  void setEnabled(bool enabled) {}

  void stop() {}

  bool get canRecord => false;

  void startRecording() {}

  Future<RecordedClip?> stopRecording() async => null;
}

Future<WebCameraSession?> startWebCamera() async => null;
