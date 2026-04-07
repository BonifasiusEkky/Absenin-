import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/models/leave_request.dart';
import '../../data/providers/leave_provider.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});
  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  bool showPie = false; // false = ring annual quota, true = pie distribution categories

  // Annual quota (example)
  final int annualQuota = 15;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveProvider>().load();
    });
  }

  int get usedAnnual {
    final items = context.read<LeaveProvider>().items;
    return items.where((h) => h.type == 'annual' && h.status == 'approved').fold(0, (p, h) => p + h.days);
  }

  int get usedSick {
    final items = context.read<LeaveProvider>().items;
    return items.where((h) => h.type == 'sick' && h.status == 'approved').fold(0, (p, h) => p + h.days);
  }

  int get usedOther {
    final items = context.read<LeaveProvider>().items;
    return items.where((h) => h.type == 'other' && h.status == 'approved').fold(0, (p, h) => p + h.days);
  }

  void _openLeaveForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _LeaveForm(
        onSubmit: (type, start, end, reason, attachment) async {
          final provider = context.read<LeaveProvider>();
          final created = await provider.submit(
            type: type.apiValue,
            startDate: start,
            endDate: end,
            reason: reason,
            attachmentFile: attachment,
          );
          if (!mounted) return;
          if (created == null) {
            _showSnack(context, provider.error ?? 'Gagal mengajukan cuti');
            return;
          }
          _showSnack(context, 'Pengajuan ${type.label} terkirim (Pending)');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final provider = context.watch<LeaveProvider>();
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
            if (provider.loading)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(child: Text('Gagal memuat: ${provider.error}')),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: provider.load,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              )
            else if (provider.items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Belum ada pengajuan cuti.'),
              )
            else
              ...provider.items.map(
                (h) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HistoryCard(item: h),
                ),
              ),
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
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: percent.clamp(0.0, 1.0),
                                strokeWidth: 8,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation(LeaveType.annual.color),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$usedAnnual',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                                ),
                                const Text('hari', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegendDot(color: LeaveType.annual.color),
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

enum LeaveType { annual, sick, other }

class _HistoryCard extends StatelessWidget {
  final LeaveRequest item;
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
                child: Text(
                  'Mengajukan pada: ${_fmtDate(item.createdAt ?? DateTime.now())}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
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
              Expanded(child: _MiniInfo(label: 'Hari Awal', value: _fmtDate(item.startDate))),
              const SizedBox(width: 12),
              Expanded(child: _MiniInfo(label: 'Hari Akhir', value: _fmtDate(item.endDate))),
            ],
          )
        ],
      ),
    );
  }

  _StatusInfo _statusInfo(String status) {
    switch (status) {
      case 'approved':
        return _StatusInfo('Disetujui', const Color(0xFF27AE60), const Color(0xFFDDF5E8));
      case 'rejected':
        return _StatusInfo('Ditolak', const Color(0xFFE53935), const Color(0xFFFFE3E3));
      case 'pending':
      default:
        return _StatusInfo('Menunggu', const Color(0xFFF2A534), const Color(0xFFFFF2D9));
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
    final annualColor = LeaveType.annual.color;
    final sickColor = LeaveType.sick.color;
    final otherColor = LeaveType.other.color;
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
                  color: annualColor,
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
            _chipLegend(annualColor, 'Cuti Tahunan', usedAnnual),
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

extension LeaveTypeExt on LeaveType {
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

  Color get color {
    switch (this) {
      case LeaveType.annual:
        return const Color(0xFF2F80ED); // blue-ish for annual
      case LeaveType.sick:
        return const Color(0xFFF2A534); // orange for sick
      case LeaveType.other:
        return const Color(0xFF6C63FF); // purple for other
    }
  }
}

void _showSnack(BuildContext context, String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

// (Removed extension; logic moved into _LeaveScreenState)

class _LeaveForm extends StatefulWidget {
  final Future<void> Function(LeaveType type, DateTime start, DateTime end, String reason, File? attachment) onSubmit;
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
  File? _attachment;
  bool _submitting = false;

  @override
  void dispose() {
    reasonC.dispose();
    super.dispose();
  }

  Future<void> _pickAttachmentFromCamera() async {
    final picker = ImagePicker();
    try {
      final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1800);
      if (img != null) setState(() => _attachment = File(img.path));
    } catch (_) {}
  }

  Future<void> _pickAttachmentFromGallery() async {
    final picker = ImagePicker();
    try {
      final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1800);
      if (img != null) setState(() => _attachment = File(img.path));
    } catch (_) {}
  }

  Future<void> _pickAttachmentFile() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      );
      final p = res?.files.single.path;
      if (p != null) setState(() => _attachment = File(p));
    } catch (_) {}
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
              const SizedBox(height: 14),
              const Text('Lampiran (opsional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickAttachmentFromCamera,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Kamera'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickAttachmentFromGallery,
                      icon: const Icon(Icons.photo_outlined),
                      label: const Text('Galeri'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickAttachmentFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Pilih File (PDF/JPG/PNG)'),
                ),
              ),
              if (_attachment != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: Text(_attachment!.path.split(Platform.pathSeparator).last, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    IconButton(
                      onPressed: () => setState(() => _attachment = null),
                      icon: const Icon(Icons.close),
                      tooltip: 'Hapus lampiran',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _submitting
                      ? null
                      : () async {
                    if (start == null || end == null) {
                      _showSnack(context, 'Tanggal belum dipilih');
                      return;
                    }
                    if (_formKey.currentState!.validate()) {
                      setState(() => _submitting = true);
                      await widget.onSubmit(type, start!, end!, reasonC.text.trim(), _attachment);
                      if (mounted) Navigator.of(context).pop();
                    }
                  },
                  child: Text(_submitting ? 'Mengirim...' : 'Kirim Pengajuan'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

extension LeaveTypeApi on LeaveType {
  String get apiValue {
    switch (this) {
      case LeaveType.annual:
        return 'annual';
      case LeaveType.sick:
        return 'sick';
      case LeaveType.other:
        return 'other';
    }
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
