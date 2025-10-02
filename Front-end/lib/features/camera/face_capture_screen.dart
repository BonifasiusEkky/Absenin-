import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/location_access_provider.dart';
import '../../services/location_service.dart';

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
    final access = context.watch<LocationAccessProvider>();
    // If user navigated here without passing verification, show blocking UI.
    if (!access.isAuthorized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan Wajah')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text('Verifikasi lokasi diperlukan sebelum scan wajah', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (access.lastResult?.message != null)
                  Text(
                    access.lastResult!.message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: access.checking
                      ? null
                      : () async {
                          final res = await access.verify();
                          if (res.status == LocationCheckStatus.inside && context.mounted) {
                            setState(() {}); // rebuild to show camera
                          }
                        },
                  icon: access.checking
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(access.checking ? 'Memeriksa...' : 'Cek Lokasi'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kembali'),
                )
              ],
            ),
          ),
        ),
      );
    }
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
