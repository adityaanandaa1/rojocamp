// lib/data/repositories/slot_repository.dart

import '../database/database_helper.dart';
import '../models/slot_tenda.dart';

class SlotRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Ambil semua slot, urut sort_order.
  Future<List<SlotTenda>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('slot_tenda', orderBy: 'sort_order ASC');
    return rows.map(SlotTenda.fromMap).toList();
  }

  /// Slot yang sudah terpakai di rentang [tanggalMulai, tanggalSelesai).
  ///
  /// Dipakai di Fase 2 (Denah Tenda) untuk mewarnai slot abu-abu.
  /// Logic overlap: A overlap B jika A_mulai < B_selesai AND A_selesai > B_mulai
  ///
  /// [excludePengunjungId]: isi saat mode "edit" agar slot milik sendiri tidak ikut dihitung.
  Future<Set<String>> getBookedSlotIds({
    required String tanggalMulai,
    required String tanggalSelesai,
    String? excludePengunjungId,
  }) async {
    final db = await _db.database;

    var query = '''
      SELECT ps.slot_id
      FROM pengunjung_slot ps
      INNER JOIN pengunjung p ON ps.pengunjung_id = p.id
      WHERE p.status          = 'AKTIF'
        AND p.tanggal_mulai   < ?
        AND p.tanggal_selesai > ?
    ''';
    final args = <String>[tanggalSelesai, tanggalMulai];

    if (excludePengunjungId != null) {
      query += ' AND p.id != ?';
      args.add(excludePengunjungId);
    }

    final result = await db.rawQuery(query, args);
    return result.map((r) => r['slot_id'] as String).toSet();
  }
}
