import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraApp extends StatefulWidget {
  const CameraApp({super.key});

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void> _operation = Future<void>.value();
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openCamera();
  }

  void _openCamera() {
    final generation = ++_generation;
    setState(() => _error = null);
    // Serialize camera operations when permission prompts change lifecycle.
    _operation = _operation.then((_) async {
      if (!mounted || generation != _generation) return;
      CameraController? controller;
      try {
        final cameras = await availableCameras();
        if (!mounted || generation != _generation) return;
        if (cameras.isEmpty) {
          setState(() => _error = 'Tidak ada kamera pada perangkat ini.');
          return;
        }
        controller = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await controller.initialize();
        if (!mounted || generation != _generation) {
          await controller.dispose();
          return;
        }
        setState(() => _controller = controller);
      } catch (error) {
        await controller?.dispose();
        if (!mounted || generation != _generation) return;
        setState(() {
          _error = switch (error) {
            CameraException(code: 'CameraAccessDenied') =>
              'Izin kamera ditolak. Izinkan kamera di pengaturan aplikasi, lalu coba lagi.',
            CameraException(code: 'CameraAccessDeniedWithoutPrompt') =>
              'Aktifkan izin kamera di pengaturan aplikasi, lalu coba lagi.',
            CameraException(code: 'CameraAccessRestricted') =>
              'Akses kamera dibatasi oleh pengaturan perangkat.',
            _ =>
              'Kamera tidak dapat dibuka. Pastikan kamera tersedia dan tidak digunakan aplikasi lain, lalu coba lagi.',
          };
        });
      }
    });
  }

  void _releaseCamera() {
    ++_generation;
    final controller = _controller;
    _controller = null;
    _operation = _operation.then((_) async {
      await controller?.dispose();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _openCamera();
    } else {
      _releaseCamera();
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _releaseCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Kamera')),
      body: SafeArea(
        child: Center(
          child: _error != null
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _openCamera,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                )
              : controller == null
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Membuka kamera...'),
                  ],
                )
              : CameraPreview(controller),
        ),
      ),
    );
  }
}
