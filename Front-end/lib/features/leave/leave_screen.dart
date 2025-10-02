import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});
  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  bool showPie = false; // false = ring annual quota, true = pie distribution categories

  // Annual quota (example)
  final int annualQuota = 15;

  final List<_LeaveHistory> history = [
    _LeaveHistory(
      applied: DateTime(2025, 5, 20),
      start: DateTime(2025, 6, 1),
      end: DateTime(2025, 6, 2),
      status: LeaveStatus.approved,
      type: LeaveType.annual,
      reason: 'Liburan keluarga',
    ),
    // Dummy Cuti Sakit (approved) agar grafik kategori menampilkan nilai > 0 untuk sakit
    _LeaveHistory(
      applied: DateTime(2025, 5, 21),
      start: DateTime(2025, 6, 2),
      end: DateTime(2025, 6, 2),
      status: LeaveStatus.approved,
      type: LeaveType.sick,
      reason: 'Flu ringgan',
    ),
    _LeaveHistory(
      applied: DateTime(2025, 5, 22),
      start: DateTime(2025, 6, 3),
      end: DateTime(2025, 6, 3),
      status: LeaveStatus.pending,
      type: LeaveType.sick,
      reason: 'Demam',
    ),
    _LeaveHistory(
      applied: DateTime(2025, 5, 25),
      start: DateTime(2025, 6, 4),
      end: DateTime(2025, 6, 5),
      status: LeaveStatus.approved,
      type: LeaveType.other,
      reason: 'Urusan keluarga',
    ),
    _LeaveHistory(
      applied: DateTime(2025, 5, 27),
      start: DateTime(2025, 6, 6),
      end: DateTime(2025, 6, 7),
      status: LeaveStatus.rejected,
      type: LeaveType.annual,
      reason: 'Trip pantai',
    ),
  ];

  int _days(_LeaveHistory h) => h.end.difference(h.start).inDays + 1;

  int get usedAnnual => history.where((h) => h.type == LeaveType.annual && h.status == LeaveStatus.approved).fold(0, (p, h) => p + _days(h));
  int get usedSick => history.where((h) => h.type == LeaveType.sick && h.status == LeaveStatus.approved).fold(0, (p, h) => p + _days(h));
  int get usedOther => history.where((h) => h.type == LeaveType.other && h.status == LeaveStatus.approved).fold(0, (p, h) => p + _days(h));

  void _openLeaveForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _LeaveForm(onSubmit: (type, start, end, reason) {
        setState(() {
          history.insert(
            0,
            _LeaveHistory(
              applied: DateTime.now(),
              start: start,
              end: end,
              status: LeaveStatus.pending,
              type: type,
              reason: reason,
            ),
          );
        });
        _showSnack(context, 'Pengajuan ${type.label} tersimpan (Pending)');
      }),
    );
  }

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
        onPressed: _openLeaveForm,
        backgroundColor: primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QuotaCard(
              showPie: showPie,
              annualQuota: annualQuota,
              usedAnnual: usedAnnual,
              usedSick: usedSick,
              usedOther: usedOther,
            ),
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
  final bool showPie;
  final int annualQuota;
  final int usedAnnual;
  final int usedSick;
  final int usedOther;
  const _QuotaCard({
    required this.showPie,
    required this.annualQuota,
    required this.usedAnnual,
    required this.usedSick,
    required this.usedOther,
  });
  @override
  Widget build(BuildContext context) {
    final percent = annualQuota == 0 ? 0.0 : usedAnnual / annualQuota;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: showPie
              ? _PieDistribution(
                  key: const ValueKey('pieDist'),
                  usedAnnual: usedAnnual,
                  usedSick: usedSick,
                  usedOther: usedOther,
                )
              : SizedBox(
                  key: const ValueKey('ring'),
                  height: 160,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 110,
                        width: 110,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: percent,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                            ),
                            Center(
                              child: Text('$usedAnnual/$annualQuota', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegendDot(color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 6),
                          const Text('Kuota Cuti Yang Telah Diambil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
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
enum LeaveType { annual, sick, other }

class _LeaveHistory {
  final DateTime applied;
  final DateTime start;
  final DateTime end;
  final LeaveStatus status;
  final LeaveType type;
  final String reason;
  _LeaveHistory({
    required this.applied,
    required this.start,
    required this.end,
    required this.status,
    required this.type,
    this.reason = '',
  });
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

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _PieDistribution extends StatelessWidget {
  final int usedAnnual;
  final int usedSick;
  final int usedOther;
  const _PieDistribution({super.key, required this.usedAnnual, required this.usedSick, required this.usedOther});
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const sickColor = Color(0xFFF2A534);
    const otherColor = Color(0xFF6C63FF);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 135,
          child: PieChart(
            PieChartData(
              sectionsSpace: 8,
              centerSpaceRadius: 42,
              startDegreeOffset: -20,
              sections: [
                PieChartSectionData(
                  value: usedAnnual.toDouble(),
                  color: primary,
                  title: usedAnnual == 0 ? '' : usedAnnual.toString(),
                  radius: 44,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                ),
                PieChartSectionData(
                  value: usedSick.toDouble(),
                  color: sickColor,
                  title: usedSick == 0 ? '' : usedSick.toString(),
                  radius: 38,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10),
                ),
                PieChartSectionData(
                  value: usedOther.toDouble(),
                  color: otherColor,
                  title: usedOther == 0 ? '' : usedOther.toString(),
                  radius: 36,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            _chipLegend(primary, 'Cuti Tahunan', usedAnnual),
            _chipLegend(sickColor, 'Cuti Sakit', usedSick),
            _chipLegend(otherColor, 'Cuti Lainnya', usedOther),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Total Diambil: ${usedAnnual + usedSick + usedOther} hari',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color c, String label, int value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendDot(color: c),
          const SizedBox(width: 6),
          Text('$label ($value)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      );

  static Widget _chipLegend(Color color, String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendDot(color: color),
          const SizedBox(width: 6),
          Text(
            '$label ($value)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.darken()),
          ),
        ],
      ),
    );
  }
}

extension _ColorShade on Color {
  Color darken([double amount = .2]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

extension on LeaveType {
  String get label {
    switch (this) {
      case LeaveType.annual:
        return 'Cuti Tahunan';
      case LeaveType.sick:
        return 'Cuti Sakit';
      case LeaveType.other:
        return 'Cuti Lainnya';
    }
  }
}

void _showSnack(BuildContext context, String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

// (Removed extension; logic moved into _LeaveScreenState)

class _LeaveForm extends StatefulWidget {
  final void Function(LeaveType type, DateTime start, DateTime end, String reason) onSubmit;
  const _LeaveForm({required this.onSubmit});
  @override
  State<_LeaveForm> createState() => _LeaveFormState();
}

class _LeaveFormState extends State<_LeaveForm> {
  LeaveType type = LeaveType.annual;
  DateTime? start;
  DateTime? end;
  final TextEditingController reasonC = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    reasonC.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          start = picked;
          if (end != null && end!.isBefore(start!)) end = start;
        } else {
          end = picked;
          if (start != null && end!.isBefore(start!)) start = end;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
              ),
              const SizedBox(height: 16),
              const Text('Ajukan Cuti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              const Text('Jenis Cuti', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: LeaveType.values.map((lv) {
                  final sel = type == lv;
                  return ChoiceChip(
                    label: Text(lv.label),
                    selected: sel,
                    onSelected: (_) => setState(() => type = lv),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _DatePickTile(label: 'Tanggal Mulai', date: start, onTap: () => _pickDate(true))),
                  const SizedBox(width: 12),
                  Expanded(child: _DatePickTile(label: 'Tanggal Akhir', date: end, onTap: () => _pickDate(false))),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: reasonC,
                decoration: const InputDecoration(labelText: 'Alasan', border: OutlineInputBorder()),
                minLines: 2,
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Isi alasan' : null,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () {
                    if (start == null || end == null) {
                      _showSnack(context, 'Tanggal belum dipilih');
                      return;
                    }
                    if (_formKey.currentState!.validate()) {
                      widget.onSubmit(type, start!, end!, reasonC.text.trim());
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Kirim Pengajuan'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DatePickTile({required this.label, required this.date, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            Text(
              date == null ? 'Pilih tanggal' : _fmtDate(date!),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
