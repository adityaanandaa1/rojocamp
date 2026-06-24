import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'pengunjung.dart';
import 'detail_page.dart'; // Menyambungkan ke halaman QR Code

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<Pengunjung> _listPengunjung = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData(); // Tarik data dari SQLite saat halaman dibuka
  }

  void _loadData() async {
    final data = await DatabaseHelper.instance.getAllPengunjung();
    setState(() {
      _listPengunjung = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Pengunjung", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _listPengunjung.isEmpty 
          ? const Center(child: Text("Belum ada pengunjung terdaftar.", style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _listPengunjung.length,
              separatorBuilder: (context, index) => const Divider(height: 30),
              itemBuilder: (context, index) {
                final user = _listPengunjung[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    user.nama, 
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
                  ),
                  subtitle: Text("Tenda ${user.jenisTenda} • ${user.tanggalMasuk}"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E), // Warna hijau persis desainmu
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.status,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  onTap: () {
                    // Berpindah ke Halaman Detail & QR Code
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailPage(pengunjung: user),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}