// lib/screens/home/home_screen.dart
// Phase 5: filter tanggal aktif + unduh laporan CSV

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/pengunjung_provider.dart';
import '../../utils/csv_generator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── State ───────────────────────────────────────────────────

  // Filter untuk stat cards + chart
  DateTime _selectedDate = DateTime.now();

  // Filter untuk download CSV
  late DateTime _dlMulai;
  late DateTime _dlSelesai;

  Map<String, int> _stats = {'VIP': 0, 'REGULER': 0, 'CITYLIGHT': 0};
  bool _loadingStats = true;
  bool _isDownloading = false;

  static const int _totalSlot = 47; // 6 VIP + 10 Reguler + 31 Citylight
  static final _fmtYmd = DateFormat('yyyy-MM-dd');

  // ── Init ────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Default download range: awal bulan ini → hari ini
    final now = DateTime.now();
    _dlMulai = DateTime(now.year, now.month, 1);
    _dlSelesai = now;
    _loadStats();
  }

  // ── Stat loading ────────────────────────────────────────────

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _loadingStats = true);
    final stats = await context
        .read<PengunjungProvider>()
        .statsByDate(_fmtYmd.format(_selectedDate));
    if (mounted) setState(() { _stats = stats; _loadingStats = false; });
  }

  Future<void> _refresh() async {
    await context.read<PengunjungProvider>().loadAll();
    await _loadStats();
  }

  // ── Date pickers ────────────────────────────────────────────

  Future<void> _pickStatDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFF0088FF)),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      await _loadStats();
    }
  }

  Future<void> _pickDownloadDate(bool isMulai) async {
    final initial = isMulai ? _dlMulai : _dlSelesai;
    final firstDate = isMulai
        ? DateTime(2020)
        : _dlMulai;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFF0088FF)),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isMulai) {
          _dlMulai = picked;
          // Pastikan selesai tidak lebih awal dari mulai
          if (_dlSelesai.isBefore(_dlMulai)) _dlSelesai = _dlMulai;
        } else {
          _dlSelesai = picked;
        }
      });
    }
  }

  // ── Download CSV ─────────────────────────────────────────────

  Future<void> _downloadCsv() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final result = await CsvGenerator.generateAndShare(
        tanggalMulai: _fmtYmd.format(_dlMulai),
        tanggalSelesai: _fmtYmd.format(_dlSelesai),
      );

      if (!mounted) return;
      if (result.status == ShareResultStatus.success) {
        _showSnack('Laporan berhasil dibagikan ✓', Colors.green.shade600);
      }
      // dismissed → tidak perlu feedback (user sengaja batal)
      // unavailable → tidak support share di perangkat ini
    } on CsvGeneratorException catch (e) {
      if (mounted) _showSnack(e.message, Colors.orange.shade700);
    } catch (e) {
      if (mounted) _showSnack('Gagal membuat laporan. Coba lagi.', Colors.red.shade600);
      debugPrint('[CSV] Error: $e');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Computed ────────────────────────────────────────────────

  int get _totalTerpakai =>
      (_stats['VIP'] ?? 0) +
      (_stats['REGULER'] ?? 0) +
      (_stats['CITYLIGHT'] ?? 0);

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF0088FF),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Header ──────────────────────────────────
              const Text(
                'Kebun Rojo Camp',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // ── Date filter pill ─────────────────────────
              _DateFilterPill(
                date: _selectedDate,
                isToday: _isToday,
                onTap: _pickStatDate,
                onResetToToday: () {
                  setState(() => _selectedDate = DateTime.now());
                  _loadStats();
                },
              ),
              const SizedBox(height: 28),

              // ── Stat cards ───────────────────────────────
              if (_loadingStats)
                const SizedBox(
                  height: 140,
                  child: Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF0088FF)),
                  ),
                )
              else
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    _StatCard(
                      icon: Icons.holiday_village_outlined,
                      label: 'Total Slot',
                      value: _totalSlot.toString(),
                      subtitle: 'kapasitas',
                    ),
                    _StatCard(
                      icon: Icons.star_outline,
                      label: 'VIP & Mini',
                      value: (_stats['VIP'] ?? 0).toString(),
                      subtitle: 'terpakai',
                      highlight: (_stats['VIP'] ?? 0) > 0,
                    ),
                    _StatCard(
                      icon: Icons.gite_outlined,
                      label: 'Reguler',
                      value: (_stats['REGULER'] ?? 0).toString(),
                      subtitle: 'terpakai',
                      highlight: (_stats['REGULER'] ?? 0) > 0,
                    ),
                    _StatCard(
                      icon: Icons.light_outlined,
                      label: 'Citylight',
                      value: (_stats['CITYLIGHT'] ?? 0).toString(),
                      subtitle: 'terpakai',
                      highlight: (_stats['CITYLIGHT'] ?? 0) > 0,
                    ),
                  ],
                ),
              const SizedBox(height: 28),

              // ── Donut chart ──────────────────────────────
              _ChartCard(
                stats: _stats,
                totalTerpakai: _totalTerpakai,
                isLoading: _loadingStats,
              ),
              const SizedBox(height: 28),

              // ── Download section ─────────────────────────
              _DownloadCard(
                dlMulai: _dlMulai,
                dlSelesai: _dlSelesai,
                isDownloading: _isDownloading,
                onPickMulai: () => _pickDownloadDate(true),
                onPickSelesai: () => _pickDownloadDate(false),
                onDownload: _downloadCsv,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────

class _DateFilterPill extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final VoidCallback onTap;
  final VoidCallback onResetToToday;

  const _DateFilterPill({
    required this.date,
    required this.isToday,
    required this.onTap,
    required this.onResetToToday,
  });

  @override
  Widget build(BuildContext context) {
    final label = isToday
        ? 'Hari ini, ${DateFormat('d MMM yyyy').format(date)}'
        : DateFormat('d MMMM yyyy').format(date);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isToday
                    ? const Color(0xFF0088FF)
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: isToday
                      ? const Color(0xFF0088FF)
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isToday
                        ? const Color(0xFF0088FF)
                        : Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down,
                    size: 16,
                    color: isToday
                        ? const Color(0xFF0088FF)
                        : Colors.grey),
              ],
            ),
          ),
        ),
        // Tombol reset ke hari ini (hanya tampil kalau bukan hari ini)
        if (!isToday) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onResetToToday,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0088FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Hari ini',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF0088FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final bool highlight;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: highlight
            ? Border.all(color: const Color(0xFF0088FF), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: highlight
                      ? const Color(0xFF0088FF)
                      : Colors.black54),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: highlight
                        ? const Color(0xFF0088FF)
                        : Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
                fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final Map<String, int> stats;
  final int totalTerpakai;
  final bool isLoading;

  const _ChartCard({
    required this.stats,
    required this.totalTerpakai,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistik Slot Terpakai',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Total $totalTerpakai slot aktif',
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(
                        color: Color(0xFF0088FF)),
                  ),
                )
              : totalTerpakai == 0
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(Icons.tent_outlined,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text(
                              'Tidak ada slot aktif di tanggal ini',
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 58,
                          sections: [
                            if ((stats['VIP'] ?? 0) > 0)
                              PieChartSectionData(
                                color: const Color(0xFF0088FF),
                                value: (stats['VIP'] ?? 0).toDouble(),
                                title: '${stats['VIP']}',
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                radius: 32,
                              ),
                            if ((stats['REGULER'] ?? 0) > 0)
                              PieChartSectionData(
                                color: const Color(0xFFFBBF24),
                                value: (stats['REGULER'] ?? 0).toDouble(),
                                title: '${stats['REGULER']}',
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                radius: 32,
                              ),
                            if ((stats['CITYLIGHT'] ?? 0) > 0)
                              PieChartSectionData(
                                color: const Color(0xFFF97316),
                                value: (stats['CITYLIGHT'] ?? 0).toDouble(),
                                title: '${stats['CITYLIGHT']}',
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                radius: 32,
                              ),
                          ],
                        ),
                      ),
                    ),
          if (totalTerpakai > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(const Color(0xFF0088FF), 'VIP'),
                const SizedBox(width: 20),
                _LegendDot(const Color(0xFFFBBF24), 'Reguler'),
                const SizedBox(width: 20),
                _LegendDot(const Color(0xFFF97316), 'Citylight'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _DownloadCard extends StatelessWidget {
  final DateTime dlMulai;
  final DateTime dlSelesai;
  final bool isDownloading;
  final VoidCallback onPickMulai;
  final VoidCallback onPickSelesai;
  final VoidCallback onDownload;

  const _DownloadCard({
    required this.dlMulai,
    required this.dlSelesai,
    required this.isDownloading,
    required this.onPickMulai,
    required this.onPickSelesai,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Unduh Data Pengunjung',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Filter berdasarkan tanggal check-in',
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),

          // Date range pickers
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  label: 'Dari',
                  value: fmt.format(dlMulai),
                  onTap: onPickMulai,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatePickerField(
                  label: 'Sampai',
                  value: fmt.format(dlSelesai),
                  onTap: onPickSelesai,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Unduh button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isDownloading ? null : onDownload,
              icon: isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Icon(Icons.download_outlined, size: 20),
              label: Text(
                isDownloading ? 'Membuat CSV...' : 'Unduh CSV',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'File CSV bisa dibuka di Excel, Google Sheets, atau LibreOffice.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87),
                  ),
                ),
                const Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
