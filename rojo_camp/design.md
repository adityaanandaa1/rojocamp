# Design Document
**Proyek:** Aplikasi Pencatatan Pengunjung — Kebun Rojo Camp
**Versi:** 2.0 (Flutter)
**Terkait:** PRD.md, ROADMAP.md

---

## 1. Arsitektur: Local-First Flutter

```
[Flutter App — Local-First]
         │
         ├─ sqflite (SQLite lokal)   ← semua operasi harian di sini
         │     ├─ tabel: pengunjung
         │     ├─ tabel: slot_tenda (master, statis)
         │     └─ tabel: pengunjung_slot (junction)
         │
         ├─ qr_flutter               ← generate QR offline
         ├─ mobile_scanner           ← scan QR via kamera
         │
         └─ http                     ← saat online: push ke cloud
               │
               ▼
     [Google Apps Script Web App]
               │
               ▼
         [Google Sheets]             ← backup & laporan
```

Operasional harian (input, denah, QR, scan) = 100% offline.
Cloud hanya diakses saat sinkronisasi, bukan saat operasi normal.

---

## 2. Tech Stack

| Layer | Package/Tools | Alasan |
|-------|--------------|--------|
| Framework | Flutter (Dart) | Cross-platform, UI modern, satu codebase |
| Database lokal | `sqflite` + `path` | SQLite standard Flutter, ringan, offline |
| State management | `provider` | Cukup untuk 1-admin app, mudah dipelajari |
| Generate QR | `qr_flutter` | Simpel, offline, render sebagai widget |
| Scan QR | `mobile_scanner` | Akurasi tinggi, aktif di-maintain, on-device |
| HTTP sync | `http` | Cukup untuk POST ke Apps Script, tanpa overhead |
| Chart | `fl_chart` | Donut chart + bar chart, fleksibel, gratis |
| Share/export | `share_plus` + `path_provider` | Share QR image + simpan CSV ke storage |
| Konektivitas | `connectivity_plus` | Cek online/offline sebelum sync |
| Date picker | `intl` + Flutter native DatePicker | Format tanggal Indonesia |

**Total biaya: Rp0** — semua package di atas gratis (open-source, pub.dev).

---

## 3. Database Schema

### Tabel 1: `pengunjung`

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `id` | TEXT, PRIMARY KEY | UUID — juga isi QR code |
| `nama` | TEXT | Nama penanggung jawab rombongan |
| `alamat` | TEXT | |
| `tanggal_mulai` | TEXT | Format: YYYY-MM-DD |
| `tanggal_selesai` | TEXT | Format: YYYY-MM-DD (exclusive — malam terakhir = tgl_selesai - 1) |
| `jumlah_pengunjung` | INTEGER | |
| `jenis_pesanan` | TEXT | 'RESERVASI' / 'ONSITE' |
| `keterangan` | TEXT | Nullable |
| `status` | TEXT | 'AKTIF' / 'NON_AKTIF' |
| `waktu_checkout` | TEXT | Nullable, diisi saat scan QR |
| `created_at` | TEXT | Datetime string |
| `updated_at` | TEXT | |
| `synced` | INTEGER | 0 = belum sync, 1 = sudah sync |

### Tabel 2: `slot_tenda` (Master Data — di-seed saat app pertama install)

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `id` | TEXT, PRIMARY KEY | Kode unik: 'VIP1', 'VIP2', 'REG_A', 'CL_1A', 'CL_4C', dll |
| `kategori` | TEXT | 'VIP' / 'REGULER' / 'CITYLIGHT' |
| `label_display` | TEXT | Label tampilan: 'VIP 1', 'A', 'Ground 1 A', dll |
| `sort_order` | INTEGER | Urutan tampilan di Denah Tenda |

> Tabel ini statis — tidak berubah selama runtime. Di-seed sekali saat pertama install.

### Tabel 3: `pengunjung_slot` (Junction / Many-to-Many)

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `pengunjung_id` | TEXT | FK → pengunjung.id |
| `slot_id` | TEXT | FK → slot_tenda.id |
| PRIMARY KEY | (pengunjung_id, slot_id) | Satu rombongan tidak bisa pesan slot yang sama 2x |

---

## 4. Master Data Slot Tenda (Seed Data)

### VIP (6 slot)
| id | label_display | sort_order |
|----|---------------|------------|
| VIP5 | VIP 5 | 1 |
| VIP4 | VIP 4 | 2 |
| VIP3 | VIP 3 | 3 |
| VIP2 | VIP 2 | 4 |
| VIP_MINI | Mini Ground | 5 |
| VIP1 | VIP 1 | 6 |

### Reguler (10 slot, A–J)
| id | label_display | sort_order |
|----|---------------|------------|
| REG_A | A | 1 |
| REG_B | B | 2 |
| ... | ... | ... |
| REG_J | J | 10 |

### Citylight (31 slot)
| id | label_display | sort_order |
|----|---------------|------------|
| CL_1A | Ground 1 A | 1 |
| CL_1B | Ground 1 B | 2 |
| CL_1C | Ground 1 C | 3 |
| CL_2A | Ground 2 A | 4 |
| ... | ... | ... |
| CL_4C | Ground 4 C | 18 |
| ... | ... | ... |
| CL_9B | Ground 9 B | 31 |

> Detail lengkap seed data ada di `lib/data/database/seed_data.dart`

---

## 5. Logic Conflict Detection (Denah Tenda)

Query untuk mendapatkan semua slot_id yang sudah terpakai di rentang tanggal baru:

```sql
SELECT ps.slot_id
FROM pengunjung_slot ps
INNER JOIN pengunjung p ON ps.pengunjung_id = p.id
WHERE p.status = 'AKTIF'
AND p.tanggal_mulai < :tgl_selesai_baru
AND p.tanggal_selesai > :tgl_mulai_baru
```

Penjelasan kondisi overlap: dua rentang waktu [A_mulai, A_selesai) dan [B_mulai, B_selesai) overlap jika dan hanya jika `A_mulai < B_selesai AND A_selesai > B_mulai`.

Hasilnya dipakai di UI Denah Tenda:
- Slot id ada di hasil query → tampilkan abu-abu, tidak bisa dipilih.
- Slot id tidak ada → tampilkan putih (tersedia).
- Slot id dipilih user sekarang → tampilkan biru (#0088FF).

---

## 6. State Machine Status Pengunjung

```
[Input data] ──────────────────────► AKTIF
                                        │
                              Scan QR / Batalkan manual
                                        │
                                        ▼
                                   NON_AKTIF
```

Aturan:
- Semua pesanan baru (reservasi maupun onsite) langsung AKTIF saat disimpan.
- NON_AKTIF dicapai lewat scan QR (checkout) ATAU pembatalan manual oleh admin.
- NON_AKTIF tidak bisa diubah kembali ke AKTIF (final state).
- Slot dari pesanan NON_AKTIF tidak lagi masuk hitungan conflict detection.

---

## 7. Navigasi & Struktur Layar

```
Bottom Navigation Bar
├─ [Beranda]      → HomeScreen
├─ [+]            → TambahPengunjungScreen
└─ [Pengunjung]   → DaftarPengunjungScreen

HomeScreen
└─ (tidak ada navigasi keluar dari sini)

TambahPengunjungScreen
└─ field "Jenis" ditekan → DenahTendaScreen → kembali ke TambahPengunjungScreen

DaftarPengunjungScreen
└─ item ditekan → DetailPengunjungScreen
                  └─ tombol scan / icon scan → ScanQRScreen → kembali ke Daftar

ScanQRScreen (bisa juga diakses dari app bar DaftarPengunjung)
└─ Setelah scan sukses → feedback snackbar + kembali ke Daftar
```

---

## 8. Desain Tiap Layar

### HomeScreen
- Header: "Kebun Rojo Camp" + tanggal filter (tap untuk ubah, default = hari ini)
- 4 stat cards: Total Tenda (statis = jumlah semua slot), VIP terpakai, Reguler terpakai, Citylight terpakai di tanggal tersebut
- Donut chart (fl_chart PieChart): proporsi VIP/Reguler/Citylight dari pengunjung aktif di tanggal itu
- Section "Unduh Data": date range picker (tanggal mulai–selesai) + tombol Unduh → generate CSV → share/simpan

### TambahPengunjungScreen
- Field: Nama Pengunjung, Jenis (tap → DenahTendaScreen), Alamat, Tanggal Mulai, Tanggal Selesai, Jumlah Pengunjung, Jenis Pesanan (dropdown: Reservasi/Onsite), Keterangan (opsional)
- Validasi: Nama, Jenis (minimal 1 slot terpilih), Tanggal Mulai, Tanggal Selesai, Jumlah Pengunjung wajib diisi. Tanggal Mulai harus diisi sebelum bisa buka Denah Tenda.
- Tombol "Tambah Pengunjung" → simpan ke DB + generate QR + kembali ke Daftar

### DaftarPengunjungScreen
- List: nama pengunjung + label status (AKTIF=hijau, NON_AKTIF=merah)
- App bar: icon scan QR (akses ScanQRScreen)
- Tap item → DetailPengunjungScreen

### DetailPengunjungScreen
- Tampilkan semua field: Nama, Jenis (list slot dipilih per baris), Alamat, Tanggal Mulai, Tanggal Selesai, Jumlah Pengunjung, Jenis Pesanan, Keterangan
- QR code widget (qr_flutter) di bagian bawah
- Tombol share QR (screenshot widget → share via WhatsApp intent)
- Tombol "Batalkan Pesanan" (hanya jika status AKTIF) → dialog konfirmasi → set NON_AKTIF

### DenahTendaScreen
- 3 section: VIP (list vertikal named slots), Reguler (grid 2 kolom A–J), Citylight (grouped per Ground 1–9)
- Warna slot: putih = tersedia, biru = dipilih, abu-abu = terpakai (tidak bisa ditekan)
- Tombol "Pilih" (biru, fixed di bawah) → kembali ke TambahPengunjungScreen dengan data slot terpilih
- Slot abu-abu: tidak responsif terhadap tap

### ScanQRScreen
- Preview kamera full screen (mobile_scanner)
- Overlay frame scan di tengah
- Saat QR terdeteksi: lookup `pengunjung.id` dari DB, jika AKTIF → set NON_AKTIF, catat `waktu_checkout` → tampilkan snackbar sukses + nama pengunjung
- Jika QR tidak dikenali / sudah NON_AKTIF → tampilkan pesan error yang jelas

---

## 9. Generate QR

- Isi QR: `id` (UUID) dari record pengunjung — pointer ke DB lokal.
- Library: `qr_flutter` (Widget `QrImageView`).
- Di-generate on-demand saat DetailPengunjungScreen dibuka (bukan disimpan ke file).
- Untuk share: screenshot widget menggunakan `RepaintBoundary` + `RenderRepaintBoundary.toImage()` → simpan sementara ke `path_provider` → share via `share_plus`.

---

## 10. Sinkronisasi Cloud (Google Sheets)

Alur:
1. Setiap create/update record → set `synced = 0`.
2. Saat app dibuka + ada koneksi (cek via `connectivity_plus`) → jalankan sync otomatis.
3. Ambil semua record dengan `synced = 0` (pengunjung + slot terpilihnya).
4. HTTP POST ke endpoint Apps Script (JSON body).
5. Jika respons sukses → set `synced = 1`.
6. Jika gagal → tetap `synced = 0`, retry di sesi berikutnya.
7. Ada tombol "Sync Manual" di settings/home untuk force sync.

Data yang di-sync per record pengunjung:
```json
{
  "id": "uuid",
  "nama": "...",
  "alamat": "...",
  "tanggal_mulai": "YYYY-MM-DD",
  "tanggal_selesai": "YYYY-MM-DD",
  "jumlah_pengunjung": 7,
  "jenis_pesanan": "RESERVASI",
  "keterangan": "...",
  "status": "AKTIF",
  "slot_terpilih": ["VIP2", "REG_A", "CL_4C"],
  "created_at": "...",
  "waktu_checkout": null
}
```

---

## 11. Generate & Unduh Laporan (CSV)

- Filter: rentang tanggal (dari Home screen).
- Query: semua pengunjung dengan `tanggal_mulai >= tgl_filter_mulai AND tanggal_selesai <= tgl_filter_selesai`.
- Gabungkan data slot dari tabel `pengunjung_slot`.
- Bangun string CSV manual (tidak butuh library khusus untuk kasus sederhana ini).
- Kolom: ID, Nama, Alamat, Tgl Mulai, Tgl Selesai, Jumlah Orang, Jenis Pesanan, Slot Terpilih (digabung dengan `;`), Status, Waktu Checkout.
- Simpan ke direktori Downloads via `path_provider` → buka dengan `share_plus`.

---

## 12. Struktur Project (Disarankan)

```
lib/
├─ main.dart
├─ app.dart                          # MaterialApp, routes, theme
│
├─ data/
│   ├─ database/
│   │   ├─ database_helper.dart      # inisialisasi sqflite, createTables
│   │   └─ seed_data.dart            # data master semua slot (hardcoded)
│   ├─ models/
│   │   ├─ pengunjung.dart
│   │   ├─ slot_tenda.dart
│   │   └─ pengunjung_slot.dart
│   └─ repositories/
│       ├─ pengunjung_repository.dart
│       └─ slot_repository.dart
│
├─ providers/
│   ├─ pengunjung_provider.dart
│   └─ denah_provider.dart           # state slot dipilih + slot abu-abu
│
├─ screens/
│   ├─ home/
│   │   └─ home_screen.dart
│   ├─ tambah_pengunjung/
│   │   └─ tambah_pengunjung_screen.dart
│   ├─ daftar_pengunjung/
│   │   └─ daftar_pengunjung_screen.dart
│   ├─ detail_pengunjung/
│   │   └─ detail_pengunjung_screen.dart
│   ├─ denah_tenda/
│   │   ├─ denah_tenda_screen.dart
│   │   ├─ widgets/
│   │   │   ├─ vip_section.dart
│   │   │   ├─ reguler_section.dart
│   │   │   └─ citylight_section.dart
│   └─ scan_qr/
│       └─ scan_qr_screen.dart
│
├─ services/
│   └─ sync_service.dart             # HTTP POST ke Apps Script
│
└─ utils/
    ├─ csv_generator.dart
    └─ qr_share_helper.dart
```

---

## 13. Yang Tidak Dibangun di v1

Lihat PRD bagian "Non-Goals". Prioritas utama: fitur inti berjalan solid dan dipakai operasional nyata, sebelum tambah fitur baru.
