import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class FaceCaptureScreen extends StatefulWidget {
  const FaceCaptureScreen({super.key});
  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  XFile? captured;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      cameras = await availableCameras();
      final front = cameras!.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras!.first);
      controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await controller!.initialize();
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _capture() async {
    if (controller == null || !controller!.value.isInitialized) return;
    final file = await controller!.takePicture();
    setState(() => captured = file);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Wajah')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: captured == null
                            ? CameraPreview(controller!)
                            : Image.file(File(captured!.path), fit: BoxFit.cover),
                      ),
                      // Overlay guide
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              width: 240,
                              height: 320,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white.withOpacity(0.85), width: 3),
                                borderRadius: BorderRadius.circular(24),
                                color: Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: captured != null ? () => setState(() => captured = null) : null,
                          child: const Text('Ulang'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _capture,
                          child: Text(captured == null ? 'Ambil' : 'Gunakan'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}
