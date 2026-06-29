// lib/screens/detail_pengunjung/detail_pengunjung_screen.dart
// Phase 3 (maks): EticketWidget nyata + share robust + handle ShareResult

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/database/seed_data.dart';
import '../../data/models/pengunjung.dart';
import '../../providers/pengunjung_provider.dart';
import '../../utils/qr_share_helper.dart';
import '../../widgets/eticket_widget.dart';

class DetailPengunjungScreen extends StatefulWidget {
  final String pengunjungId;

  const DetailPengunjungScreen({super.key, required this.pengunjungId});

  @override
  State<DetailPengunjungScreen> createState() =>
      _DetailPengunjungScreenState();
}

class _DetailPengunjungScreenState extends State<DetailPengunjungScreen> {
  // GlobalKey HARUS di-declare sebagai field state — bukan di build().
  // Kalau di build(), key akan berubah tiap rebuild dan _getBoundary() gagal.
  final GlobalKey _eticketKey = GlobalKey();

  bool _isSharing = false;

  // Cache label statis dari seed_data — tidak perlu query DB
  static final Map<String, String> _slotLabels = {
    for (final s in kSemuaSlot) s.id: s.labelDisplay,
  };

  Pengunjung? _find(List<Pengunjung> list) {
    try {
      return list.firstWhere((p) => p.id == widget.pengunjungId);
    } catch (_) {
      return null;
    }
  }

  // ── Share QR ────────────────────────────────────────────────

  Future<void> _share(Pengunjung p) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final shareText =
          '🏕️ E-Ticket Kebun Rojo Camp\n'
          '👤 ${p.nama}\n'
          '📅 ${p.tanggalMulai} → ${p.tanggalSelesai}\n\n'
          'Simpan gambar ini dan tunjukkan kepada admin saat checkout.';

      final result = await QrShareHelper.share(
        repaintKey: _eticketKey,
        fileName: 'eticket_${p.nama}',
        shareText: shareText,
      );

      if (!mounted) return;

      // Handle hasil share secara eksplisit — jangan asumsi semua sukses
      switch (result.status) {
        case ShareResultStatus.success:
          _showSnack(
            '✓ E-ticket berhasil dikirim',
            color: Colors.green.shade600,
          );
        case ShareResultStatus.dismissed:
          // User tutup share sheet — tidak perlu tampilkan apa-apa
          break;
        case ShareResultStatus.unavailable:
          _showSnack(
            'Fitur share tidak tersedia di perangkat ini',
            color: Colors.orange.shade600,
          );
      }
    } on QrShareException catch (e) {
      // Error yang kita define sendiri — pesan sudah informatif
      if (mounted) _showSnack(e.message, color: Colors.red.shade600);
    } catch (e) {
      // Error tidak terduga — log untuk debug, tampilkan pesan generik
      debugPrint('[QrShare] Unexpected error: $e');
      if (mounted) {
        _showSnack('Gagal share. Coba lagi.', color: Colors.red.shade600);
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  // ── Batalkan pesanan ────────────────────────────────────────

  Future<void> _batalkan(BuildContext ctx, String id) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pesanan'),
        content: const Text(
          'Yakin ingin membatalkan pesanan ini?\n'
          'Status berubah jadi Non-Aktif dan slot tenda dikosongkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Batalkan',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    await context.read<PengunjungProvider>().batalkan(id);
    if (mounted) {
      _showSnack('Pesanan dibatalkan', color: Colors.orange.shade700);
    }
  }

  void _showSnack(String msg, {required Color color}) {
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
              child: Text('Data tidak ditemukan',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          final isAktif = p.status == 'AKTIF';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status badge ────────────────────────────
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
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

                // ── Field data ──────────────────────────────
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
                            value: _fmtDate(p.tanggalMulai))),
                    const SizedBox(width: 14),
                    Expanded(
                        child: _Field(
                            label: 'Tanggal Selesai',
                            value: _fmtDate(p.tanggalSelesai))),
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
                _Field(
                    label: 'Keterangan',
                    value: p.keterangan ?? '-'),
                if (p.waktuCheckout != null) ...[
                  const SizedBox(height: 14),
                  _Field(
                      label: 'Waktu Checkout',
                      value: _fmtDatetime(p.waktuCheckout!)),
                ],

                const SizedBox(height: 32),

                // ── E-Ticket ────────────────────────────────
                //
                // RepaintBoundary membatasi area yang di-screenshot.
                // _eticketKey menunjuk ke boundary ini.
                // EticketWidget yang sama muncul di layar DAN jadi screenshot.
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: RepaintBoundary(
                    key: _eticketKey,
                    // Container putih di dalam boundary —
                    // agar screenshot punya background bersih (bukan transparan)
                    child: Container(
                      color: Colors.white,
                      child: EticketWidget(
                        pengunjung: p,
                        slotLabels: _slotLabels,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Tombol share ────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : () => _share(p),
                    icon: _isSharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(Icons.share_outlined, size: 20),
                    label: Text(
                      _isSharing ? 'Menyiapkan e-ticket...' : 'Kirim E-Ticket ke Pengunjung',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Petunjuk kecil di bawah tombol
                Text(
                  'E-ticket dikirim sebagai gambar. '
                  'Pengunjung menyimpannya dan menunjukkan saat checkout.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                ),

                const SizedBox(height: 24),

                // ── Batalkan (hanya jika AKTIF) ─────────────
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
                            color: Colors.red,
                            fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  String _fmtDate(String yyyyMmDd) {
    try {
      return DateFormat('dd MMMM yyyy')
          .format(DateFormat('yyyy-MM-dd').parse(yyyyMmDd));
    } catch (_) {
      return yyyyMmDd;
    }
  }

  String _fmtDatetime(String iso) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

// ── Shared widget ───────────────────────────────────────────────

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
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 13),
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
