class Pengunjung {
  int? id;
  String nama;
  String alamat;
  String jenisTenda;
  String status;
  String tanggalMasuk;
  // --- TAMBAHAN BARU SESUAI DESAIN & BUKU MANUAL ---
  String tanggalMulai;
  String tanggalSelesai;
  int jumlahPengunjung;
  String jenisPesanan;
  String keterangan;

  Pengunjung({
    this.id,
    required this.nama,
    required this.alamat,
    required this.jenisTenda,
    this.status = "Aktif",
    required this.tanggalMasuk,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.jumlahPengunjung,
    required this.jenisPesanan,
    required this.keterangan,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'alamat': alamat,
      'jenisTenda': jenisTenda,
      'status': status,
      'tanggalMasuk': tanggalMasuk,
      'tanggalMulai': tanggalMulai,
      'tanggalSelesai': tanggalSelesai,
      'jumlahPengunjung': jumlahPengunjung,
      'jenisPesanan': jenisPesanan,
      'keterangan': keterangan,
    };
  }

  factory Pengunjung.fromMap(Map<String, dynamic> map) {
    return Pengunjung(
      id: map['id'],
      nama: map['nama'],
      alamat: map['alamat'],
      jenisTenda: map['jenisTenda'],
      status: map['status'],
      tanggalMasuk: map['tanggalMasuk'],
      tanggalMulai: map['tanggalMulai'],
      tanggalSelesai: map['tanggalSelesai'],
      jumlahPengunjung: map['jumlahPengunjung'],
      jenisPesanan: map['jenisPesanan'],
      keterangan: map['keterangan'],
    );
  }
}