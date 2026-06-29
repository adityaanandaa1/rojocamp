# Product Requirements Document (PRD)
**Proyek:** Aplikasi Pencatatan Pengunjung — Kebun Rojo Camp
**Versi:** 2.0 (Flutter, full features)
**Tanggal:** 21 Juni 2026
**Platform:** Flutter Android (local-first, backup ke Google Sheets)

---

## Changelog dari v1.x
- Platform berubah dari Kotlin ke Flutter — seluruh tech stack diperbarui.
- Ditambahkan fitur Denah Tenda: pemilihan slot tenda spesifik secara visual dengan deteksi konflik tanggal.
- Satu rombongan dapat memilih banyak slot sekaligus dari kategori yang berbeda (multi-slot, many-to-many).
- Status disederhanakan: AKTIF → NON_AKTIF (scan QR saat pengunjung pulang).
- 3 kategori tenda: VIP, Reguler, Citylight, masing-masing dengan slot bernama spesifik.

---

## 1. Latar Belakang

Kebun Rojo Camp adalah tempat wisata camping ground yang sudah beroperasi. Saat ini pencatatan pengunjung masih manual (buku tulis). Aplikasi ini menggantikan proses tersebut dengan solusi digital lokal yang bisa digunakan offline, dengan backup otomatis ke cloud saat ada koneksi internet.

## 2. Problem Statement

Admin Kebun Rojo Camp membutuhkan cara yang lebih cepat untuk:
- Mencatat data rombongan pengunjung (reservasi maupun walk-in/onsite).
- Mengetahui slot tenda mana yang sudah terpakai di tanggal tertentu secara visual.
- Memverifikasi kepulangan pengunjung via scan QR.
- Melihat statistik kunjungan dan mengunduh laporannya.
- Semua ini tanpa bergantung koneksi internet di lokasi.

## 3. Tujuan (Goals)

1. Menggantikan pencatatan manual (buku tulis) dengan aplikasi Flutter Android untuk 1 admin.
2. Menyediakan Denah Tenda interaktif untuk memilih slot spesifik dengan deteksi konflik otomatis.
3. Mendukung pemilihan multi-slot (satu rombongan bisa pesan VIP + Reguler + Citylight sekaligus).
4. Mendukung 2 jenis pesanan: Reservasi (booking via WA duluan) dan Onsite (datang langsung).
5. Verifikasi kepulangan rombongan via scan QR — status berubah dari AKTIF ke NON_AKTIF.
6. Menyediakan statistik kunjungan dengan filter tanggal dan fitur unduh laporan (CSV/Excel).
7. Backup data ke Google Sheets saat ada koneksi internet.
8. Biaya pengembangan dan operasional Rp0.
9. Proyek portofolio mahasiswa.

## 4. Non-Goals (Di Luar Cakupan v1)

- Pembayaran di dalam aplikasi (tetap via WhatsApp).
- Aplikasi untuk pengunjung (pengunjung hanya terima QR via WhatsApp).
- Multi-admin / multi-device real-time sync.
- Publikasi ke Play Store (distribusi via APK sideload).
- Login/autentikasi kompleks.
- Manajemen slot tenda dari dalam app (slot bersifat hardcoded/statis di v1).
- Auto-cancel no-show (pembatalan tetap manual oleh admin).

## 5. Dua Jenis Pesanan

### Jenis 1 — Reservasi
Pengunjung menghubungi admin via WhatsApp, booking + bayar di muka. Admin input data ke app sebelum pengunjung datang. Status langsung AKTIF saat disimpan. QR dikirim ke pengunjung via WhatsApp. Saat pengunjung pulang, admin scan QR → status NON_AKTIF.

### Jenis 2 — Onsite (Walk-in)
Pengunjung datang langsung. Admin input data saat itu juga. Status langsung AKTIF. QR bisa langsung ditunjukkan di layar atau dikirim ke pengunjung. Alur checkout sama: scan QR → NON_AKTIF.

## 6. Kategori dan Struktur Slot Tenda

### VIP (6 slot)
VIP1, VIP2, VIP3, VIP4, VIP5, Mini Ground

### Reguler (10 slot, berlabel huruf A–J)
A, B, C, D, E, F, G, H, I, J

### Citylight (31 slot, berlabel Ground [nomor][huruf])
| Ground | Slot |
|--------|------|
| Ground 1 | A, B, C |
| Ground 2 | A, B, C |
| Ground 3 | A, B, C, D, E, F |
| Ground 4 | A, B, C, D, E, F |
| Ground 5 | G, H, I, J |
| Ground 6 | A, B, C |
| Ground 7 | A, B |
| Ground 8 | A, B |
| Ground 9 | A, B |

**Total slot: 47 unit** (6 VIP + 10 Reguler + 31 Citylight)
> Catatan: angka pada mockup (74, 50, dll) adalah placeholder desain, bukan angka real.

## 7. Fitur Denah Tenda

- Ditampilkan sebagai halaman full-screen saat admin menekan field "Jenis" di form Tambah Pengunjung.
- Menampilkan 3 section: VIP (atas), Reguler (tengah, grid huruf A–J), Citylight (bawah, per Ground 1–9).
- Setiap slot punya 3 state visual:
  - **Putih/default** = tersedia di rentang tanggal yang dipilih
  - **Biru (#0088FF)** = sedang dipilih oleh admin sekarang (bisa multi-select)
  - **Abu-abu (#7A7979)** = sudah dipesan rombongan lain di tanggal yang overlap
- Slot abu-abu tidak bisa dipilih.
- Setelah selesai, tekan tombol "Pilih" → kembali ke form Tambah Pengunjung.
- Field "Jenis" di form menampilkan semua slot yang dipilih (satu baris per slot), contoh:
  ```
  VIP 2
  Reguler A
  Citylight 4C
  ```
- Denah hanya bisa dibuka setelah admin mengisi Tanggal Mulai dan Tanggal Selesai terlebih dahulu (karena deteksi konflik butuh rentang tanggal).

## 8. Status Pengunjung

| Status | Tampilan | Kapan |
|--------|----------|-------|
| AKTIF | Label hijau | Saat record pertama dibuat (reservasi maupun onsite) |
| NON_AKTIF | Label merah | Setelah QR rombongan di-scan oleh admin |

## 9. User Stories

| # | Sebagai admin... | Supaya... |
|---|---|---|
| US-1 | mencatat reservasi baru dengan slot tenda spesifik | ada data sebelum pengunjung datang |
| US-2 | mencatat onsite langsung saat pengunjung tiba | data tercatat real-time |
| US-3 | melihat Denah Tenda dan tahu slot mana yang masih kosong di tanggal tertentu | tidak terjadi double-booking |
| US-4 | memilih banyak slot sekaligus untuk satu rombongan | rombongan besar bisa pesan beberapa slot beda kategori |
| US-5 | mendapat QR unik per rombongan | bisa dikirim sebagai e-ticket dan dipakai saat checkout |
| US-6 | scan QR saat rombongan pulang | status otomatis berubah, slot terbuka lagi untuk tanggal berikutnya |
| US-7 | melihat daftar semua pengunjung dengan status | tahu siapa yang masih aktif |
| US-8 | melihat detail lengkap pengunjung termasuk slot yang dipilih | verifikasi data saat dibutuhkan |
| US-9 | melihat statistik kunjungan (jumlah tenda terpakai per kategori, donut chart) dengan filter tanggal | evaluasi operasional |
| US-10 | mengunduh laporan data pengunjung (CSV/Excel) dengan filter rentang tanggal | pelaporan tanpa buka laptop |
| US-11 | membatalkan pesanan secara manual | slot tidak terkunci kalau ada no-show |
| US-12 | data ter-backup ke cloud saat ada internet | data tidak hilang kalau HP rusak/hilang |
| US-13 | semua fungsi tetap berjalan tanpa internet | operasional tidak terganggu sinyal lemah di lokasi |

## 10. Functional Requirements

- FR-1: Form tambah pengunjung: nama, jenis slot (via Denah Tenda), alamat, tanggal mulai & selesai, jumlah pengunjung, jenis pesanan (Reservasi/Onsite), keterangan (opsional).
- FR-2: Denah Tenda menampilkan status slot (tersedia/dipilih/abu-abu) secara real-time berdasarkan rentang tanggal yang diinput di form.
- FR-3: Satu rombongan dapat memilih banyak slot dari kategori berbeda (multi-slot).
- FR-4: Aplikasi mencegah pemilihan slot yang sudah dipesan rombongan lain di tanggal yang overlap.
- FR-5: Generate QR code unik per rombongan, ditampilkan di halaman Detail Pengunjung.
- FR-6: QR bisa di-share sebagai gambar (via WhatsApp intent Android).
- FR-7: Scan QR → lookup rombongan → update status ke NON_AKTIF.
- FR-8: Daftar Pengunjung menampilkan nama dan status (Aktif/Non-Aktif), bisa difilter.
- FR-9: Detail Pengunjung menampilkan semua data termasuk slot yang dipilih (format per baris).
- FR-10: Home screen menampilkan jumlah slot terpakai per kategori dan donut chart pengunjung, di-filter berdasarkan tanggal yang dipilih.
- FR-11: Fitur unduh laporan (CSV) dengan filter rentang tanggal.
- FR-12: Sinkronisasi backup ke Google Sheets saat ada koneksi internet (manual trigger / otomatis saat buka app online).
- FR-13: Pembatalan pesanan manual oleh admin (mereset slot yang dipilih kembali ke tersedia).
- FR-14: Semua fungsi inti (CRUD, Denah, QR, scan) berjalan offline.

## 11. Non-Functional Requirements

- NFR-1 (Biaya): Rp0 untuk semua tools dan operasional.
- NFR-2 (Offline-first): Tidak ada fungsi inti yang gagal akibat tidak ada sinyal.
- NFR-3 (Reliabilitas data): Data tidak hilang jika sync terakhir berhasil dilakukan sebelum HP rusak.
- NFR-4 (Kemudahan pakai): UI sederhana, bisa dioperasikan admin tanpa pelatihan teknis.
- NFR-5 (Maintainability): Kode terstruktur untuk keperluan portofolio.

## 12. Roadmap Fase (Ringkasan)

| Fase | Cakupan | Deliverable |
|------|---------|-------------|
| 1 | Setup Flutter + database 3 tabel + CRUD pengunjung dasar | App jalan, data bisa masuk |
| 2 | Denah Tenda (UI + conflict detection + multi-slot) | Pemilihan slot berfungsi |
| 3 | Generate QR + Detail Pengunjung | QR bisa ditampilkan & dibagikan |
| 4 | Scan QR + update status | Checkout via kamera |
| 5 | Home screen (statistik, chart, filter tanggal, unduh CSV) | Dashboard berfungsi |
| 6 | Sinkronisasi Google Sheets | Backup cloud aktif |

Detail teknis tiap fase ada di `design.md` dan `ROADMAP.md`.
