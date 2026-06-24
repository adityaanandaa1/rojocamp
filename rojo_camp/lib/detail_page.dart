import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'pengunjung.dart';

class DetailPage extends StatelessWidget {
  final Pengunjung pengunjung;

  const DetailPage({super.key, required this.pengunjung});

  @override
  Widget build(BuildContext context) {
    String qrData = "RC-${pengunjung.id}-${pengunjung.nama.toUpperCase()}-${pengunjung.jenisTenda.toUpperCase()}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Pengunjung", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField("Nama Pengunjung", pengunjung.nama),
            const SizedBox(height: 16),
            _buildField("Jenis Tenda", "Tenda ${pengunjung.jenisTenda}"),
            const SizedBox(height: 16),
            _buildField("Alamat", pengunjung.alamat),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _buildField("Tanggal Mulai", pengunjung.tanggalMulai)),
                const SizedBox(width: 16),
                Expanded(child: _buildField("Tanggal Selesai", pengunjung.tanggalSelesai)),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildField("Jumlah Pengunjung", "${pengunjung.jumlahPengunjung} Orang"),
            const SizedBox(height: 16),
            _buildField("Jenis Pesanan", pengunjung.jenisPesanan),
            const SizedBox(height: 16),
            _buildField("Keterangan", pengunjung.keterangan),
            const SizedBox(height: 40),

            // AREA GENERATOR QR CODE
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    qrData,
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}