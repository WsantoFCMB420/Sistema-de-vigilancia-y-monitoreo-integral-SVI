// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import '../utils/webm_duration.dart';
import 'recorded_clip.dart';

/// Transmisión de la webcam del navegador mostrada con un <video>.
/// También graba clips con MediaRecorder (formato webm).
class WebCameraSession {
  final String viewId;
  final html.MediaStream _stream;
  WebCameraSession._(this.viewId, this._stream);

  html.MediaRecorder? _recorder;
  final List<html.Blob> _chunks = [];
  DateTime? _recordingStarted;
  String _mime = 'video/webm';

  void setEnabled(bool enabled) {
    for (final track in _stream.getVideoTracks()) {
      track.enabled = enabled;
    }
  }

  void stop() {
    try {
      _recorder?.stop();
    } catch (_) {}
    for (final track in _stream.getTracks()) {
      track.stop();
    }
  }

  bool get canRecord {
    try {
      return html.MediaRecorder.isTypeSupported('video/webm');
    } catch (_) {
      return false;
    }
  }

  void startRecording() {
    _chunks.clear();
    for (final candidate in const ['video/webm;codecs=vp9', 'video/webm;codecs=vp8', 'video/webm']) {
      if (html.MediaRecorder.isTypeSupported(candidate)) {
        _mime = candidate;
        break;
      }
    }
    final recorder = html.MediaRecorder(_stream, {'mimeType': _mime});
    recorder.addEventListener('dataavailable', (html.Event event) {
      final data = (event as html.BlobEvent).data;
      if (data != null && data.size > 0) _chunks.add(data);
    });
    recorder.start(1000); // un fragmento por segundo
    _recorder = recorder;
    _recordingStarted = DateTime.now();
  }

  Future<RecordedClip?> stopRecording() async {
    final recorder = _recorder;
    if (recorder == null) return null;
    _recorder = null;

    final stopped = Completer<void>();
    recorder.addEventListener('stop', (_) {
      if (!stopped.isCompleted) stopped.complete();
    });
    recorder.stop();
    await stopped.future.timeout(const Duration(seconds: 5), onTimeout: () {});

    if (_chunks.isEmpty) return null;
    final blob = html.Blob(List<Object>.from(_chunks), 'video/webm');
    _chunks.clear();

    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);
    await reader.onLoadEnd.first;
    final result = reader.result;
    final Uint8List bytes;
    if (result is Uint8List) {
      bytes = result;
    } else if (result is ByteBuffer) {
      bytes = result.asUint8List();
    } else {
      return null;
    }

    final started = _recordingStarted ?? DateTime.now();
    final duration = DateTime.now().difference(started);
    return RecordedClip(
      // MediaRecorder no escribe la duración; sin ella el reproductor no
      // muestra el tiempo real ni permite adelantar.
      bytes: fixWebmDuration(bytes, duration),
      extension: 'webm',
      duration: duration,
    );
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
