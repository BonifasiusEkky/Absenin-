import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/providers/attendance_provider.dart';
import '../../data/providers/user_provider.dart';
import '../../data/models/attendance.dart';
import '../attendance/attendance_list_screen.dart';
import '../attendance/attendance_calendar_screen.dart';
import '../../services/location_service.dart';
import '../../data/providers/location_access_provider.dart';
import '../../services/office_config.dart';
import '../../services/attendance_service.dart';
import '../../core/network/api_client.dart';
import '../../services/session_storage.dart';
// reverse geocoding no longer used in dashboard; distance-based check used instead
import 'package:geolocator/geolocator.dart';
import '../leave/leave_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int current = 0;
  @override
  Widget build(BuildContext context) {
  // Pages; only some implemented.
  const pages = [DashboardScreen(), AttendanceListScreen(), AttendanceCalendarScreen(), LeaveScreen(), ProfileScreen()];
    return Scaffold(
      body: SafeArea(top: false, child: pages[current]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: (i) => setState(() => current = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.event_available_outlined), selectedIcon: Icon(Icons.event_available), label: 'Attendance'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.flight_takeoff_outlined), selectedIcon: Icon(Icons.flight_takeoff), label: 'Leave'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: SingleChildScrollView(
        child: Column(
          children: const [
            _HeaderSection(),
            SizedBox(height: 24),
            _QuickActions(),
            SizedBox(height: 28),
            _AttendanceSummarySection(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatefulWidget {
  const _HeaderSection();
  @override
  State<_HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<_HeaderSection> {
  late DateTime now;
  @override
  void initState() {
    super.initState();
    now = DateTime.now();
    // Update every minute
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return false;
      setState(() => now = DateTime.now());
      return true; // continue loop
    });
  }

  String _formatIndonesianDate(DateTime dt) {
    // Manual Indonesian day/month names to avoid needing locale initialization
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${days[dt.weekday % 7]}, ${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m WIB';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final dateStr = _formatIndonesianDate(now);
    final timeStr = _formatTime(now);
    final user = context.watch<UserProvider>();
    // Lazy load attendance if not loaded yet
    final attProv = context.read<AttendanceProvider>();
    final userProv = context.read<UserProvider>();
    if (attProv.records.isEmpty) {
      // fire and forget
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) attProv.loadFromBackend(userProv);
      });
    }
    return SizedBox(
      height: 400, // slightly more to lower white card per request
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 230,
            width: double.infinity,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(.4)),
                        ),
                        child: const Text(
                          'PT. Naraya Telematika',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(user.role, style: TextStyle(color: Colors.white.withOpacity(.85), fontSize: 13)),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage('https://ui-avatars.com/api/?name='
                      '${Uri.encodeComponent(user.name)}&background=0D8ABC&color=fff'),
                )
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 160, // lowered card
            child: _AttendanceCard(dateStr: dateStr, timeStr: timeStr),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatefulWidget {
  final String dateStr;
  final String timeStr;
  const _AttendanceCard({super.key, required this.dateStr, required this.timeStr});

  @override
  State<_AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<_AttendanceCard> {
  bool _checking = false;
  String? _lastMessage;
  LocationCheckStatus? _lastStatus;
  String? _locationName; // kept for potential future use
  bool _loadingLocation = true;
  double? _distanceMeters;
  bool? _isInside;

  @override
  void initState() {
    super.initState();
    _loadLocationName();
  }

  Future<void> _loadLocationName() async {
    try {
      final office = context.read<LocationAccessProvider>().office;
      final officePoints = office != null ? [LatLng(office.latitude, office.longitude)] : OfficeConfig.officePoints;
      final radiusMeters = office?.radiusMeters ?? OfficeConfig.radiusMeters;

      Position? pos = await Geolocator.getLastKnownPosition();
      if (pos == null) {
        pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low, timeLimit: const Duration(seconds: 5));
      }
        final Position p = pos;
        {
        // Compute distance to nearest office point
        double minD = double.infinity;
        for (final o in officePoints) {
          final d = Geolocator.distanceBetween(p.latitude, p.longitude, o.lat, o.lng);
          if (d < minD) minD = d;
        }
        final bool inside = minD <= radiusMeters;
        if (!mounted) return;
        setState(() {
          _distanceMeters = minD.isFinite ? minD : null;
          _isInside = inside;
          _loadingLocation = false;
        });
        return;
        }
    } catch (_) {
      // ignore, will show fallback
    }
    if (!mounted) return;
    setState(() {
      _locationName = null;
      _loadingLocation = false;
    });
  }

  Future<void> _handleAbsenMasuk(BuildContext context) async {
    if (_checking) return;
    setState(() => _checking = true);
    final provider = context.read<LocationAccessProvider>();
    final res = await provider.verify();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _lastMessage = res.message ?? _statusToMessage(res.status, res.distanceMeters);
      _lastStatus = res.status;
    });
    if (provider.isAuthorized) {
      context.push('/camera/face');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Gagal verifikasi lokasi')),
      );
    }
  }

  String _statusToMessage(LocationCheckStatus status, double? distance) {
    final radiusMeters = context.read<LocationAccessProvider>().office?.radiusMeters ?? OfficeConfig.radiusMeters;
    switch (status) {
      case LocationCheckStatus.inside:
        return 'Lokasi terverifikasi (dalam radius ${radiusMeters.toStringAsFixed(0)} m)';
      case LocationCheckStatus.outside:
        return 'Diluar radius (${distance?.toStringAsFixed(1)} m)';
      case LocationCheckStatus.permissionDenied:
        return 'Izin lokasi ditolak';
      case LocationCheckStatus.permissionPermanentlyDenied:
        return 'Izin ditolak permanen - buka pengaturan';
      case LocationCheckStatus.serviceDisabled:
        return 'Aktifkan GPS / Location Service';
      case LocationCheckStatus.timeout:
        return 'Gagal mendapatkan lokasi (timeout)';
      case LocationCheckStatus.mocked:
        return 'Lokasi terdeteksi spoof/mocked';
      case LocationCheckStatus.error:
        return 'Kesalahan verifikasi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final today = DateTime.now();
    final p = context.watch<AttendanceProvider>();
    final todayRec = p.records.firstWhere(
      (r) => r.date.year == today.year && r.date.month == today.month && r.date.day == today.day,
      orElse: () => AttendanceRecord(
        id: 'temp', userId: '-', date: DateTime(today.year, today.month, today.day),
      ),
    );
    String fmtTime(DateTime? dt) => dt == null
        ? '- - : - -'
        : '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  final hasIn = todayRec.checkIn != null;
  final hasOut = todayRec.checkOut != null;
  final isCheckoutPhase = hasIn && !hasOut;
  final isDisabled = hasIn && hasOut; // already checked out
  final buttonLabel = !hasIn
    ? 'Absen Masuk'
    : isCheckoutPhase
      ? 'Absen Pulang'
      : 'Sudah Absen Pulang';
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16),
                const SizedBox(width: 6),
                Text(widget.dateStr, style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(widget.timeStr, style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.login, size: 16, color: Colors.green),
                          SizedBox(width: 4),
                          Text('Absen Masuk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(fmtTime(todayRec.checkIn), style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.logout, size: 16, color: Colors.redAccent),
                          SizedBox(width: 4),
                          Text('Absen Pulang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(fmtTime(todayRec.checkOut), style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.location_pin, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Expanded(
                  child: _loadingLocation
                      ? const Text('Memuat lokasi...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500))
                      : _distanceMeters == null
                          ? const Text('Lokasi tidak tersedia', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_distanceMeters! < 1000 ? _distanceMeters!.toStringAsFixed(0) + " m" : (_distanceMeters! / 1000).toStringAsFixed(2) + " km"} dari kantor',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: (_isInside ?? false) ? Colors.green : Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text('Min radius: ${(context.read<LocationAccessProvider>().office?.radiusMeters ?? OfficeConfig.radiusMeters).toStringAsFixed(0)} m', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                              ],
                            ),
                ),
                // Retry button to attempt reverse-geocoding again if initial lookup failed
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.blueGrey),
                  tooltip: 'Muat ulang lokasi',
                  onPressed: _loadingLocation
                      ? null
                      : () async {
                          setState(() {
                            _loadingLocation = true;
                          });
                          await _loadLocationName();
                        },
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: isCheckoutPhase ? Colors.redAccent : Colors.green,
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: (_checking || isDisabled)
                    ? null
                    : () async {
                        if (isCheckoutPhase) {
                          if (!context.mounted) return;
                          context.push('/camera/checkout');
                        } else {
                          await _handleAbsenMasuk(context);
                        }
                      },
                child: _checking
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            if (_lastMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _lastStatus == LocationCheckStatus.inside
                          ? Icons.check_circle
                          : _lastStatus == LocationCheckStatus.outside
                              ? Icons.error_outline
                              : Icons.info_outline,
                      size: 14,
                      color: _lastStatus == LocationCheckStatus.inside
                          ? Colors.green
                          : _lastStatus == LocationCheckStatus.outside
                              ? Colors.orange
                              : Colors.blueGrey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _lastMessage!,
                        style: TextStyle(
                          fontSize: 11,
                          color: _lastStatus == LocationCheckStatus.inside
                              ? Colors.green
                              : _lastStatus == LocationCheckStatus.outside
                                  ? Colors.orange.shade800
                                  : Colors.blueGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: () => context.push('/attendance'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kehadiran',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF444B57)),
            ),
            const SizedBox(height: 12),
            _SimpleMonthlyHeatmap(),
          ],
        ),
      ),
    );
  }
}

class _SimpleMonthlyHeatmap extends StatefulWidget {
  const _SimpleMonthlyHeatmap();

  @override
  State<_SimpleMonthlyHeatmap> createState() => _SimpleMonthlyHeatmapState();
}

class _SimpleMonthlyHeatmapState extends State<_SimpleMonthlyHeatmap> {
  final Map<int, List<AttendanceRecord>> _cache = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllMonths());
  }

  Future<void> _loadAllMonths() async {
    final now = DateTime.now();
    final user = context.read<UserProvider>();
    final stored = await StoredSession.load();
    final token = user.token?.isNotEmpty == true ? user.token : stored?.token;
    final api = ApiClient();
    final svc = AttendanceService(api);

    for (int m = 1; m <= 12; m++) {
      try {
        final list = await svc.list(token: token, year: now.year, month: m);
        _cache[m] = list.map((e) => AttendanceRecord.fromJson(e)).toList();
      } catch (_) {
        _cache[m] = [];
      }
      if (!mounted) break;
      setState(() {});
    }

    api.close();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      children: [
        // Months Jan-Jun
        Row(
          children: List.generate(6, (i) {
            final month = i + 1;
            return Expanded(
              child: _MonthHeatmapCard(month: month, year: now.year, records: _cache[month] ?? []),
            );
          }),
        ),
        const SizedBox(height: 8),
        // Months Jul-Dec
        Row(
          children: List.generate(6, (i) {
            final month = i + 7;
            return Expanded(
              child: _MonthHeatmapCard(month: month, year: now.year, records: _cache[month] ?? []),
            );
          }),
        ),
      ],
    );
  }
}

class _MonthHeatmapCard extends StatefulWidget {
  final int month;
  final int year;
  final List<AttendanceRecord> records;

  const _MonthHeatmapCard({required this.month, required this.year, required this.records});

  @override
  State<_MonthHeatmapCard> createState() => _MonthHeatmapCardState();
}

class _MonthHeatmapCardState extends State<_MonthHeatmapCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Animasi muncul secara berurutan per bulan
    Future.delayed(Duration(milliseconds: (widget.month - 1) * 150), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const monthNames = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    const dayNames = ['M', 'W', 'F', 'S'];
    
    final firstDay = DateTime(widget.year, widget.month, 1);
    final lastDay = DateTime(widget.year, widget.month + 1, 0);
    
    Color getCellColor(DateTime day) {
      if (day.month != widget.month || day.isAfter(DateTime.now())) return const Color(0xFFE8E8E8);

      final record = widget.records.cast<AttendanceRecord?>().firstWhere(
        (r) => r != null && r.date.year == day.year && r.date.month == day.month && r.date.day == day.day,
        orElse: () => null,
      );

      if (record == null) {
        if (day.weekday == 6 || day.weekday == 7) return const Color(0xFFE8E8E8);
        return const Color(0xFFE8E8E8);
      }

      if (record.isAbsent) return const Color(0xFFE74C3C);
      if (record.isLeave || record.isSick) return const Color(0xFFF39C12);
      return const Color(0xFF27AE60);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            children: [
              Text(monthNames[widget.month - 1], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
              const SizedBox(height: 4),
              Row(
                children: List.generate(4, (dayIdx) {
                  return Expanded(
                    child: Column(
                      children: [
                        if (dayIdx == 0) Text(dayNames[dayIdx], style: const TextStyle(fontSize: 7, color: Color(0xFFCCCCCC))),
                        const SizedBox(height: 2),
                        ...List.generate((lastDay.day / 7).ceil(), (weekIdx) {
                          final dayOfMonth = weekIdx * 7 + dayIdx + 1;
                          if (dayOfMonth > lastDay.day) return Container();
                          final day = DateTime(widget.year, widget.month, dayOfMonth);
                          final color = getCellColor(day);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Container(
                              width: double.infinity,
                              height: 6,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceSummarySection extends StatelessWidget {
  const _AttendanceSummarySection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attendance Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Consumer<AttendanceProvider>(
            builder: (context, p, _) => Row(
              children: [
                _SummaryCard(label: 'Hadir', value: p.presentCount.toString(), color: const Color(0xFF2D82F4)),
                const SizedBox(width: 12),
                _SummaryCard(label: 'Absen', value: p.absentCount.toString(), color: const Color(0xFFF16063)),
                const SizedBox(width: 12),
                _SummaryCard(label: 'Cuti', value: p.leaveCount.toString(), color: const Color(0xFFF2C94C)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

