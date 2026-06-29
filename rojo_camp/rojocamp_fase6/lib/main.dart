// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/database/database_helper.dart';
import 'providers/pengunjung_provider.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi DB + seed slot master saat pertama install
  await DatabaseHelper.instance.database;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PengunjungProvider()..loadAll(),
        ),
      ],
      child: const RojoCampApp(),
    ),
  );

  // Auto-sync setelah frame pertama selesai render.
  // Delay 2 detik agar tidak memperlambat startup.
  // Gagal secara silent — operasional harian tidak terganggu.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(seconds: 2), () {
      SyncService.syncAll().then((result) {
        if (result.synced > 0) {
          debugPrint('[AutoSync] ${result.synced} records synced.');
        }
      }).catchError((e) {
        debugPrint('[AutoSync] Skipped: $e');
      });
    });
  });
}
