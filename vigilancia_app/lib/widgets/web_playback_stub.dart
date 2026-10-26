import 'playback.dart';

/// Fuera de la web no hay <video> nativo: se usa video_player.
Playback? createWebPlayback(Uri url) => null;
