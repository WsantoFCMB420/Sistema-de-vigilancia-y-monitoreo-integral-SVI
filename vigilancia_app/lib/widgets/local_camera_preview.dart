import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Vista en vivo de la webcam del portátil o de una cámara USB conectada.
class LocalCameraPreview extends StatefulWidget {
  final bool playing;
  final bool showDevicePicker;
  final ValueChanged<CameraDescription>? onCameraSelected;

  const LocalCameraPreview({
    super.key,
    this.playing = true,
    this.showDevicePicker = true,
    this.onCameraSelected,
  });

  @override
  State<LocalCameraPreview> createState() => LocalCameraPreviewState();
}

class LocalCameraPreviewState extends State<LocalCameraPreview> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedIndex = 0;
  String? _error;
  bool _loading = true;
  bool _paused = false;

  ImageFormatGroup get _format {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return ImageFormatGroup.yuv420;
      default:
        return ImageFormatGroup.bgra8888;
    }
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant LocalCameraPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playing != widget.playing) {
      _syncPlayback();
    }
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        setState(() {
          _loading = false;
          _error =
              'No se encontró ninguna cámara.\n'
              'Conecta una webcam USB o activa la cámara del portátil.\n'
              'En Windows: Configuración → Privacidad → Cámara → '
              'permite el acceso a las aplicaciones de escritorio.';
        });
        return;
      }

      _cameras = cameras;
      final preferred = _preferredIndex(cameras);
      await _openCamera(preferred);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _describeCameraError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'No se pudo iniciar la cámara.\n'
            'Revisa que no esté en uso por otra aplicación y que Windows '
            'permita el acceso a la cámara.';
      });
    }
  }

  int _preferredIndex(List<CameraDescription> cameras) {
    final usb = cameras.indexWhere((camera) {
      final name = camera.name.toLowerCase();
      return name.contains('usb') ||
          name.contains('external') ||
          camera.lensDirection == CameraLensDirection.external;
    });
    if (usb >= 0) return usb;
    return 0;
  }

  Future<void> _openCamera(int index) async {
    if (index < 0 || index >= _cameras.length) return;

    try {
      final previous = _controller;
      _controller = null;
      await previous?.dispose();

      final selected = _cameras[index];
      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: _format,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _selectedIndex = index;
        _loading = false;
        _paused = false;
        _error = null;
      });
      widget.onCameraSelected?.call(selected);
      await _syncPlayback();
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _describeCameraError(e);
      });
    }
  }

  Future<void> _syncPlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      if (widget.playing && _paused) {
        await controller.resumePreview();
        _paused = false;
      } else if (!widget.playing && !_paused) {
        await controller.pausePreview();
        _paused = true;
      }
    } catch (_) {
      // Algunos plugins de escritorio no implementan pause/resume.
    }
  }

  Future<XFile?> takePicture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return null;
    }
    return controller.takePicture();
  }

  String _describeCameraError(CameraException error) {
    final code = error.code.toLowerCase();
    if (code.contains('access') || code.contains('denied') || code.contains('permission')) {
      return 'Windows bloqueó el acceso a la cámara.\n'
          'Abre Configuración → Privacidad y seguridad → Cámara '
          'y activa el acceso para aplicaciones de escritorio.';
    }
    if (code.contains('audio') || code.contains('inuse') || code.contains('busy')) {
      return 'La cámara está en uso por otra aplicación. Ciérrala e inténtalo de nuevo.';
    }
    return error.description?.isNotEmpty == true
        ? error.description!
        : 'No se pudo iniciar la cámara (${error.code}).';
  }

  String _labelFor(CameraDescription camera, int index) {
    final raw = camera.name.trim();
    if (raw.isEmpty) return 'Cámara ${index + 1}';
    final lower = raw.toLowerCase();
    if (lower.contains('usb')) return 'USB · $raw';
    if (camera.lensDirection == CameraLensDirection.external) return 'USB · $raw';
    if (camera.lensDirection == CameraLensDirection.front) return 'Portátil · $raw';
    if (camera.lensDirection == CameraLensDirection.back) return 'Trasera · $raw';
    return raw;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF1A5DC8)),
        ),
      );
    }

    if (_error != null) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 48),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _start,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final controller = _controller!;
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio == 0
                  ? 16 / 9
                  : controller.value.aspectRatio,
              child: CameraPreview(controller),
            ),
          ),
          if (widget.showDevicePicker && _cameras.length > 1)
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedIndex,
                      dropdownColor: const Color(0xFF0D1117),
                      isDense: true,
                      iconEnabledColor: Colors.white70,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      items: [
                        for (var i = 0; i < _cameras.length; i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text(
                              _labelFor(_cameras[i], i),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (index) {
                        if (index == null || index == _selectedIndex) return;
                        setState(() => _loading = true);
                        _openCamera(index);
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
