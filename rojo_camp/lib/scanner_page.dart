import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'database_helper.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    // Mencegah scan berulang kali saat kamera sedang memproses
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final String code = barcode.rawValue!;
        
        // Memastikan yang di-scan benar-benar tiket Rojo Camp (Format: RC-ID-NAMA-TENDA)
        if (code.startsWith('RC-')) {
          setState(() => _isProcessing = true);
          
          try {
            List<String> parts = code.split('-');
            if (parts.length >= 2) {
              int id = int.parse(parts[1]); // Mengambil angka ID dari QR Code
              
              // Ubah status di database SQLite
              await DatabaseHelper.instance.checkoutPengunjung(id);
              
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Berhasil Checkout! Kapasitas tenda dikosongkan."),
                  backgroundColor: Colors.green,
                ),
              );
              
              // Tutup halaman kamera, kembali ke Home
              Navigator.pop(context, true); 
              return;
            }
          } catch (e) {
            // Jika gagal membedah teks
          }
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Tiket Checkout", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
          // Membuat efek frame kotak di tengah layar
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Text(
              "Arahkan ke QR Code Pengunjung",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}