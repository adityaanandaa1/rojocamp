// lib/screens/detail_pengunjung/detail_pengunjung_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/pengunjung.dart';
import '../../data/models/slot_tenda.dart';
import '../../data/repositories/slot_repository.dart';
import '../../providers/pengunjung_provider.dart';

class DetailPengunjungScreen extends StatefulWidget {
  final String pengunjungId;

  const DetailPengunjungScreen({super.key, required this.pengunjungId});

  @override
  State<DetailPengunjungScreen> createState() =>
      _DetailPengunjungScreenState();
}

class _DetailPengunjungScreenState extends State<DetailPengunjungScreen> {
  // Cache label slot agar tidak query ulang setiap rebuild
  Map<String, String> _slotLabels = {};

  @override
  void initState() {
    super.initState();
    _loadSlotLabels();
  }

  Future<void> _loadSlotLabels() async {
    final slots = await SlotRepository().getAll();
    if (mounted) {
      setState(() {
        _slotLabels = {for (final s in slots) s.id: s.labelDisplay};
      });
    }
  }

  Pengunjung? _find(List<Pengunjung> list) {
    try {
      return list.firstWhere((p) => p.id == widget.pengunjungId);
    } catch (_) {
      return null;
    }
  }

  // ── Actions ─────────────────────────────────────────────────

  Future<void> _batalkan(BuildContext ctx, String id) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pesanan'),
        content: const Text(
          'Yakin ingin membatalkan pesanan ini?\n'
          'Status akan berubah menjadi Non-Aktif dan slot tenda dikosongkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Batalkan',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    await context.read<PengunjungProvider>().batalkan(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan dibatalkan'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengunjung'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<PengunjungProvider>(
        builder: (ctx, provider, _) {
          final p = _find(provider.list);

          if (p == null) {
            return const Center(
              child: Text('Data tidak ditemukan', style: TextStyle(color: Colors.grey)),
            );
          }

          final isAktif = p.status == 'AKTIF';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge di atas
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isAktif
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAktif ? 'Aktif' : 'Non-Aktif',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Detail fields
                _Field(label: 'Nama Pengunjung', value: p.nama),
                const SizedBox(height: 14),
                _Field(
                  label: 'Jenis Tenda',
                  value: p.slotIds.isEmpty
                      ? '-'
                      : p.slotIds
                          .map((id) => _slotLabels[id] ?? id)
                          .join('\n'),
                ),
                const SizedBox(height: 14),
                _Field(label: 'Alamat', value: p.alamat),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label: 'Tanggal Mulai',
                        value: _formatDate(p.tanggalMulai),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _Field(
                        label: 'Tanggal Selesai',
                        value: _formatDate(p.tanggalSelesai),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Field(
                    label: 'Jumlah Pengunjung',
                    value: '${p.jumlahPengunjung} orang'),
                const SizedBox(height: 14),
                _Field(
                  label: 'Jenis Pesanan',
                  value: p.jenisPesanan == 'RESERVASI'
                      ? 'Reservasi (via WhatsApp)'
                      : 'Onsite (datang langsung)',
                ),
                const SizedBox(height: 14),
                _Field(label: 'Keterangan', value: p.keterangan ?? '-'),

                if (p.waktuCheckout != null) ...[
                  const SizedBox(height: 14),
                  _Field(
                    label: 'Waktu Checkout',
                    value: _formatDateTime(p.waktuCheckout!),
                  ),
                ],

                const SizedBox(height: 32),

                // ── QR Code (Phase 3 placeholder) ──────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.qr_code_2,
                          size: 90, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      const Text(
                        'QR Code',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Akan tersedia di Fase 3',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${p.id.substring(0, 8)}...',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Tombol batalkan ────────────────────────────
                if (isAktif)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => _batalkan(ctx, p.id),
                      icon: const Icon(Icons.cancel_outlined,
                          size: 18, color: Colors.red),
                      label: const Text(
                        'Batalkan Pesanan',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String yyyyMmDd) {
    try {
      return DateFormat('dd MMMM yyyy').format(
        DateFormat('yyyy-MM-dd').parse(yyyyMmDd),
      );
    } catch (_) {
      return yyyyMmDd;
    }
  }

  String _formatDateTime(String iso) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

// ── Shared widgets ──────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final String value;

  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
