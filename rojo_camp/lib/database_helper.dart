import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'pengunjung.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('rojocamp.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pengunjung (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        alamat TEXT NOT NULL,
        jenisTenda TEXT NOT NULL,
        status TEXT NOT NULL,
        tanggalMasuk TEXT NOT NULL,
        tanggalMulai TEXT NOT NULL,
        tanggalSelesai TEXT NOT NULL,
        jumlahPengunjung INTEGER NOT NULL,
        jenisPesanan TEXT NOT NULL,
        keterangan TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertPengunjung(Pengunjung pengunjung) async {
    final db = await instance.database;
    return await db.insert('pengunjung', pengunjung.toMap());
  }

  Future<List<Pengunjung>> getAllPengunjung() async {
    final db = await instance.database;
    final result = await db.query('pengunjung', orderBy: 'id DESC');
    return result.map((json) => Pengunjung.fromMap(json)).toList();
  }

  Future<int> checkoutPengunjung(int id) async {
    final db = await instance.database;
    return await db.rawUpdate('UPDATE pengunjung SET status = ? WHERE id = ?', ['Checkout', id]);
  }

  // --- LOGIKA UNTUK FITUR SEAT BOOKING & STATISTIK ---
  
  Future<List<String>> getBookedTents() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT jenisTenda FROM pengunjung WHERE status = 'Aktif'");
    return result.map((row) => row['jenisTenda'] as String).toList();
  }

  Future<int> countVIP() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COUNT(*) FROM pengunjung WHERE status = 'Aktif' AND (jenisTenda LIKE 'VIP%' OR jenisTenda = 'Mini Ground')");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countCitylight() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COUNT(*) FROM pengunjung WHERE status = 'Aktif' AND jenisTenda LIKE 'Ground%'");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countReguler() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COUNT(*) FROM pengunjung WHERE status = 'Aktif' AND jenisTenda LIKE 'Kavling%'");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countTotal() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COUNT(*) FROM pengunjung WHERE status = 'Aktif'");
    return Sqflite.firstIntValue(result) ?? 0;
  }
}