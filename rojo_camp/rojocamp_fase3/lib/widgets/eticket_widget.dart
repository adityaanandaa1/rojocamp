// lib/widgets/eticket_widget.dart
//
// Widget e-ticket yang dipakai di DUA tempat sekaligus:
// 1. Ditampilkan di DetailPengunjungScreen (di dalam RepaintBoundary)
// 2. Di-screenshot oleh QrShareHelper untuk dikirim via WhatsApp
//
// PENTING: Widget ini TIDAK boleh pakai MediaQuery karena
// saat di-screenshot bisa jalan di luar context layar biasa.
// Semua ukuran harus fixed pixel value.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/models/pengunjung.dart';

class EticketWidget extends StatelessWidget {
  final Pengunjung pengunjung;

  /// Map dari slotId → labelDisplay.
  /// Gunakan kSemuaSlot dari seed_data.dart:
  /// `{for (final s in kSemuaSlot) s.id: s.labelDisplay}`
  final Map<String, String> slotLabels;

  const EticketWidget({
    super.key,
    required this.pengunjung,
    required this.slotLabels,
  });

  // ── Computed values ────────────────────────────────────────

  String get _slotText {
    if (pengunjung.slotIds.isEmpty) return '-';
    return pengunjung.slotIds
        .map((id) => slotLabels[id] ?? id)
        .join('\n');
  }

  String _fmtDate(String yyyyMmDd) {
    try {
      return DateFormat('dd MMM yyyy')
          .format(DateFormat('yyyy-MM-dd').parse(yyyyMmDd));
    } catch (_) {
      return yyyyMmDd;
    }
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(),
          _Body(
            nama: pengunjung.nama,
            slotText: _slotText,
            tanggalMulai: _fmtDate(pengunjung.tanggalMulai),
            tanggalSelesai: _fmtDate(pengunjung.tanggalSelesai),
            jumlah: '${pengunjung.jumlahPengunjung} orang',
            jenis: pengunjung.jenisPesanan == 'RESERVASI'
                ? 'Reservasi'
                : 'Onsite',
          ),
          _DashedDivider(),
          _QrSection(qrData: pengunjung.id),
          _Footer(),
        ],
      ),
    );
  }
}

// ── Section widgets (private, hanya dipakai di EticketWidget) ──

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0088FF),
      ),
      child: Column(
        children: [
          const Text(
            '🏕️  KEBUN ROJO CAMP',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'E-TICKET PENGUNJUNG',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final String nama;
  final String slotText;
  final String tanggalMulai;
  final String tanggalSelesai;
  final String jumlah;
  final String jenis;

  const _Body({
    required this.nama,
    required this.slotText,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.jumlah,
    required this.jenis,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          _Row(label: 'Nama',   value: nama),
          _Row(label: 'Tenda',  value: slotText),
          _Row(label: 'Masuk',  value: tanggalMulai),
          _Row(label: 'Keluar', value: tanggalSelesai),
          _Row(label: 'Orang',  value: jumlah),
          _Row(label: 'Jenis',  value: jenis),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(':  ', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        // Dashed line manual: alternating container + gap
        child: Row(
          children: List.generate(
            42,
            (i) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                height: 1.5,
                color: i.isEven
                    ? Colors.grey.shade300
                    : Colors.transparent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QrSection extends StatelessWidget {
  final String qrData;

  const _QrSection({required this.qrData});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        children: [
          // QR code — ukuran fixed 170, tidak bergantung layar
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 170,
            gapless: true,
            errorStateBuilder: (_, __) => const SizedBox(
              width: 170,
              height: 170,
              child: Center(
                child: Text('QR Error', style: TextStyle(color: Colors.red)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tunjukkan QR ini kepada admin saat checkout',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.grey.shade50,
      child: Text(
        'Diterbitkan: $now',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
      ),
    );
  }
}
