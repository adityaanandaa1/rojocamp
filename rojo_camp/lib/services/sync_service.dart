// lib/services/sync_service.dart

import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../data/database/seed_data.dart';
import '../data/models/pengunjung.dart';
import '../data/repositories/pengunjung_repository.dart';

// ── Result ───────────────────────────────────────────────────────

class SyncResult {
  final int synced;      // jumlah record yang berhasil di-sync
  final int skipped;     // jumlah record yang sudah synced sebelumnya
  final String? error;   // pesan error jika gagal, null jika sukses

  const SyncResult({
    required this.synced,
    this.skipped = 0,
    this.error,
  });

  bool get isSuccess => error == null;

  @override
  String toString() => isSuccess
      ? 'SyncResult: $synced synced, $skipped skipped'
      : 'SyncResult error: $error';
}

// ── Exception ────────────────────────────────────────────────────

class SyncException implements Exception {
  final String message;
  const SyncException(this.message);

  @override
  String toString() => message;
}

// ── Service ──────────────────────────────────────────────────────

class SyncService {
  SyncService._();

  static final Map<String, String> _slotLabels = {
    for (final s in kSemuaSlot) s.id: s.labelDisplay,
  };

  /// Sync semua record yang belum ter-sync ke Google Sheets.
  ///
  /// Throws [SyncException] dengan pesan yang bisa ditampilkan ke user.
  static Future<SyncResult> syncAll() async {
    // Guard: pastikan URL sudah dikonfigurasi
    if (!AppConfig.isConfigured) {
      throw const SyncException(
        'URL Apps Script belum dikonfigurasi.\n'
        'Edit lib/config/app_config.dart dan isi appScriptUrl.',
      );
    }

    // Cek koneksi internet
    await _checkConnectivity();

    // Ambil record yang belum ter-sync
    final repo = PengunjungRepository();
    final unsynced = await repo.getUnsynced();

    if (unsynced.isEmpty) {
      return const SyncResult(synced: 0, skipped: 0);
    }

    // Kirim ke Apps Script
    await _postToAppScript(unsynced);

    // Tandai semua sebagai ter-sync
    await repo.markSynced(unsynced.map((p) => p.id).toList());

    debugPrint('[Sync] ${unsynced.length} records synced successfully.');
    return SyncResult(synced: unsynced.length);
  }

  // ── Private ──────────────────────────────────────────────────

  static Future<void> _checkConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      // connectivity_plus 6.x mengembalikan List<ConnectivityResult>
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (!isOnline) {
        throw const SyncException(
          'Tidak ada koneksi internet.\n'
          'Sambungkan ke WiFi atau data seluler lalu coba lagi.',
        );
      }
    } on SyncException {
      rethrow;
    } catch (e) {
      // Kalau connectivity check error sendiri, coba tetap lanjut sync
      debugPrint('[Sync] Connectivity check error (ignored): $e');
    }
  }

  static Future<void> _postToAppScript(List<Pengunjung> records) async {
    final payload = jsonEncode({
      'records': records.map(_toJson).toList(),
    });

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(AppConfig.appScriptUrl),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(
            Duration(seconds: AppConfig.httpTimeoutSeconds),
            onTimeout: () => throw const SyncException(
              'Koneksi timeout (${AppConfig.httpTimeoutSeconds}s).\n'
              'Apps Script mungkin sedang lambat. Coba lagi.',
            ),
          );
    } on SyncException {
      rethrow;
    } catch (e) {
      throw SyncException('Gagal terhubung ke server: $e');
    }

    if (response.statusCode != 200) {
      throw SyncException(
        'Server mengembalikan error HTTP ${response.statusCode}.\n'
        'Cek Apps Script deployment URL.',
      );
    }

    // Parse respons Apps Script
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'ok') {
        final msg = data['message'] as String? ?? 'Unknown error';
        throw SyncException('Apps Script error: $msg');
      }
    } catch (e) {
      if (e is SyncException) rethrow;
      throw SyncException('Respons server tidak valid: $e');
    }
  }

  /// Konversi Pengunjung ke format JSON yang diharapkan Code.gs.
  static Map<String, dynamic> _toJson(Pengunjung p) {
    return {
      'id': p.id,
      'nama': p.nama,
      'alamat': p.alamat,
      'tanggal_mulai': p.tanggalMulai,
      'tanggal_selesai': p.tanggalSelesai,
      'jumlah_pengunjung': p.jumlahPengunjung,
      'jenis_pesanan': p.jenisPesanan,
      'keterangan': p.keterangan ?? '',
      'status': p.status,
      'waktu_checkout': p.waktuCheckout ?? '',
      // Slot terpilih dikirim sebagai list ID + label untuk readability di Sheets
      'slot_terpilih_id': p.slotIds,
      'slot_terpilih_label': p.slotIds
          .map((id) => _slotLabels[id] ?? id)
          .join('; '),
      'created_at': p.createdAt,
    };
  }
}
