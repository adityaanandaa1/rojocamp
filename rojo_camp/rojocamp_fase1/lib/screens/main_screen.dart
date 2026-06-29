// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'daftar_pengunjung/daftar_pengunjung_screen.dart';
import 'tambah_pengunjung/tambah_pengunjung_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // IndexedStack: pages tetap hidup di memory, tidak di-rebuild tiap nav berubah.
  // Lebih efisien dari membangun ulang dengan UniqueKey().
  static const List<Widget> _pages = [
    HomeScreen(),
    DaftarPengunjungScreen(),
  ];

  void _openTambah() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true, // muncul dari bawah, ada X di AppBar
        builder: (_) => const TambahPengunjungScreen(),
      ),
    );
    // Provider notifyListeners() otomatis terpanggil setelah insert,
    // sehingga DaftarPengunjung refresh sendiri tanpa perlu callback manual.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openTambah,
        backgroundColor: const Color(0xFF0088FF),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Beranda',
                index: 0,
                selectedIndex: _selectedIndex,
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              const SizedBox(width: 80), // ruang untuk FAB
              _NavItem(
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: 'Pengunjung',
                index: 1,
                selectedIndex: _selectedIndex,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selectedIndex == index;
    const activeColor = Color(0xFF0088FF);
    final inactiveColor = Colors.grey.shade500;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? activeColor : inactiveColor,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
