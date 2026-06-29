// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'data/database/database_helper.dart';
import 'providers/pengunjung_provider.dart';

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
}
