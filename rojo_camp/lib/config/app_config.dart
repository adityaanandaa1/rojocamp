// lib/config/app_config.dart
//
// ═══════════════════════════════════════════════════════════════
//  WAJIB DIISI sebelum build APK untuk pertama kali:
//
//  1. Buat project di https://script.google.com
//  2. Paste isi Code.gs (lihat file Code.gs di output)
//  3. Deploy → New Deployment → Web App
//     - Execute as : Me
//     - Who has access: Anyone with the link
//  4. Copy URL yang muncul (format: https://script.google.com/macros/s/xxx/exec)
//  5. Paste URL itu di bawah menggantikan string placeholder
//  6. Jalankan: flutter pub get → flutter run
// ═══════════════════════════════════════════════════════════════

class AppConfig {
  AppConfig._(); // utility class

  /// URL Google Apps Script Web App.
  /// GANTI string ini dengan URL deployment kamu.
  ///
  /// Contoh: 'https://script.google.com/macros/s/AKfycbxXXXXX/exec'
  static const String appScriptUrl =
      'https://script.google.com/macros/s/AKfycbzl587YA9445mlFi9kKn3ad42dDmOfRFvwHCFU1jld0yFBURYfe3cVk6G54xzAM1aeuqQ/exec';

  /// Nama tab di Google Sheets yang menerima data sync.
  /// Harus sama persis dengan nama sheet di spreadsheet kamu.
  static const String sheetsTabName = 'Rombongan';

  /// Timeout HTTP per request (detik).
  /// Apps Script cold-start bisa lambat, 30 detik cukup aman.
  static const int httpTimeoutSeconds = 30;

  /// Cek apakah URL sudah diisi (bukan placeholder).
  static bool get isConfigured =>
      appScriptUrl.isNotEmpty &&
      !appScriptUrl.startsWith('GANTI_');
}
