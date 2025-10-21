import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../core/config/env.dart';
import '../../core/network/api_client.dart';
import '../../data/providers/attendance_provider.dart';
import '../../data/providers/user_provider.dart';
import '../../services/attendance_service.dart';

class CheckoutFaceScreen extends StatefulWidget {
  const CheckoutFaceScreen({super.key});
  @override
  State<CheckoutFaceScreen> createState() => _CheckoutFaceScreenState();
}

class _CheckoutFaceScreenState extends State<CheckoutFaceScreen> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  XFile? captured;
  bool loading = true;
  bool working = false;
  final TextEditingController activityCtrl = TextEditingController();

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

  Future<void> _verifyAndCheckout() async {
    if (captured == null) return;
    setState(() => working = true);
    final messenger = ScaffoldMessenger.of(context);
    final api = ApiClient();
    try {
      final user = context.read<UserProvider>();
      // verify face via backend proxy
      final res = await api.postMultipart(
        Env.api('/api/face/verify'),
        fields: {'user_id': user.backendUserId.toString()},
        files: [await http.MultipartFile.fromPath('image', captured!.path)],
      );
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['verified'] != true) {
        messenger.showSnackBar(const SnackBar(content: Text('Wajah tidak cocok. Coba ulangi.')));
        setState(() => working = false);
        return;
      }
      // submit checkout with activity
      final now = DateTime.now();
      final svc = AttendanceService(api);
      await svc.checkOut(
        userId: user.backendUserId.toString(),
        date: DateTime(now.year, now.month, now.day),
        time: now,
        activity: activityCtrl.text.trim(),
      );
      // refresh provider
      try { await context.read<AttendanceProvider>().loadFromBackend(user); } catch (_) {}
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Absen pulang tersimpan')));
      Navigator.of(context).pop();
    } on ApiError catch (e) {
      String msg = 'Gagal checkout (HTTP ${e.statusCode}).';
      try {
        final body = jsonDecode(e.body);
        if (body is Map<String, dynamic>) {
          if (body['errors'] is Map) {
            final errors = body['errors'] as Map;
            final flat = errors.values.expand((v) => (v as List).map((x) => x.toString())).join('\n');
            if (flat.isNotEmpty) msg = flat;
          } else if (body['ok'] == false && body['error'] is String) {
            msg = body['error'];
          }
        }
      } catch (_) {}
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } on SocketException catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Tidak dapat terhubung ke server.')));
    } on TimeoutException catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Timeout. Coba lagi.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      setState(() => working = false);
      api.close();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    activityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absen Pulang')),
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
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: TextField(
                              controller: activityCtrl,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Laporan aktivitas hari ini (opsional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: captured != null ? () => setState(() => captured = null) : null,
                          child: const Text('Ulang Foto'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: working
                              ? null
                              : () async {
                                  if (captured == null) {
                                    await _capture();
                                  } else {
                                    await _verifyAndCheckout();
                                  }
                                },
                          child: working
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(captured == null ? 'Ambil Foto' : 'Selesai'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
    );
  }
}
