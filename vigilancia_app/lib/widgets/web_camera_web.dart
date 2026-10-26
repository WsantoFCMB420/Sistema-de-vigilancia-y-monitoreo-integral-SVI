// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

/// Transmisión de la webcam del navegador mostrada con un <video>.
class WebCameraSession {
  final String viewId;
  final html.MediaStream _stream;
  WebCameraSession._(this.viewId, this._stream);

  void setEnabled(bool enabled) {
    for (final track in _stream.getVideoTracks()) {
      track.enabled = enabled;
    }
  }

  void stop() {
    for (final track in _stream.getTracks()) {
      track.stop();
    }
  }
}

/// Pide permiso y abre la webcam. Devuelve null si el navegador no la ofrece.
Future<WebCameraSession?> startWebCamera() async {
  final mediaDevices = html.window.navigator.mediaDevices;
  if (mediaDevices == null) return null;

  final stream = await mediaDevices.getUserMedia({
    'video': {
      'width': {'ideal': 1280},
      'height': {'ideal': 720},
    },
    'audio': false,
  });

  final viewId = 'webcam-html-${DateTime.now().millisecondsSinceEpoch}';
  final video = html.VideoElement()
    ..srcObject = stream
    ..autoplay = true
    ..muted = true
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.objectFit = 'cover';

  ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) => video);
  return WebCameraSession._(viewId, stream);
}
