import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});
  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  bool showPie = false;

  // Dummy quota & history data
  final int used = 4;
  final int quota = 15;

  final List<_LeaveHistory> history = [
    _LeaveHistory(applied: DateTime(2025, 5, 20), start: DateTime(2025, 6, 1), end: DateTime(2025, 6, 2), status: LeaveStatus.approved),
    _LeaveHistory(applied: DateTime(2025, 5, 20), start: DateTime(2025, 6, 3), end: DateTime(2025, 6, 3), status: LeaveStatus.pending),
    _LeaveHistory(applied: DateTime(2025, 5, 20), start: DateTime(2025, 6, 4), end: DateTime(2025, 6, 5), status: LeaveStatus.pending),
    _LeaveHistory(applied: DateTime(2025, 5, 20), start: DateTime(2025, 6, 6), end: DateTime(2025, 6, 7), status: LeaveStatus.rejected),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text('Izin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: showPie ? 'Tampilkan Ring' : 'Tampilkan Pie',
            onPressed: () => setState(() => showPie = !showPie),
            icon: const Icon(Icons.tune, color: Colors.white),
          ),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primary,
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QuotaCard(used: used, quota: quota, showPie: showPie),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text('Riwayat Cuti', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Lihat semua >'),
                )
              ],
            ),
            ...history.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HistoryCard(item: h),
                )),
          ],
        ),
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  final int used;
  final int quota;
  final bool showPie;
  const _QuotaCard({required this.used, required this.quota, required this.showPie});
  @override
  Widget build(BuildContext context) {
    final percent = quota == 0 ? 0.0 : used / quota;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: showPie
              ? SizedBox(
                  key: const ValueKey('pie'),
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 32,
                      sections: [
                        PieChartSectionData(
                          value: used.toDouble(),
                          color: Theme.of(context).colorScheme.primary,
                          title: used.toString(),
                          radius: 56,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        PieChartSectionData(
                          value: (quota - used).toDouble(),
                          color: Colors.grey.shade300,
                          title: (quota - used).toString(),
                          radius: 50,
                          titleStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox(
                  key: const ValueKey('ring'),
                  height: 180,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: percent,
                              strokeWidth: 10,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                            ),
                            Center(
                              child: Text('$used/$quota', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text('Kuota Cuti Yang Telah Diambil', style: TextStyle(fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

enum LeaveStatus { approved, pending, rejected }

class _LeaveHistory {
  final DateTime applied;
  final DateTime start;
  final DateTime end;
  final LeaveStatus status;
  _LeaveHistory({required this.applied, required this.start, required this.end, required this.status});
}

class _HistoryCard extends StatelessWidget {
  final _LeaveHistory item;
  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(item.status);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 6, offset: const Offset(0, 3))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Mengajukan pada: ${_fmtDate(item.applied)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusInfo.background,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(statusInfo.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusInfo.foreground)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MiniInfo(label: 'Hari Awal', value: _fmtDate(item.start))),
              const SizedBox(width: 12),
              Expanded(child: _MiniInfo(label: 'Hari Akhir', value: _fmtDate(item.end))),
            ],
          )
        ],
      ),
    );
  }

  _StatusInfo _statusInfo(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.approved:
        return _StatusInfo('Disetujui', const Color(0xFF27AE60), const Color(0xFFDDF5E8));
      case LeaveStatus.pending:
        return _StatusInfo('Menunggu', const Color(0xFFF2A534), const Color(0xFFFFF2D9));
      case LeaveStatus.rejected:
        return _StatusInfo('Ditolak', const Color(0xFFE53935), const Color(0xFFFFE3E3));
    }
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;
  const _MiniInfo({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _StatusInfo {
  final String label;
  final Color foreground;
  final Color background;
  _StatusInfo(this.label, this.foreground, this.background);
}

String _fmtDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
}
