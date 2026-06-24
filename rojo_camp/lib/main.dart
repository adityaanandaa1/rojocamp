import 'package:flutter/material.dart';
import 'home_page.dart';
import 'add_visitor_page.dart';
import 'users_page.dart'; // Import halaman Add Visitor-nya
// import 'users_page.dart'; // Nanti kita aktifkan saat halaman All User dibuat

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kebun Rojo Camp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        primaryColor: const Color(0xFF2563EB),
        fontFamily: 'Poppins', 
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

@override
  void initState() {
    super.initState();
    _pages = [
      HomePage(key: UniqueKey()), 
      AddVisitorPage(onSave: () {
        setState(() { _selectedIndex = 0; }); 
      }),
      // --- GANTI BARIS KETIGA MENJADI INI ---
      UsersPage(key: UniqueKey()),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Refresh halaman Home atau Users saat diklik
      if (index == 0) _pages[0] = HomePage(key: UniqueKey());
      if (index == 2) _pages[2] = UsersPage(key: UniqueKey());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      // Membuat Bottom Navigation dengan Tombol + di tengah
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onItemTapped(1), // Arahkan ke halaman Add (index 1)
        backgroundColor: const Color(0xFF2563EB),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.home_filled, color: _selectedIndex == 0 ? const Color(0xFF2563EB) : Colors.grey),
                onPressed: () => _onItemTapped(0),
              ),
              const SizedBox(width: 40), // Spasi untuk tombol tengah
              IconButton(
                icon: Icon(Icons.people_alt, color: _selectedIndex == 2 ? const Color(0xFF2563EB) : Colors.grey),
                onPressed: () => _onItemTapped(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}