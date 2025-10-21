import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../data/providers/location_access_provider.dart';
import '../../services/location_service.dart';
import '../../services/attendance_service.dart';
import '../../services/face_service.dart';
import '../../core/network/api_client.dart';
import '../../core/config/env.dart';
import '../../data/providers/user_provider.dart';
import '../../data/providers/attendance_provider.dart';

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
  bool verifying = false;

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

  Future<void> _verifyAndCheckIn(BuildContext context) async {
    if (captured == null) return;
    setState(() => verifying = true);
    final messenger = ScaffoldMessenger.of(context);
    final api = ApiClient();
    try {
      // 1) Health checks (optional but helpful)
      final faceSvc = FaceService(api);
      final faceOk = await faceSvc.health();
      if (!faceOk) {
        messenger.showSnackBar(const SnackBar(content: Text('Face service tidak siap')));
        setState(() => verifying = false);
        return;
      }

      // 2) Call Laravel proxy /api/face/verify with user_id + image (captured)
      //    Use ApiClient.postMultipart to ensure Accept: application/json header,
      //    so Laravel returns JSON (not HTML redirect) on validation errors.
      final user = context.read<UserProvider>();
      final res = await api.postMultipart(
        Env.api('/api/face/verify'),
        fields: {'user_id': user.backendUserId.toString()},
        files: [await http.MultipartFile.fromPath('image', captured!.path)],
      );
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final verified = json['verified'] == true;
      if (!verified) {
        messenger.showSnackBar(const SnackBar(content: Text('Verifikasi wajah gagal. Coba ulangi.')));
        setState(() => verifying = false);
        return;
      }

      // 3) On success, call attendance check-in
      final now = DateTime.now();
      final attendanceSvc = AttendanceService(api);
      final locProv = context.read<LocationAccessProvider>();
      final distance = locProv.lastResult?.distanceMeters;
      await attendanceSvc.checkIn(
        userId: user.backendUserId.toString(),
        date: DateTime(now.year, now.month, now.day),
        time: now,
        latitude: null, // integrate actual current lat/lng if available
        longitude: null,
        distanceM: distance,
      );
      // Refresh attendance provider
      try {
        final prov = context.read<AttendanceProvider>();
        await prov.loadFromBackend(user);
      } catch (_) {}
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Presensi masuk berhasil')));
        Navigator.of(context).pop();
      }
    } on ApiError catch (e) {
      // Try to parse JSON error from backend to show clearer message
      String msg = 'Gagal verifikasi wajah (HTTP ${e.statusCode}).';
      try {
        final body = jsonDecode(e.body);
        if (body is Map<String, dynamic>) {
          // Laravel validation
          if (body['errors'] is Map) {
            final errors = body['errors'] as Map;
            final flat = errors.values.expand((v) => (v as List).map((x) => x.toString())).join('\n');
            msg = flat.isNotEmpty ? flat : msg;
          }
          // Face-service or proxy error
          else if (body['ok'] == false && body['error'] is String) {
            msg = body['error'];
          } else if (body['verified'] == false) {
            msg = 'Wajah tidak cocok dengan data terdaftar. Coba ulangi dengan posisi wajah jelas.';
          }
        }
      } catch (_) {}
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } on SocketException catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Tidak dapat terhubung ke server. Periksa koneksi internet atau server offline.')));
    } on http.ClientException catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Gagal mengirim data ke server. Coba lagi.')));
    } on TimeoutException catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Permintaan timeout. Server mungkin lambat atau tidak responsif.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      setState(() => verifying = false);
      api.close();
    }
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
                          onPressed: verifying
                              ? null
                              : () async {
                                  if (captured == null) {
                                    await _capture();
                                  } else {
                                    await _verifyAndCheckIn(context);
                                  }
                                },
                          child: verifying
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(captured == null ? 'Ambil' : 'Gunakan'),
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
