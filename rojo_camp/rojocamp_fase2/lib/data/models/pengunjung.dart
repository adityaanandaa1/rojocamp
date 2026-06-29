// lib/data/models/pengunjung.dart

class Pengunjung {
  final String id;              // UUID — juga isi QR code
  final String nama;
  final String alamat;
  final String tanggalMulai;    // Format: YYYY-MM-DD
  final String tanggalSelesai;  // Format: YYYY-MM-DD (exclusive — malam terakhir = tgl_selesai - 1 hari)
  final int jumlahPengunjung;
  final String jenisPesanan;    // 'RESERVASI' | 'ONSITE'
  final String? keterangan;
  final String status;          // 'AKTIF' | 'NON_AKTIF'
  final String? waktuCheckout;
  final String createdAt;
  final int synced;             // 0 = belum sync, 1 = sudah sync ke Sheets

  // Slot terpilih — di-load dari tabel pengunjung_slot, TIDAK disimpan di tabel pengunjung
  final List<String> slotIds;

  const Pengunjung({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.jumlahPengunjung,
    required this.jenisPesanan,
    this.keterangan,
    this.status = 'AKTIF',
    this.waktuCheckout,
    required this.createdAt,
    this.synced = 0,
    this.slotIds = const [],
  });

  Pengunjung copyWith({
    String? status,
    String? waktuCheckout,
    int? synced,
    List<String>? slotIds,
  }) {
    return Pengunjung(
      id: id,
      nama: nama,
      alamat: alamat,
      tanggalMulai: tanggalMulai,
      tanggalSelesai: tanggalSelesai,
      jumlahPengunjung: jumlahPengunjung,
      jenisPesanan: jenisPesanan,
      keterangan: keterangan,
      status: status ?? this.status,
      waktuCheckout: waktuCheckout ?? this.waktuCheckout,
      createdAt: createdAt,
      synced: synced ?? this.synced,
      slotIds: slotIds ?? this.slotIds,
    );
  }

  // Hanya kolom tabel pengunjung — slotIds tidak masuk ke sini
  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'alamat': alamat,
        'tanggal_mulai': tanggalMulai,
        'tanggal_selesai': tanggalSelesai,
        'jumlah_pengunjung': jumlahPengunjung,
        'jenis_pesanan': jenisPesanan,
        'keterangan': keterangan,
        'status': status,
        'waktu_checkout': waktuCheckout,
        'created_at': createdAt,
        'synced': synced,
      };

  factory Pengunjung.fromMap(Map<String, dynamic> map, {List<String>? slotIds}) {
    return Pengunjung(
      id: map['id'] as String,
      nama: map['nama'] as String,
      alamat: map['alamat'] as String,
      tanggalMulai: map['tanggal_mulai'] as String,
      tanggalSelesai: map['tanggal_selesai'] as String,
      jumlahPengunjung: map['jumlah_pengunjung'] as int,
      jenisPesanan: map['jenis_pesanan'] as String,
      keterangan: map['keterangan'] as String?,
      status: map['status'] as String,
      waktuCheckout: map['waktu_checkout'] as String?,
      createdAt: map['created_at'] as String,
      synced: map['synced'] as int,
      slotIds: slotIds ?? [],
    );
  }
}
