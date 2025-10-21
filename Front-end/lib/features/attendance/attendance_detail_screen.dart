import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/attendance_provider.dart';
import '../../data/models/attendance.dart';

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
            const SizedBox(height: 20),
            const Text('Lokasi', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: Icon(Icons.map, size: 50, color: Colors.grey)),
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
