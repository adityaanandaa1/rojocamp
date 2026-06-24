import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';
import 'scanner_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Variabel penampung hasil hitungan (Versi Baru)
  int totalTenda = 0;
  int tendaVIP = 0;
  int tendaCitylight = 0;
  int tendaReguler = 0;

  @override
  void initState() {
    super.initState();
    _hitungStatistik(); // Jalankan fungsi hitung saat halaman dibuka
  }

  // Fungsi untuk menghitung otomatis dari database
  void _hitungStatistik() async {
    final total = await DatabaseHelper.instance.countTotal();
    final vip = await DatabaseHelper.instance.countVIP();
    final citylight = await DatabaseHelper.instance.countCitylight();
    final reguler = await DatabaseHelper.instance.countReguler();

    setState(() {
      totalTenda = total;
      tendaVIP = vip;
      tendaCitylight = citylight;
      tendaReguler = reguler;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> namaBulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    DateTime sekarang = DateTime.now();
    String tanggalHariIni = "${sekarang.day} ${namaBulan[sekarang.month - 1]} ${sekarang.year}";

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // Judul + Tombol Kamera
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Kebun Rojo Camp",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner, size: 30, color: Color(0xFF2563EB)),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const ScannerPage())
                    );
                    if (result == true) {
                      _hitungStatistik();
                    }
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            // Tombol Tanggal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(tanggalHariIni, style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4), 
                  const Icon(Icons.keyboard_arrow_down, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Grid Kotak Statistik (Versi Baru)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard("Total Tenda", totalTenda.toString(), Icons.storefront),
                _buildStatCard("VIP & Mini", tendaVIP.toString(), Icons.campaign),
                _buildStatCard("Citylight", tendaCitylight.toString(), Icons.holiday_village),
                _buildStatCard("Reguler A-J", tendaReguler.toString(), Icons.gite),
              ],
            ),
            const SizedBox(height: 40),

            // Bagian Grafik Statistik Pengunjung
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Statistik Pengunjung",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  totalTenda == 0 
                  ? const Center(child: Text("Belum ada data pengunjung", style: TextStyle(color: Colors.grey)))
                  : SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 60,
                        sections: [
                          PieChartSectionData(
                            color: const Color(0xFF3B82F6),
                            value: tendaReguler.toDouble(),
                            title: '',
                            radius: 25,
                          ),
                          PieChartSectionData(
                            color: const Color(0xFFFBBF24),
                            value: tendaCitylight.toDouble(),
                            title: '',
                            radius: 25,
                          ),
                          PieChartSectionData(
                            color: const Color(0xFFF97316),
                            value: tendaVIP.toDouble(),
                            title: '',
                            radius: 25,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Legend (Versi Baru)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend(const Color(0xFF3B82F6), "Reguler"),
                      const SizedBox(width: 16),
                      _buildLegend(const Color(0xFFFBBF24), "Citylight"),
                      const SizedBox(width: 16),
                      _buildLegend(const Color(0xFFF97316), "VIP"),
                    ],
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

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.black87),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}