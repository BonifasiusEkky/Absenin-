import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/attendance_provider.dart';
import '../../data/models/attendance.dart';
import '../../core/config/env.dart';

class AttendanceDetailScreen extends StatelessWidget {
  final String dateIso; // yyyy-MM-dd
  const AttendanceDetailScreen({super.key, required this.dateIso});
  @override
  Widget build(BuildContext context) {
    DateTime? date;
    try {
      date = DateTime.parse(dateIso);
    } catch (_) {}
    final provider = context.watch<AttendanceProvider>();
    AttendanceRecord? record = provider.records.firstWhere(
      (r) => date != null && r.date.year == date.year && r.date.month == date.month && r.date.day == date.day,
      orElse: () => AttendanceRecord(
        id: 'local-missing',
        userId: 'unknown',
        date: date ?? DateTime.now(),
      ),
    );
    final dateLabel = provider.formatDate(record.date);
    final checkIn = record.checkIn == null ? '-' : _fmtTime(record.checkIn!);
    final checkOut = record.checkOut == null ? '-' : _fmtTime(record.checkOut!);

    final inVerified = record.checkInVerified;
    final outVerified = record.checkOutVerified;

    final inPhoto = record.checkInPhotoPath;
    final outPhoto = record.checkOutPhotoPath;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Kehadiran')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _InfoTile(label: 'Masuk', value: checkIn)),
                const SizedBox(width: 12),
                Expanded(child: _InfoTile(label: 'Pulang', value: checkOut)),
              ],
            ),
            const SizedBox(height: 16),
            if (record.activityNote != null && record.activityNote!.trim().isNotEmpty) ...[
              const Text('Aktivitas (checkout)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Text(record.activityNote!),
              ),
              const SizedBox(height: 16),
            ],
            const Text('Verifikasi', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _InfoTile(label: 'Masuk', value: _fmtVerified(inVerified))),
                const SizedBox(width: 12),
                Expanded(child: _InfoTile(label: 'Pulang', value: _fmtVerified(outVerified))),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Bukti Foto', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _PhotoCard(label: 'Masuk', path: inPhoto)),
                const SizedBox(width: 12),
                Expanded(child: _PhotoCard(label: 'Pulang', path: outPhoto)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

String _fmtVerified(bool? v) {
  if (v == null) return '-';
  return v ? 'Terverifikasi' : 'Tidak cocok';
}

class _PhotoCard extends StatelessWidget {
  final String label;
  final String? path;
  const _PhotoCard({required this.label, required this.path});

  @override
  Widget build(BuildContext context) {
    final has = path != null && path!.trim().isNotEmpty;
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: has
                ? Image.network(_resolveStorageUrl(path!), fit: BoxFit.cover)
                : const Center(child: Icon(Icons.photo_outlined, size: 44, color: Colors.grey)),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.black.withOpacity(.55), borderRadius: BorderRadius.circular(999)),
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  static String _resolveStorageUrl(String raw) {
    final u = raw.trim();
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    if (u.startsWith('public/')) {
      // Laravel public disk stores as "public/..." and is served under "/storage/..."
      return Env.api('/storage/${u.substring('public/'.length)}').toString();
    }
    if (u.startsWith('/')) return Env.api(u).toString();
    return Env.api('/$u').toString();
  }
}
