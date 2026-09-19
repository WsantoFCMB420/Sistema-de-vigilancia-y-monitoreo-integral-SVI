import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Vista en vivo de la cámara del celular o webcam del computador.
class LocalCameraPreview extends StatefulWidget {
  final bool playing;

  const LocalCameraPreview({super.key, this.playing = true});

  @override
  State<LocalCameraPreview> createState() => _LocalCameraPreviewState();
}

class _LocalCameraPreviewState extends State<LocalCameraPreview> {
  CameraController? _controller;
  String? _error;
  bool _loading = true;
  bool _paused = false;

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
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        setState(() {
          _loading = false;
          _error =
              'No se encontró ninguna cámara. En el celular concede el permiso; en el computador conecta una webcam.';
        });
        return;
      }

      final selected = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
      await _syncPlayback();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'No se pudo iniciar la cámara. Revisa el permiso de cámara e inténtalo de nuevo.';
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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A5DC8)),
      );
    }
    if (_error != null) {
      return Center(
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
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _start();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller!;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 1280,
          height: controller.value.previewSize?.width ?? 720,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}
