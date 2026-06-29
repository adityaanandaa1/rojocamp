// lib/screens/home/home_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/pengunjung_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, int> _stats = {'VIP': 0, 'REGULER': 0, 'CITYLIGHT': 0};
  bool _loadingStats = true;

  // Total slot statis sesuai seed_data.dart: 6 VIP + 10 Reguler + 31 Citylight
  static const int _totalSlot = 47;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final stats =
        await context.read<PengunjungProvider>().statsByDate(today);
    if (mounted) {
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _loadingStats = true);
    await context.read<PengunjungProvider>().loadAll();
    await _loadStats();
  }

  int get _totalTerpakai =>
      (_stats['VIP'] ?? 0) + (_stats['REGULER'] ?? 0) + (_stats['CITYLIGHT'] ?? 0);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tanggalStr = DateFormat('d MMMM yyyy', 'id_ID').format(now);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF0088FF),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Header ──────────────────────────────────────
              const Text(
                'Kebun Rojo Camp',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      tanggalStr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Stat Cards ───────────────────────────────────
              if (_loadingStats)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(color: Color(0xFF0088FF)),
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
                      label: 'Total Tenda',
                      value: _totalSlot.toString(),
                    ),
                    _StatCard(
                      icon: Icons.star_outline,
                      label: 'VIP & Mini',
                      value: (_stats['VIP'] ?? 0).toString(),
                    ),
                    _StatCard(
                      icon: Icons.gite_outlined,
                      label: 'Reguler A–J',
                      value: (_stats['REGULER'] ?? 0).toString(),
                    ),
                    _StatCard(
                      icon: Icons.light_outlined,
                      label: 'Citylight',
                      value: (_stats['CITYLIGHT'] ?? 0).toString(),
                    ),
                  ],
                ),
              const SizedBox(height: 28),

              // ── Donut Chart ──────────────────────────────────
              Container(
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
                      'Statistik Pengunjung',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _totalTerpakai == 0
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Column(
                                children: [
                                  Icon(Icons.bar_chart,
                                      size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'Belum ada pengunjung aktif hari ini',
                                    style: TextStyle(color: Colors.grey),
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
                                  if ((_stats['VIP'] ?? 0) > 0)
                                    PieChartSectionData(
                                      color: const Color(0xFF0088FF),
                                      value:
                                          (_stats['VIP'] ?? 0).toDouble(),
                                      title: '',
                                      radius: 28,
                                    ),
                                  if ((_stats['REGULER'] ?? 0) > 0)
                                    PieChartSectionData(
                                      color: const Color(0xFFFBBF24),
                                      value: (_stats['REGULER'] ?? 0)
                                          .toDouble(),
                                      title: '',
                                      radius: 28,
                                    ),
                                  if ((_stats['CITYLIGHT'] ?? 0) > 0)
                                    PieChartSectionData(
                                      color: const Color(0xFFF97316),
                                      value: (_stats['CITYLIGHT'] ?? 0)
                                          .toDouble(),
                                      title: '',
                                      radius: 28,
                                    ),
                                ],
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _LegendDot(color: Color(0xFF0088FF), label: 'VIP'),
                        SizedBox(width: 20),
                        _LegendDot(
                            color: Color(0xFFFBBF24), label: 'Reguler'),
                        SizedBox(width: 20),
                        _LegendDot(
                            color: Color(0xFFF97316), label: 'Citylight'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Download Placeholder (aktif di Fase 5) ────────
              Container(
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Filter tanggal & unduh CSV/Excel tersedia di Fase 5.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: null, // aktifkan di Fase 5
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('Unduh (Tersedia di Fase 5)'),
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: Colors.grey.shade200,
                          disabledForegroundColor: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80), // ruang FAB
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
