import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/providers/attendance_provider.dart';
import '../../data/models/attendance.dart';
import '../../data/providers/user_provider.dart';

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});
  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

enum _Filter { all, present, absent, leave }

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  _Filter current = _Filter.all;
  String query = '';
  late int selectedYear;
  late int selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedYear = now.year;
    selectedMonth = now.month;
    // Defer to first frame to ensure providers are mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<AttendanceProvider>();
      final user = context.read<UserProvider>();
      prov.loadByMonth(user, selectedYear, selectedMonth);
    });
  }

  Future<void> _changeMonth(int monthOffset) async {
    final newDate = DateTime(selectedYear, selectedMonth + monthOffset);
    final prov = context.read<AttendanceProvider>();
    final user = context.read<UserProvider>();
    setState(() {
      selectedYear = newDate.year;
      selectedMonth = newDate.month;
    });
    await prov.loadByMonth(user, selectedYear, selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final isLoading = provider.loading;

    if (provider.error != null && !isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attendance')),
        body: Center(child: Text('Gagal memuat data: ${provider.error}')),
      );
    }
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
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Bulan sebelumnya',
                ),
                Expanded(
                  child: Text(
                    context.read<AttendanceProvider>().getMonthYearLabel(selectedYear, selectedMonth),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Bulan berikutnya',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SearchAndCalendar(
            onQuery: (v) => setState(() => query = v),
            onPickDate: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(selectedYear, selectedMonth),
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
            child: isLoading
                ? const _AttendanceSkeletonList()
                : ListView.separated(
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

class _SearchAndCalendar extends StatefulWidget {
  final ValueChanged<String> onQuery;
  final VoidCallback onPickDate;
  const _SearchAndCalendar({required this.onQuery, required this.onPickDate});

  @override
  State<_SearchAndCalendar> createState() => _SearchAndCalendarState();
}

class _SearchAndCalendarState extends State<_SearchAndCalendar> {
  late TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: _searchCtrl.text.isNotEmpty
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) {
                        widget.onQuery(v);
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        widget.onQuery('');
                        setState(() {});
                      },
                      child: Icon(
                        Icons.close_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: widget.onPickDate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
          ),
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

class _AttendanceSkeletonList extends StatelessWidget {
  const _AttendanceSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const _AttendanceSkeletonCard(),
    );
  }
}

class _AttendanceSkeletonCard extends StatelessWidget {
  const _AttendanceSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final skeleton = Colors.grey.shade300;

    return Container(
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
              Container(width: 4, height: 16, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 8),
              Container(
                height: 13,
                width: 140,
                decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(6)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 11,
                      width: 80,
                      decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(5)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 16,
                      width: 64,
                      decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(6)),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 42, color: Colors.grey.shade200),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 11,
                      width: 88,
                      decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(5)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 16,
                      width: 64,
                      decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _fmtTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}';
