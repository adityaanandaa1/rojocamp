/**
 * Code.gs — Backend Google Apps Script untuk Kebun Rojo Camp
 *
 * DUA fungsi:
 * 1. doPost  → menerima sync data dari aplikasi Android (dipanggil HTTP POST)
 * 2. doGet   → menyajikan halaman Dashboard admin (dibuka lewat browser)
 *
 * ── CARA SETUP ────────────────────────────────────────────────
 * 1. Buka spreadsheet → Extensions → Apps Script
 * 2. Paste seluruh isi file ini di editor (ganti semua konten lama)
 * 3. Tambah file HTML baru bernama "Dashboard" → paste isi Dashboard.html
 * 4. Deploy → New Deployment → Web App
 *    - Execute as  : Me
 *    - Who has access: Anyone
 * 5. Copy URL deployment → paste ke lib/config/app_config.dart
 *
 * ── PENTING ───────────────────────────────────────────────────
 * Setiap kali Code.gs diubah → harus deploy ulang (versi baru).
 * Kalau tidak, app Android masih pakai versi kode lama.
 * ─────────────────────────────────────────────────────────────
 */

// Nama tab sheet — harus sama persis dengan AppConfig.sheetsTabName di Dart
var SHEET_NAME = 'Rombongan';

// Urutan kolom header di sheet — urutan ini yang menentukan posisi kolom Excel
var HEADERS = [
  'id',
  'nama',
  'alamat',
  'tanggal_mulai',
  'tanggal_selesai',
  'jumlah_pengunjung',
  'jenis_pesanan',
  'slot_terpilih_label',  // "VIP 2; Reguler A; Ground 4 C" — mudah dibaca
  'slot_terpilih_id',     // "VIP2;REG_A;CL_4C" — untuk referensi teknis
  'status',
  'waktu_checkout',
  'keterangan',
  'created_at',
  'synced_at'             // waktu Apps Script menerima data ini (server-side)
];

// ── doGet: Sajikan Dashboard ─────────────────────────────────────

function doGet(e) {
  return HtmlService.createHtmlOutputFromFile('Dashboard')
    .setTitle('Dashboard Kebun Rojo Camp')
    .addMetaTag('viewport', 'width=device-width, initial-scale=1');
}

// ── doPost: Terima sync dari aplikasi Android ─────────────────────

function doPost(e) {
  try {
    var payload = JSON.parse(e.postData.contents);
    var records = payload.records;

    if (!Array.isArray(records) || records.length === 0) {
      return _jsonResponse({ status: 'ok', message: 'No records to sync', synced: 0 });
    }

    var sheet = _getOrCreateSheet();

    // Pastikan baris header ada
    _ensureHeaders(sheet);

    var syncedAt = new Date().toISOString();
    var insertedCount = 0;

    records.forEach(function(record) {
      var existingRow = _findRowById(sheet, record.id);

      if (existingRow > 0) {
        // Record sudah ada → UPDATE baris (status bisa berubah, misal checkout)
        _updateRow(sheet, existingRow, record, syncedAt);
      } else {
        // Record baru → INSERT baris baru
        _insertRow(sheet, record, syncedAt);
        insertedCount++;
      }
    });

    return _jsonResponse({
      status: 'ok',
      synced: records.length,
      inserted: insertedCount,
      updated: records.length - insertedCount
    });

  } catch (err) {
    // Log error ke Stackdriver (bisa dilihat di Apps Script → Executions)
    console.error('doPost error:', err);
    return _jsonResponse({ status: 'error', message: err.toString() }, 500);
  }
}

// ── Fungsi yang dipanggil dari Dashboard.html ─────────────────────

/**
 * Ambil semua data dari sheet sebagai array of objects.
 * Dipanggil lewat google.script.run dari browser (Dashboard).
 */
function ambilSemuaData() {
  var sheet = _getOrCreateSheet();
  var data = sheet.getDataRange().getValues();
  if (data.length <= 1) return JSON.stringify([]); // hanya header / kosong

  var headers = data[0];
  var rows = data.slice(1); // buang baris header

  var result = rows.map(function(row) {
    var obj = {};
    headers.forEach(function(h, i) {
      // Konversi Date object ke string agar JSON-safe
      var val = row[i];
      if (val instanceof Date) {
        obj[h] = val.toISOString();
      } else {
        obj[h] = val;
      }
    });
    return obj;
  });

  return JSON.stringify(result);
}

// ── Private helpers ───────────────────────────────────────────────

function _getOrCreateSheet() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName(SHEET_NAME);
  if (!sheet) {
    sheet = ss.insertSheet(SHEET_NAME);
  }
  return sheet;
}

function _ensureHeaders(sheet) {
  if (sheet.getLastRow() === 0) {
    sheet.appendRow(HEADERS);
    // Format baris header: bold + background biru
    var headerRange = sheet.getRange(1, 1, 1, HEADERS.length);
    headerRange.setFontWeight('bold');
    headerRange.setBackground('#0088FF');
    headerRange.setFontColor('#FFFFFF');
    // Freeze baris header agar tidak ikut scroll
    sheet.setFrozenRows(1);
  }
}

/**
 * Cari baris berdasarkan id (kolom pertama).
 * Return nomor baris (1-indexed) atau -1 kalau tidak ketemu.
 */
function _findRowById(sheet, id) {
  var lastRow = sheet.getLastRow();
  if (lastRow <= 1) return -1; // hanya header atau kosong

  // Ambil kolom id saja (kolom 1) dari baris 2 ke bawah
  var idColumn = sheet.getRange(2, 1, lastRow - 1, 1).getValues();
  for (var i = 0; i < idColumn.length; i++) {
    if (idColumn[i][0] === id) return i + 2; // +2: 1-indexed + skip header
  }
  return -1;
}

function _recordToRow(record, syncedAt) {
  return [
    record.id || '',
    record.nama || '',
    record.alamat || '',
    record.tanggal_mulai || '',
    record.tanggal_selesai || '',
    record.jumlah_pengunjung || 0,
    record.jenis_pesanan || '',
    record.slot_terpilih_label || '',
    Array.isArray(record.slot_terpilih_id)
      ? record.slot_terpilih_id.join(';')
      : (record.slot_terpilih_id || ''),
    record.status || '',
    record.waktu_checkout || '',
    record.keterangan || '',
    record.created_at || '',
    syncedAt
  ];
}

function _insertRow(sheet, record, syncedAt) {
  sheet.appendRow(_recordToRow(record, syncedAt));
}

function _updateRow(sheet, rowNum, record, syncedAt) {
  var row = _recordToRow(record, syncedAt);
  sheet.getRange(rowNum, 1, 1, row.length).setValues([row]);
}

function _jsonResponse(data, statusCode) {
  var output = ContentService.createTextOutput(JSON.stringify(data));
  output.setMimeType(ContentService.MimeType.JSON);
  return output;
}
