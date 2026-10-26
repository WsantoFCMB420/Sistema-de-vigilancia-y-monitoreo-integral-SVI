/// Versión para Android, iOS y escritorio: la webcam del navegador no aplica.
class WebCameraSession {
  final String viewId;
  const WebCameraSession._(this.viewId);

  void setEnabled(bool enabled) {}

  void stop() {}
}

Future<WebCameraSession?> startWebCamera() async => null;
