// lib/screens/denah_tenda/denah_tenda_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/database/seed_data.dart';
import '../../providers/denah_provider.dart';
import 'widgets/vip_section.dart';
import 'widgets/reguler_section.dart';
import 'widgets/citylight_section.dart';

/// Layar pemilihan slot tenda secara visual.
///
/// Dibuka dari TambahPengunjungScreen lewat Navigator.push,
/// mengembalikan Set<String> slot yang dipilih via Navigator.pop.
///
/// Cara pakai:
/// ```dart
/// final result = await Navigator.push<Set<String>>(
///   context,
///   MaterialPageRoute(
///     builder: (_) => DenahTendaScreen(
///       tanggalMulai: 'YYYY-MM-DD',
///       tanggalSelesai: 'YYYY-MM-DD',
///       initialSelected: currentSelectedIds,
///     ),
///   ),
/// );
/// if (result != null) { /* update state dengan slot baru */ }
/// ```
class DenahTendaScreen extends StatelessWidget {
  final String tanggalMulai;
  final String tanggalSelesai;
  final Set<String> initialSelected;
  final String? excludePengunjungId; // untuk mode edit

  const DenahTendaScreen({
    super.key,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.initialSelected = const {},
    this.excludePengunjungId,
  });

  @override
  Widget build(BuildContext context) {
    // Provider disediakan lokal di sini — tidak butuh masuk ke main.dart.
    // Scope-nya cuma hidup selama layar ini terbuka.
    return ChangeNotifierProvider(
      create: (_) => DenahProvider()
        ..init(
          tanggalMulai: tanggalMulai,
          tanggalSelesai: tanggalSelesai,
          initialSelected: initialSelected,
          excludePengunjungId: excludePengunjungId,
        ),
      child: const _DenahContent(),
    );
  }
}

class _DenahContent extends StatelessWidget {
  const _DenahContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DenahProvider>();

    // Pisahkan slot dari kSemuaSlot (data statis, tidak perlu query DB)
    final vipSlots =
        kSemuaSlot.where((s) => s.kategori == 'VIP').toList();
    final regulerSlots =
        kSemuaSlot.where((s) => s.kategori == 'REGULER').toList();
    final citylightSlots =
        kSemuaSlot.where((s) => s.kategori == 'CITYLIGHT').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Denah Tenda'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, null),
        ),
        actions: [
          // Tombol reset pilihan
          if (!provider.isLoading && provider.selectedCount > 0)
            TextButton(
              onPressed: () {
                for (final id in Set.from(provider.selected)) {
                  provider.toggleSlot(id);
                }
              },
              child: const Text(
                'Reset',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0088FF)),
                  SizedBox(height: 14),
                  Text(
                    'Mengecek ketersediaan tenda...',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Scrollable content
                SingleChildScrollView(
                  padding:
                      const EdgeInsets.fromLTRB(20, 16, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info tanggal
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          'Menampilkan ketersediaan: $tanggalMulai → $tanggalSelesai',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Legend
                      _Legend(),
                      const SizedBox(height: 20),

                      // VIP Section
                      VipSection(slots: vipSlots),
                      const SizedBox(height: 24),

                      // Reguler Section
                      RegulerSection(slots: regulerSlots),
                      const SizedBox(height: 24),

                      // Citylight Section
                      CitylightSection(slots: citylightSlots),
                    ],
                  ),
                ),

                // Tombol Pilih — fixed di bawah
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding:
                        const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: provider.selectedCount == 0
                              ? null
                              : () => Navigator.pop(
                                    context,
                                    provider.selected,
                                  ),
                          child: Text(
                            provider.selectedCount == 0
                                ? 'Pilih Tenda'
                                : 'Pilih  (${provider.selectedCount} slot dipilih)',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Legend ──────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LegendItem(
          color: Colors.white,
          borderColor: Colors.grey.shade400,
          label: 'Tersedia',
        ),
        const SizedBox(width: 14),
        const _LegendItem(
          color: Color(0xFF0088FF),
          borderColor: Color(0xFF0088FF),
          label: 'Dipilih',
        ),
        const SizedBox(width: 14),
        const _LegendItem(
          color: Color(0xFF7A7979),
          borderColor: Color(0xFF7A7979),
          label: 'Terisi',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final String label;

  const _LegendItem({
    required this.color,
    required this.borderColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
