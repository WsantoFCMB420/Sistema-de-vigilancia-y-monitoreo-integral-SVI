import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import 'playback.dart';

/// Android, iOS y escritorio: reproducción con el plugin video_player.
class VideoPlayerPlayback implements Playback {
  VideoPlayerPlayback(Uri url) : _c = VideoPlayerController.networkUrl(url);

  final VideoPlayerController _c;

  @override
  Future<void> initialize() => _c.initialize();
  @override
  Future<void> play() => _c.play();
  @override
  Future<void> pause() => _c.pause();
  @override
  Future<void> seekTo(Duration position) => _c.seekTo(position);
  @override
  Future<Duration> get position async => await _c.position ?? _c.value.position;
  @override
  Duration get duration => _c.value.duration;
  @override
  bool get isPlaying => _c.value.isPlaying;
  @override
  double get aspectRatio => _c.value.aspectRatio > 0 ? _c.value.aspectRatio : 16 / 9;
  @override
  Widget view() => VideoPlayer(_c);
  @override
  void dispose() => _c.dispose();
}
