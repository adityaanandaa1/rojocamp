// lib/utils/csv_generator.dart
//
// Menghasilkan file CSV laporan pengunjung dalam rentang tanggal,
// lalu membuka system share sheet.
//
// Catatan penting: file diawali BOM (0xEF 0xBB 0xBF) agar Excel
// membaca karakter UTF-8 (nama Indonesia, keterangan) dengan benar.
// Tanpa BOM, Excel sering salah baca huruf seperti é, ñ, dll.

import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/database/seed_data.dart';
import '../data/models/pengunjung.dart';
import '../data/repositories/pengunjung_repository.dart';

class CsvGenerator {
  CsvGenerator._(); // utility class

  // Cache label slot dari data statis
  static final Map<String, String> _slotLabels = {
    for (final s in kSemuaSlot) s.id: s.labelDisplay,
  };

  // Header kolom CSV — urutan ini yang akan muncul di Excel
  static const List<String> _headers = [
    'No',
    'Nama Pengunjung',
    'Alamat',
    'Tanggal Masuk',
    'Tanggal Keluar',
    'Jumlah Orang',
    'Jenis Pesanan',
    'Tenda Dipilih',
    'Status',
    'Waktu Checkout',
    'Keterangan',
  ];

  /// Generate CSV dari data pengunjung dalam rentang [tanggalMulai, tanggalSelesai]
  /// (filter berdasarkan tanggal_mulai pengunjung).
  ///
  /// Throws [CsvGeneratorException] jika tidak ada data dalam rentang tersebut.
  static Future<ShareResult> generateAndShare({
    required String tanggalMulai,   // format: YYYY-MM-DD
    required String tanggalSelesai, // format: YYYY-MM-DD
  }) async {
    // 1. Ambil data dari DB
    final list = await PengunjungRepository()
        .getByDateRange(tanggalMulai, tanggalSelesai);

    if (list.isEmpty) {
      throw CsvGeneratorException(
        'Tidak ada data pengunjung\n'
        'dalam rentang tanggal $tanggalMulai s/d $tanggalSelesai.',
      );
    }

    // 2. Bangun string CSV
    final csvContent = _buildCsv(list);

    // 3. Simpan ke cache dengan BOM
    final file = await _saveToTemp(csvContent, tanggalMulai, tanggalSelesai);

    // 4. Share — user bisa pilih WhatsApp, email, Google Drive, dll.
    return Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Laporan Pengunjung Kebun Rojo Camp',
      text: '📊 Laporan Pengunjung Kebun Rojo Camp\n'
            '📅 Periode: ${_fmtDate(tanggalMulai)} s/d ${_fmtDate(tanggalSelesai)}\n'
            '👥 Total: ${list.length} rombongan\n\n'
            'Buka file CSV dengan Excel atau Google Sheets.',
    );
  }

  // ── CSV Building ─────────────────────────────────────────────

  static String _buildCsv(List<Pengunjung> list) {
    final buf = StringBuffer();

    // Header row
    buf.writeln(_headers.map(_quoteCsvField).join(','));

    // Data rows
    for (int i = 0; i < list.length; i++) {
      final p = list[i];

      // Gabungkan semua slot dengan " ; " agar mudah dibaca di satu cell Excel
      final tendaText = p.slotIds.isEmpty
          ? '-'
          : p.slotIds.map((id) => _slotLabels[id] ?? id).join(' ; ');

      final row = [
        '${i + 1}',
        p.nama,
        p.alamat,
        _fmtDate(p.tanggalMulai),
        _fmtDate(p.tanggalSelesai),
        '${p.jumlahPengunjung}',
        p.jenisPesanan == 'RESERVASI' ? 'Reservasi' : 'Onsite',
        tendaText,
        p.status == 'AKTIF' ? 'Aktif' : 'Non-Aktif',
        p.waktuCheckout != null ? _fmtDatetime(p.waktuCheckout!) : '-',
        p.keterangan ?? '-',
      ];

      buf.writeln(row.map(_quoteCsvField).join(','));
    }

    return buf.toString();
  }

  /// Quoting CSV yang benar per RFC 4180:
  /// - Jika field mengandung koma, quote, atau newline → wrap dengan ""
  /// - Double quote di dalam field → escape jadi ""
  static String _quoteCsvField(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  // ── File Management ──────────────────────────────────────────

  static Future<File> _saveToTemp(
    String csvContent,
    String mulai,
    String selesai,
  ) async {
    final dir = await getTemporaryDirectory();
    final laporanDir = Directory('${dir.path}/laporan');

    // Bersihkan file laporan lama
    if (await laporanDir.exists()) {
      await for (final entity in laporanDir.list()) {
        if (entity is File) {
          await entity.delete().catchError((_) => entity);
        }
      }
    } else {
      await laporanDir.create(recursive: true);
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final safeRange = '${mulai}_${selesai}'.replaceAll('-', '');
    final file = File('${laporanDir.path}/rojocamp_$safeRange\_$ts.csv');

    // Tulis BOM dulu, lalu content CSV sebagai UTF-8
    // BOM = [0xEF, 0xBB, 0xBF] — penanda encoding UTF-8 untuk Excel
    final sink = file.openWrite();
    sink.add([0xEF, 0xBB, 0xBF]);
    sink.write(csvContent);
    await sink.flush();
    await sink.close();

    return file;
  }

  // ── Format helpers ───────────────────────────────────────────

  static String _fmtDate(String yyyyMmDd) {
    try {
      return DateFormat('dd/MM/yyyy')
          .format(DateFormat('yyyy-MM-dd').parse(yyyyMmDd));
    } catch (_) {
      return yyyyMmDd;
    }
  }

  static String _fmtDatetime(String iso) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

// ── Custom exception ─────────────────────────────────────────────

class CsvGeneratorException implements Exception {
  final String message;
  const CsvGeneratorException(this.message);

  @override
  String toString() => message;
}
