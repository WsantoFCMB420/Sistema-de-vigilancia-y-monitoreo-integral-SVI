// Acceso a la webcam del navegador.
//
// `dart:html` solo existe al compilar para web. Con este import condicional
// el APK (y Windows) usan una versión vacía y compilan sin errores.
export 'web_camera_stub.dart' if (dart.library.html) 'web_camera_web.dart';
export 'recorded_clip.dart';
