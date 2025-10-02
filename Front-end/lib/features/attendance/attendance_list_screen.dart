import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/providers/attendance_provider.dart';
import '../../data/models/attendance.dart';

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});
  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

enum _Filter { all, present, absent, leave }

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  _Filter current = _Filter.all;
  String query = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final recs = provider.records.where((r) {
      // search by day/month text
      final dateText = provider.formatDate(r.date).toLowerCase();
      if (query.isNotEmpty && !dateText.contains(query.toLowerCase())) return false;
      switch (current) {
        case _Filter.present:
          return !r.isAbsent && !r.isLeave && !r.isSick;
        case _Filter.absent:
          return r.isAbsent;
        case _Filter.leave:
          return r.isLeave || r.isSick;
        case _Filter.all:
          return true;
      }
    }).toList();

    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        automaticallyImplyLeading: false,
      
        title: const Text('Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        elevation: 0,
        
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _SearchAndCalendar(
            onQuery: (v) => setState(() => query = v),
            onPickDate: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 1),
              );
              if (picked != null) {
                setState(() => query = picked.day.toString());
              }
            },
          ),
          const SizedBox(height: 14),
          _FilterTabs(
            current: current,
            onChanged: (f) => setState(() => current = f),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: recs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final r = recs[i];
                return _AttendanceCardItem(record: r, provider: provider);
              },
            ),
          )
        ],
      ),
    );
  }
}

class _SearchAndCalendar extends StatelessWidget {
  final ValueChanged<String> onQuery;
  final VoidCallback onPickDate;
  const _SearchAndCalendar({required this.onQuery, required this.onPickDate});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      onChanged: onQuery,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: onPickDate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 44,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.calendar_month_outlined),
            ),
          )
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final _Filter current;
  final ValueChanged<_Filter> onChanged;
  const _FilterTabs({required this.current, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FilterChip(label: 'Semua', selected: current == _Filter.all, onTap: () => onChanged(_Filter.all)),
          const SizedBox(width: 8),
            _FilterChip(label: 'Masuk', selected: current == _Filter.present, onTap: () => onChanged(_Filter.present)),
          const SizedBox(width: 8),
          _FilterChip(label: 'Absen', selected: current == _Filter.absent, onTap: () => onChanged(_Filter.absent)),
          const SizedBox(width: 8),
          _FilterChip(label: 'Izin/Sakit', selected: current == _Filter.leave, onTap: () => onChanged(_Filter.leave)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? Theme.of(context).colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? Theme.of(context).colorScheme.primary : Colors.grey.shade300),
          boxShadow: sel
              ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(.25), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: sel ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _AttendanceCardItem extends StatelessWidget {
  final AttendanceRecord record;
  final AttendanceProvider provider;
  const _AttendanceCardItem({required this.record, required this.provider});

  @override
  Widget build(BuildContext context) {
    final dateLabel = provider.formatDate(record.date);
    final checkIn = record.checkIn == null ? '00.00' : _fmtTime(record.checkIn!);
    final checkOut = record.checkOut == null ? '00.00' : _fmtTime(record.checkOut!);
    final statusColor = _statusColor(record);
    final dateParam = record.date.toIso8601String().split('T').first;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push('/attendance/detail/$dateParam'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 4, height: 16, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Absen Masuk', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(checkIn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 4),
                          Text('WIB', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        ],
                      )
                    ],
                  ),
                ),
                Container(width: 1, height: 42, color: Colors.grey.shade200),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Absen Pulang', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(checkOut, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 4),
                          Text('WIB', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(AttendanceRecord r) {
    if (r.isAbsent) return const Color(0xFFE53935); // red
    if (r.isLeave || r.isSick) return const Color(0xFFF2C94C); // yellow
    return const Color(0xFF27AE60); // green present
  }
}

String _fmtTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}';
