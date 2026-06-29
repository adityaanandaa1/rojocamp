// lib/screens/daftar_pengunjung/daftar_pengunjung_screen.dart
// Phase 4: aktifkan scan icon di app bar

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/pengunjung.dart';
import '../../providers/pengunjung_provider.dart';
import '../detail_pengunjung/detail_pengunjung_screen.dart';
import '../scan_qr/scan_qr_screen.dart';

class DaftarPengunjungScreen extends StatelessWidget {
  const DaftarPengunjungScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pengunjung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF0088FF)),
            tooltip: 'Scan QR Checkout',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScanQrScreen()),
            ),
            // Provider notifyListeners() otomatis setelah checkout,
            // jadi list refresh sendiri saat kembali ke sini.
          ),
        ],
      ),
      body: Consumer<PengunjungProvider>(
        builder: (ctx, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0088FF)),
            );
          }

          if (provider.list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text(
                    'Belum ada pengunjung terdaftar',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tekan tombol + untuk menambahkan',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF0088FF),
            onRefresh: () => provider.loadAll(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
              itemCount: provider.list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) =>
                  _PengunjungCard(pengunjung: provider.list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _PengunjungCard extends StatelessWidget {
  final Pengunjung pengunjung;
  const _PengunjungCard({required this.pengunjung});

  @override
  Widget build(BuildContext context) {
    final isAktif = pengunjung.status == 'AKTIF';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DetailPengunjungScreen(pengunjungId: pengunjung.id),
        ),
      ),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pengunjung.nama,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_fmtDate(pengunjung.tanggalMulai)} → ${_fmtDate(pengunjung.tanggalSelesai)}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pengunjung.jenisPesanan} • ${pengunjung.jumlahPengunjung} orang',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
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
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(String yyyyMmDd) {
    try {
      return DateFormat('dd MMM')
          .format(DateFormat('yyyy-MM-dd').parse(yyyyMmDd));
    } catch (_) {
      return yyyyMmDd;
    }
  }
}
