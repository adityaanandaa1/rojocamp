# Roadmap Pengembangan
**Proyek:** Aplikasi Pencatatan Pengunjung — Kebun Rojo Camp
**Versi:** 2.0 (Flutter)

---

## Prinsip Urutan

Urutan fase ini dirancang berdasarkan dua aturan:
1. **Fondasi dulu** — fitur yang bergantung pada data harus dibangun setelah data model-nya solid.
2. **Tes nyata di tiap fase** — jangan lanjut ke fase berikutnya sebelum fase ini bisa dipakai dan dicoba di kondisi real (atau minimal di emulator dengan data buatan yang representatif).

---

## Fase 1: Fondasi — Project Setup + Database + CRUD Dasar

**Goal:** App jalan, admin bisa input dan lihat data pengunjung. Belum ada Denah, QR, atau chart.

**Yang dibangun:**
- Setup project Flutter baru (pubspec.yaml dengan semua dependencies, struktur folder sesuai design.md)
- `database_helper.dart`: inisialisasi sqflite, create 3 tabel (pengunjung, slot_tenda, pengunjung_slot), on-create seed semua slot master
- Model Dart untuk 3 entitas
- `PengunjungRepository`: insert, getAll, getById, updateStatus, delete
- `TambahPengunjungScreen` (tanpa Denah dulu — field Jenis sementara pakai dropdown biasa: VIP/Reguler/Citylight)
- `DaftarPengunjungScreen`: list semua pengunjung + status badge (hijau/merah)
- `DetailPengunjungScreen`: tampilkan semua field (tanpa QR dulu)
- Bottom navigation bar yang berfungsi
- Provider basic untuk state management

**Selesai kalau:** Admin bisa input rombongan baru, lihat di daftar, buka detail. Semua data tersimpan dan persist setelah app ditutup-buka.

**Jangan lanjut ke Fase 2 sebelum:** data insert, read, dan delete terbukti benar di sqflite. Cek dengan SQLite browser atau debug print.

---

## Fase 2: Denah Tenda

**Goal:** Admin bisa memilih slot spesifik secara visual. Slot yang sudah dipesan di tanggal sama tampil abu-abu.

**Yang dibangun:**
- `DenahTendaScreen` dengan 3 section: VIP (list), Reguler (grid A–J), Citylight (grouped Ground 1–9)
- `DenahProvider`: state slot dipilih (Set\<String\>), slot terpakai (Set\<String\>), dan query conflict detection
- Query conflict detection di `slot_repository.dart` (SQL overlap tanggal)
- Warna slot: putih/biru/abu-abu sesuai state
- Validasi: Denah hanya bisa dibuka setelah tanggal mulai & selesai diisi
- Integrasi Denah ↔ TambahPengunjungScreen: field Jenis menampilkan semua slot terpilih (per baris)
- Integrasi simpan: `pengunjung_slot` ter-insert bersama `pengunjung` dalam satu transaksi DB

**Selesai kalau:** Bisa input 2 rombongan di tanggal yang sama, pilih slot yang sama → slot itu tampil abu-abu untuk rombongan kedua. Cek dengan data test: rombongan A tanggal 20–22, buka Denah untuk rombongan B tanggal 21–23 → slot A seharusnya abu-abu.

**Jangan lanjut ke Fase 3 sebelum:** Conflict detection terbukti benar untuk semua edge case: overlap sebagian (tidak hanya sama persis), dan slot NON_AKTIF tidak ikut dihitung.

---

## Fase 3: Generate QR + Share

**Goal:** Setiap rombongan punya QR code yang bisa dikirim ke pengunjung via WhatsApp.

**Yang dibangun:**
- Tambahkan `qr_flutter` ke `DetailPengunjungScreen`: tampilkan QrImageView dengan isi = pengunjung.id
- `qr_share_helper.dart`: screenshot widget QR → simpan sementara → share via `share_plus`
- Tombol share di DetailPengunjungScreen
- Pastikan QR-nya benar-benar encode UUID yang unik (bukan data lain)

**Selesai kalau:** QR bisa ditampilkan untuk setiap rombongan, di-screenshot, dan di-share ke WhatsApp sebagai gambar.

---

## Fase 4: Scan QR → Update Status

**Goal:** Admin scan QR pengunjung yang pulang → status berubah ke NON_AKTIF, slot-nya kembali tersedia di Denah.

**Yang dibangun:**
- `ScanQRScreen` menggunakan `mobile_scanner`
- Setelah QR di-scan: lookup `pengunjung` by id di DB → validasi status (harus AKTIF) → update ke NON_AKTIF + catat `waktu_checkout`
- Feedback: snackbar sukses (nama rombongan + waktu) atau snackbar error (QR tidak dikenal / sudah NON_AKTIF)
- Akses ScanQRScreen dari icon di app bar `DaftarPengunjungScreen`
- Setelah scan sukses, Daftar otomatis refresh (status ter-update)

**Selesai kalau:** Coba full flow — input rombongan → QR muncul di detail → scan QR → status berubah merah di daftar → buka Denah untuk rombongan baru di tanggal yang sama → slot yang tadi dipesan sekarang putih lagi (tersedia).

---

## Fase 5: Home Screen — Statistik + Unduh CSV

**Goal:** Admin bisa lihat ringkasan kunjungan hari ini (atau tanggal lain) dan unduh laporan.

**Yang dibangun:**
- `HomeScreen` dengan date filter (default: hari ini)
- Query statistik: jumlah slot terpakai per kategori di tanggal tersebut (dari `pengunjung_slot` JOIN `pengunjung` WHERE status=AKTIF AND overlap tanggal)
- 4 stat cards: Total Tenda (statis), VIP terpakai, Reguler terpakai, Citylight terpakai
- Donut chart (`fl_chart` PieChart) dengan 3 segmen warna
- Section unduh laporan: date range picker + tombol Unduh
- `csv_generator.dart`: query data dalam rentang → bangun CSV string → simpan → share

**Selesai kalau:** Filter tanggal mengubah angka stat cards dan chart. Tombol unduh menghasilkan file CSV yang bisa dibuka di Excel/Sheets dengan semua kolom yang benar.

---

## Fase 6: Sinkronisasi Cloud (Google Sheets)

**Goal:** Data di-backup ke Google Sheets saat ada internet, tanpa mengganggu operasional offline.

**Yang dibangun:**
- Setup Google Apps Script (gunakan `Code.gs` yang sudah ada di output sebelumnya) + deploy sebagai Web App
- `sync_service.dart`: ambil semua record `synced=0` → POST ke Apps Script endpoint → jika sukses set `synced=1`
- `connectivity_plus`: cek koneksi saat app dibuka → auto-sync jika online
- Tambahkan tombol "Sync Manual" + indikator "X record belum ter-sync" di HomeScreen atau Settings

**Selesai kalau:** Input data offline → matikan WiFi → input beberapa record → nyalakan WiFi → buka app → data otomatis ter-sync → cek Google Sheets, data baru ada.

---

## Ringkasan Timeline (Estimasi, Bekerja Serius)

| Fase | Estimasi Waktu | Catatan |
|------|---------------|---------|
| 1 | 3–5 hari | Lebih lama kalau masih belajar sqflite dari nol |
| 2 | 5–7 hari | Fase terkompleks — jangan terburu-buru |
| 3 | 1–2 hari | Relatif mudah, library sudah handle banyak hal |
| 4 | 2–3 hari | Kamera permission dan edge case butuh testing |
| 5 | 3–5 hari | Query statistik dan chart setup butuh waktu |
| 6 | 2–3 hari | Jika Apps Script sudah siap, sisanya straightforward |
| **Total** | **~3–4 minggu kerja serius** | Asumsi ~3–4 jam/hari |

> Kalau dikerjakan di sela-sela kuliah dengan deadline akademik lain: targetkan 6–8 minggu, bukan 3–4. Lebih baik perkiraan realistis dari awal daripada proyek mati di tengah jalan.

---

## Yang Harus Dikerjakan Sebelum Mulai Kode

1. **Buat project Flutter baru** (`flutter create rojocamp`), tambahkan semua dependency ke pubspec.yaml sekaligus — lebih mudah dari menambah satu-satu nanti.
2. **Verifikasi repo GitHub sudah siap** — pastikan .gitignore ada (jangan push `build/`, `*.apk`).
3. **Buat Google Sheets baru** dengan tab "Rombongan" (bisa nanti di Fase 6, tapi baiknya disiapkan lebih awal).
4. **Catat UUID generator** — gunakan package `uuid` di Dart, bukan random string manual.
