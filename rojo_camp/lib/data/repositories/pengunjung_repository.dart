// lib/data/repositories/pengunjung_repository.dart

import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/pengunjung.dart';

class PengunjungRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<Database> get _database => _db.database;

  // ── Write ────────────────────────────────────────────────────

  /// INSERT pengunjung + semua slotnya dalam satu transaksi atomic.
  Future<void> insert(Pengunjung pengunjung, List<String> slotIds) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.insert(
        'pengunjung',
        pengunjung.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final slotId in slotIds) {
        await txn.insert('pengunjung_slot', {
          'pengunjung_id': pengunjung.id,
          'slot_id': slotId,
        });
      }
    });
  }

  /// Checkout: ubah status ke NON_AKTIF dan catat waktu.
  Future<void> checkout(String id, String waktuCheckout) async {
    final db = await _database;
    await db.update(
      'pengunjung',
      {'status': 'NON_AKTIF', 'waktu_checkout': waktuCheckout, 'synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Batalkan pesanan manual — sama dengan checkout dari sisi data.
  Future<void> batalkan(String id) async {
    final db = await _database;
    await db.update(
      'pengunjung',
      {
        'status': 'NON_AKTIF',
        'waktu_checkout': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Hapus pengunjung — slot di pengunjung_slot ikut CASCADE DELETE.
  Future<void> delete(String id) async {
    final db = await _database;
    await db.delete('pengunjung', where: 'id = ?', whereArgs: [id]);
  }

  // ── Read ─────────────────────────────────────────────────────

  /// Ambil semua pengunjung beserta slot-nya, urut terbaru dulu.
  Future<List<Pengunjung>> getAll() async {
    final db = await _database;
    final rows = await db.query('pengunjung', orderBy: 'created_at DESC');
    return _withSlots(db, rows);
  }

  /// Ambil satu pengunjung by UUID beserta slot-nya.
  Future<Pengunjung?> getById(String id) async {
    final db = await _database;
    final rows =
        await db.query('pengunjung', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final slots = await _getSlotIds(db, id);
    return Pengunjung.fromMap(rows.first, slotIds: slots);
  }

  /// Ambil pengunjung yang tanggal_mulai-nya dalam rentang [mulai, selesai].
  /// Dipakai oleh CsvGenerator untuk unduh laporan.
  ///
  /// Filter: `tanggal_mulai >= mulai AND tanggal_mulai <= selesai`
  /// Ini menampilkan pengunjung yang *mulai* camping dalam rentang tersebut.
  Future<List<Pengunjung>> getByDateRange(
      String mulai, String selesai) async {
    final db = await _database;
    final rows = await db.query(
      'pengunjung',
      where: 'tanggal_mulai >= ? AND tanggal_mulai <= ?',
      whereArgs: [mulai, selesai],
      orderBy: 'tanggal_mulai ASC, nama ASC',
    );
    return _withSlots(db, rows);
  }

  // ── Stats ────────────────────────────────────────────────────

  /// Jumlah slot terpakai per kategori di [tanggal].
  ///
  /// "Terpakai" = rombongan AKTIF yang tanggalnya mencakup [tanggal]:
  ///   `tanggal_mulai <= tanggal < tanggal_selesai`
  Future<Map<String, int>> getStatsByDate(String tanggal) async {
    final db = await _database;
    const query = '''
      SELECT st.kategori, COUNT(ps.slot_id) AS jumlah
      FROM pengunjung_slot ps
      INNER JOIN pengunjung  p  ON ps.pengunjung_id = p.id
      INNER JOIN slot_tenda  st ON ps.slot_id       = st.id
      WHERE p.status          = 'AKTIF'
        AND p.tanggal_mulai  <= ?
        AND p.tanggal_selesai > ?
      GROUP BY st.kategori
    ''';
    final result = await db.rawQuery(query, [tanggal, tanggal]);
    final stats = <String, int>{'VIP': 0, 'REGULER': 0, 'CITYLIGHT': 0};
    for (final row in result) {
      stats[row['kategori'] as String] = row['jumlah'] as int;
    }
    return stats;
  }

  // ── Sync (Phase 6) ───────────────────────────────────────────

  Future<List<Pengunjung>> getUnsynced() async {
    final db = await _database;
    final rows = await db.query('pengunjung', where: 'synced = 0');
    return _withSlots(db, rows);
  }

  Future<void> markSynced(List<String> ids) async {
    final db = await _database;
    final batch = db.batch();
    for (final id in ids) {
      batch.update('pengunjung', {'synced': 1},
          where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  // ── Helpers ──────────────────────────────────────────────────

  Future<List<Pengunjung>> _withSlots(
      Database db, List<Map<String, Object?>> rows) async {
    final result = <Pengunjung>[];
    for (final row in rows) {
      final slots = await _getSlotIds(db, row['id'] as String);
      result.add(Pengunjung.fromMap(row, slotIds: slots));
    }
    return result;
  }

  Future<List<String>> _getSlotIds(Database db, String pengunjungId) async {
    final rows = await db.query(
      'pengunjung_slot',
      columns: ['slot_id'],
      where: 'pengunjung_id = ?',
      whereArgs: [pengunjungId],
    );
    return rows.map((r) => r['slot_id'] as String).toList();
  }
}
