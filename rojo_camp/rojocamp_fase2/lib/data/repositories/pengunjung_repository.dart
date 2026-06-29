// lib/data/repositories/pengunjung_repository.dart

import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/pengunjung.dart';

class PengunjungRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<Database> get _database => _db.database;

  /// INSERT pengunjung + semua slotnya dalam satu transaksi atomic.
  /// Jika salah satu gagal, semua di-rollback.
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

  /// Ambil semua pengunjung beserta slot-nya, urut dari terbaru.
  Future<List<Pengunjung>> getAll() async {
    final db = await _database;
    final rows = await db.query('pengunjung', orderBy: 'created_at DESC');
    final result = <Pengunjung>[];
    for (final row in rows) {
      final slots = await _getSlotIds(db, row['id'] as String);
      result.add(Pengunjung.fromMap(row, slotIds: slots));
    }
    return result;
  }

  /// Ambil satu pengunjung by ID beserta slot-nya.
  Future<Pengunjung?> getById(String id) async {
    final db = await _database;
    final rows =
        await db.query('pengunjung', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final slots = await _getSlotIds(db, id);
    return Pengunjung.fromMap(rows.first, slotIds: slots);
  }

  /// Checkout: ubah status ke NON_AKTIF, catat waktu checkout.
  Future<void> checkout(String id, String waktuCheckout) async {
    final db = await _database;
    await db.update(
      'pengunjung',
      {
        'status': 'NON_AKTIF',
        'waktu_checkout': waktuCheckout,
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Batalkan pesanan manual (no-show) — sama dengan checkout.
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

  /// Hapus pengunjung — slot di pengunjung_slot ikut terhapus (CASCADE).
  Future<void> delete(String id) async {
    final db = await _database;
    await db.delete('pengunjung', where: 'id = ?', whereArgs: [id]);
  }

  /// Statistik slot terpakai per kategori untuk tanggal tertentu.
  ///
  /// "Terpakai" = rombongan AKTIF yang tanggalnya overlap dengan [tanggal].
  /// Overlap: tanggal_mulai <= tanggal < tanggal_selesai
  Future<Map<String, int>> getStatsByDate(String tanggal) async {
    final db = await _database;
    const query = '''
      SELECT st.kategori, COUNT(ps.slot_id) AS jumlah
      FROM pengunjung_slot ps
      INNER JOIN pengunjung  p  ON ps.pengunjung_id = p.id
      INNER JOIN slot_tenda  st ON ps.slot_id       = st.id
      WHERE p.status         = 'AKTIF'
        AND p.tanggal_mulai  <= ?
        AND p.tanggal_selesai > ?
      GROUP BY st.kategori
    ''';
    final result = await db.rawQuery(query, [tanggal, tanggal]);

    final stats = <String, int>{'VIP': 0, 'REGULER': 0, 'CITYLIGHT': 0};
    for (final row in result) {
      final kat = row['kategori'] as String;
      stats[kat] = row['jumlah'] as int;
    }
    return stats;
  }

  /// Ambil semua record yang belum di-sync (untuk Phase 6).
  Future<List<Pengunjung>> getUnsynced() async {
    final db = await _database;
    final rows = await db.query('pengunjung', where: 'synced = 0');
    final result = <Pengunjung>[];
    for (final row in rows) {
      final slots = await _getSlotIds(db, row['id'] as String);
      result.add(Pengunjung.fromMap(row, slotIds: slots));
    }
    return result;
  }

  /// Tandai record sebagai sudah ter-sync (untuk Phase 6).
  Future<void> markSynced(List<String> ids) async {
    final db = await _database;
    final batch = db.batch();
    for (final id in ids) {
      batch.update('pengunjung', {'synced': 1},
          where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  // ── Helper ────────────────────────────────────────────────────

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
