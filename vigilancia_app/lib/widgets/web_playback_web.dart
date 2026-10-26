// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

import 'playback.dart';

/// Reproductor web con un <video> del navegador, el mismo que usa Chrome al
/// abrir el archivo directamente. Los controles los dibuja Flutter.
Playback? createWebPlayback(Uri url) => _HtmlVideoPlayback(url);

class _HtmlVideoPlayback implements Playback {
  _HtmlVideoPlayback(this.url);

  final Uri url;
  late final html.VideoElement _video;
  late final String _viewId;

  @override
  Future<void> initialize() async {
    _viewId = 'svi-recording-${DateTime.now().microsecondsSinceEpoch}';
    _video = html.VideoElement()
      ..src = url.toString()
      ..preload = 'auto'
      ..controls = false
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'contain'
      ..style.backgroundColor = 'black'
      ..style.pointerEvents = 'none'
      ..setAttribute('playsinline', 'true');
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int id) => _video);

    final ready = Completer<void>();
    late StreamSubscription<html.Event> okSub;
    late StreamSubscription<html.Event> errSub;
    okSub = _video.onLoadedMetadata.listen((_) {
      if (!ready.isCompleted) ready.complete();
    });
    errSub = _video.onError.listen((_) {
      if (!ready.isCompleted) ready.completeError(StateError('No se pudo cargar el video'));
    });
    _video.load();
    try {
      await ready.future.timeout(const Duration(seconds: 20));
    } finally {
      await okSub.cancel();
      await errSub.cancel();
    }
  }

  @override
  Future<void> play() async {
    try {
      await _video.play();
    } catch (_) {}
  }

  @override
  Future<void> pause() async => _video.pause();

  @override
  Future<void> seekTo(Duration position) async {
    _video.currentTime = position.inMilliseconds / 1000.0;
  }

  @override
  Future<Duration> get position async =>
      Duration(milliseconds: ((_video.currentTime) * 1000).round());

  @override
  Duration get duration {
    final d = _video.duration.toDouble();
    if (d.isNaN || d.isInfinite || d <= 0) return Duration.zero;
    return Duration(milliseconds: (d * 1000).round());
  }

  @override
  bool get isPlaying => !_video.paused && !_video.ended;

  @override
  double get aspectRatio {
    final w = _video.videoWidth;
    final h = _video.videoHeight;
    return (w > 0 && h > 0) ? w / h : 16 / 9;
  }

  @override
  Widget view() => HtmlElementView(viewType: _viewId);

  @override
  void dispose() {
    _video.pause();
    _video.removeAttribute('src');
    _video.load();
  }
}
