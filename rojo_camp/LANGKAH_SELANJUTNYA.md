# Langkah Selanjutnya — Rojo Camp
**Setelah semua file selesai di IDE (Android Studio / VS Code)**

---

## Langkah 1: Setup Google Apps Script (satu kali)

### 1.1 Buat Spreadsheet dulu
1. Buka [sheets.google.com](https://sheets.google.com) → buat spreadsheet baru
2. Rename tab bawah (Sheet1) menjadi **`Rombongan`** (persis, huruf besar R)
3. Copy URL spreadsheet ini, akan dipakai di langkah 1.2

### 1.2 Buat project Apps Script
1. Buka [script.google.com](https://script.google.com) → **New Project**
2. Rename project: klik "Untitled project" → ketik **RojoCamp Sync**
3. Hapus semua isi editor yang ada
4. Paste seluruh isi file **`Code.gs`** (dari output yang sudah dibuat)
5. Klik ikon **Save** (atau Ctrl+S)

### 1.3 Sambungkan ke Spreadsheet
Di dalam editor Apps Script:
1. Klik ikon **Spreadsheet** (atau pilih menu **Project Settings** → **Script Properties**)
2. Sebenarnya tidak perlu setup manual — `SpreadsheetApp.getActiveSpreadsheet()` otomatis terhubung jika script dibuka dari dalam Spreadsheet

**Cara yang lebih mudah:**
1. Di Spreadsheet tadi → menu **Extensions** → **Apps Script**
2. Ini otomatis membuat project script yang terhubung ke spreadsheet itu
3. Paste Code.gs di sini
4. Save

### 1.4 Tambah file Dashboard
Masih di editor Apps Script:
1. Klik **+** di panel kiri samping nama file → **HTML**
2. Nama file: **`Dashboard`** (persis, tanpa spasi)
3. Hapus semua isi default → Paste seluruh isi file **`Dashboard.html`**
4. Save

### 1.5 Deploy sebagai Web App
1. Klik tombol **Deploy** (pojok kanan atas) → **New deployment**
2. Klik ikon ⚙️ di sebelah "Select type" → pilih **Web app**
3. Isi:
   - **Description:** `RojoCamp v1`
   - **Execute as:** `Me`
   - **Who has access:** `Anyone` *(biar app Android bisa POST tanpa login)*
4. Klik **Deploy**
5. **Copy URL** yang muncul — formatnya:
   ```
   https://script.google.com/macros/s/AKfycbxxxxxxxxxxxxxxx/exec
   ```
6. Klik **Done**

> ⚠️ **Setiap kali Code.gs diubah**, harus deploy ulang (**Deploy → Manage Deployments → Edit → New Version → Deploy**). Kalau tidak, app Android masih pakai versi lama.

---

## Langkah 2: Update `app_config.dart`

Buka file `lib/config/app_config.dart`, ganti baris ini:
```dart
static const String appScriptUrl = 'GANTI_DENGAN_URL_APPS_SCRIPT_KAMU';
```
Menjadi URL dari langkah 1.5:
```dart
static const String appScriptUrl = 'https://script.google.com/macros/s/AKfycbXXXXXX/exec';
```

Save file.

---

## Langkah 3: Install Dependencies

Di terminal VS Code / Android Studio Terminal:
```bash
# Masuk ke folder project
cd path/ke/rojo_camp

# Install semua package
flutter pub get
```

Kalau ada error `Could not resolve package`, coba:
```bash
flutter pub cache repair
flutter pub get
```

---

## Langkah 4: Cek Error Sebelum Run

Di VS Code: tekan **Ctrl+Shift+P** → **Flutter: Analyze Project**
Di Android Studio: menu **Analyze** → **Inspect Code**

**Error umum dan solusinya:**

| Error | Solusi |
|---|---|
| `Target of URI doesn't exist: '../utils/qr_share_helper.dart'` | Cek nama file dan folder sudah sama persis |
| `Undefined name 'kSemuaSlot'` | Pastikan ada `import '../../data/database/seed_data.dart'` |
| `The method 'withOpacity' is deprecated` | Ganti `withOpacity(x)` → `withValues(alpha: x)` |
| `sdk constraint` error | Pastikan `environment: sdk: ">=3.3.0 <4.0.0"` di pubspec.yaml |
| `MobileScannerController` error | Cek versi `mobile_scanner: ^7.2.0` di pubspec.yaml |

---

## Langkah 5: Run di Emulator

### Setup emulator (kalau belum ada):
**Android Studio:**
1. Menu **Tools** → **Device Manager** → **Create Device**
2. Pilih: **Pixel 6**, System Image: **API 34 (Android 14)**
3. Klik **Finish** → **Run** (segitiga hijau)

**VS Code:**
1. Ctrl+Shift+P → **Flutter: Launch Emulator**
2. Pilih emulator dari list

### Jalankan app:
```bash
flutter run
```
atau tekan **F5** di VS Code / tombol Run ▶ di Android Studio.

---

## Langkah 6: Testing Checklist (Jalankan Berurutan)

Setiap item harus lulus sebelum lanjut ke item berikutnya:

### ✅ Fase 1 — Database & CRUD
- [ ] Buka app → tidak crash → Home screen tampil
- [ ] Tekan **+** → Tambah Pengunjung terbuka
- [ ] Isi semua field → Tambah → muncul di Daftar Pengunjung
- [ ] Buka detail → semua data tampil benar
- [ ] Tutup app → buka lagi → data masih ada (persist)

### ✅ Fase 2 — Denah Tenda
- [ ] Tambah pengunjung A, pilih VIP2, tanggal 20–22 Jun → simpan
- [ ] Tambah pengunjung B, tanggal 21–23 Jun → buka Denah → **VIP2 harus abu-abu**
- [ ] Slot lain tetap putih → bisa dipilih
- [ ] Batalkan pengunjung A → Tambah B lagi → VIP2 sekarang putih (tersedia)

### ✅ Fase 3 — QR & Share
- [ ] Buka detail pengunjung → e-ticket tampil dengan semua info
- [ ] Tekan "Kirim E-Ticket" → system share sheet terbuka
- [ ] Share ke WhatsApp → gambar e-ticket terkirim (bukan file, bukan teks)

### ✅ Fase 4 — Scan QR
- [ ] Daftar Pengunjung → tekan ikon scan di kanan atas
- [ ] Kamera terbuka → arahkan ke QR dari layar lain (atau print)
- [ ] QR terdeteksi → bottom sheet sukses tampil dengan nama pengunjung
- [ ] Tekan "Selesai" → kembali ke Daftar → status berubah merah
- [ ] Scan QR yang sama lagi → muncul pesan "Sudah Checkout" (bukan error)

### ✅ Fase 5 — Statistik & CSV
- [ ] Home screen → stat cards menampilkan angka yang benar
- [ ] Tap date pill → ganti tanggal → angka berubah sesuai tanggal baru
- [ ] Tap "Hari ini" → kembali ke data hari ini
- [ ] Set rentang download → tap "Unduh CSV" → share sheet terbuka
- [ ] Buka file CSV di Google Sheets → semua kolom terbaca, huruf Indonesia benar

### ✅ Fase 6 — Sync (harus URL sudah dikonfigurasi)
- [ ] Tambah pengunjung baru → di Home, badge "N belum sync" muncul
- [ ] Tekan "Sync Sekarang" → loading → sukses snackbar hijau
- [ ] Buka Google Sheets → data muncul di tab Rombongan

---

## Langkah 7: Build APK untuk HP Admin

```bash
# Build release APK (lebih kecil dan lebih cepat dari debug)
flutter build apk --release

# APK tersimpan di:
# build/app/outputs/flutter-apk/app-release.apk
```

> Kalau muncul error `minSdkVersion`, buka `android/app/build.gradle` dan ubah:
> ```gradle
> defaultConfig {
>     minSdk 21        // ubah dari nilai yang lebih rendah
>     targetSdk 34
> }
> ```

---

## Langkah 8: Install APK di HP Admin

### Via USB (paling mudah):
1. Sambungkan HP ke laptop via USB
2. Copy file `app-release.apk` ke HP (folder Downloads)
3. Di HP: buka Files/File Manager → buka `app-release.apk`
4. Kalau muncul dialog **"Izinkan dari sumber ini"** → Aktifkan → Install
5. Buka app dari launcher → login

### Via WhatsApp/Telegram ke diri sendiri:
1. Kirim APK file ke chat "Saved Messages" di Telegram / chat diri sendiri di WhatsApp
2. Di HP: unduh file → buka → install

### Kalau HP blokir instalasi:
- **Settings** → **Security** (atau **Privacy**) → **Install Unknown Apps**
- Pilih aplikasi yang akan install (Files/Chrome/Telegram) → Aktifkan

---

## Langkah 9: Setelah Install — Setup di HP Admin

1. **Pertama kali buka:** tunggu beberapa detik — DB dan 47 slot di-seed otomatis
2. **Cek koneksi:** pastikan HP tersambung WiFi → tekan Sync untuk pertama kali
3. **Verifikasi:** buka Spreadsheet → data test (kalau ada) harus sudah muncul
4. **Bersihkan data test:** hapus entri-entri percobaan dari aplikasi

---

## Hal yang Perlu Dijaga Setelah Deployment

| Tugas | Kapan | Cara |
|---|---|---|
| Backup data | Setiap hari atau setelah banyak input | Tekan "Sync Sekarang" di Home |
| Update app | Kalau ada perbaikan | Rebuild APK → install ulang (data tidak hilang karena di SQLite lokal) |
| Cek Sheets | Mingguan | Buka spreadsheet → tab Rombongan |
| Hapus file temp | Otomatis | App sudah cleanup sendiri setiap share/download |

---

## Pertanyaan Umum

**Q: Data hilang setelah install ulang?**
A: Data di SQLite lokal (`rojocamp_v2.db`) akan hilang kalau app di-uninstall. Selalu sync sebelum uninstall. Setelah install ulang, data bisa dilihat di Google Sheets tapi tidak otomatis kembali ke app.

**Q: Denah Tenda berubah (ada tenda baru/dihapus)?**
A: Edit `lib/data/database/seed_data.dart` → rebuild APK → install. DB lama perlu di-uninstall dulu karena slot master di-seed hanya sekali saat install pertama.

**Q: Apps Script URL berubah?**
A: Ganti di `app_config.dart` → rebuild APK → install.

**Q: Scan QR tidak bisa (kamera tidak muncul)?**
A: Pastikan permission kamera sudah diizinkan: Settings HP → Apps → Rojo Camp → Permissions → Camera → Allow.
