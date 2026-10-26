// En web se reproduce con un <video> nativo; en las demás plataformas no aplica.
export 'web_playback_stub.dart' if (dart.library.html) 'web_playback_web.dart';
