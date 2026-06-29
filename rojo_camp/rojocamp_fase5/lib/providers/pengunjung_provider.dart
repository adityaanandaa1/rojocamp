// lib/providers/pengunjung_provider.dart

import 'package:flutter/foundation.dart';
import '../data/models/pengunjung.dart';
import '../data/repositories/pengunjung_repository.dart';

class PengunjungProvider extends ChangeNotifier {
  final PengunjungRepository _repo = PengunjungRepository();

  List<Pengunjung> _list = [];
  bool _isLoading = false;

  List<Pengunjung> get list => _list;
  bool get isLoading => _isLoading;

  List<Pengunjung> get aktif =>
      _list.where((p) => p.status == 'AKTIF').toList();
  List<Pengunjung> get nonAktif =>
      _list.where((p) => p.status == 'NON_AKTIF').toList();

  /// Muat ulang semua data dari SQLite.
  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    _list = await _repo.getAll();
    _isLoading = false;
    notifyListeners();
  }

  /// Simpan rombongan baru + slot-nya.
  Future<void> tambah(Pengunjung pengunjung, List<String> slotIds) async {
    await _repo.insert(pengunjung, slotIds);
    await loadAll();
  }

  /// Checkout via scan QR.
  Future<void> checkout(String id) async {
    await _repo.checkout(id, DateTime.now().toIso8601String());
    await loadAll();
  }

  /// Batalkan pesanan manual (no-show).
  Future<void> batalkan(String id) async {
    await _repo.batalkan(id);
    await loadAll();
  }

  /// Hapus data pengunjung (admin saja, bukan pengunjung).
  Future<void> hapus(String id) async {
    await _repo.delete(id);
    await loadAll();
  }

  /// Statistik slot terpakai per kategori di tanggal tertentu (untuk HomeScreen).
  Future<Map<String, int>> statsByDate(String tanggal) async {
    return await _repo.getStatsByDate(tanggal);
  }
}
