// lib/screens/scan_qr/scan_qr_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../data/database/seed_data.dart';
import '../../data/models/pengunjung.dart';
import '../../data/repositories/pengunjung_repository.dart';
import '../../providers/pengunjung_provider.dart';

// ── Entry point ─────────────────────────────────────────────────

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

// WidgetsBindingObserver agar kamera otomatis pause saat app background
// dan resume saat kembali ke foreground — tanpa ini kamera terus aktif.
class _ScanQrScreenState extends State<ScanQrScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;

  // Flag agar scan tidak diproses dua kali berturut-turut
  bool _isProcessing = false;

  static final Map<String, String> _slotLabels = {
    for (final s in kSemuaSlot) s.id: s.labelDisplay,
  };

  // ── Lifecycle ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _controller.stop();
      case AppLifecycleState.resumed:
        if (!_isProcessing) _controller.start();
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  // ── Scan detection ─────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    _isProcessing = true;

    // Getaran singkat sebagai feedback bahwa QR berhasil terdeteksi
    HapticFeedback.mediumImpact();

    // Jalankan processing secara async, tangkap error di sini
    _processQr(rawValue).catchError((e) {
      debugPrint('[ScanQR] Error: $e');
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  Future<void> _processQr(String rawValue) async {
    // Hentikan kamera selama proses
    await _controller.stop();

    _ScanResult result;

    // Validasi format UUID — QR dari app ini selalu UUID v4
    if (!_isValidUuid(rawValue)) {
      result = _ScanResult.invalidQr(rawValue);
    } else {
      // Cari di database
      final pengunjung = await PengunjungRepository().getById(rawValue);

      if (pengunjung == null) {
        result = _ScanResult.notFound();
      } else if (pengunjung.status == 'NON_AKTIF') {
        result = _ScanResult.alreadyCheckedOut(pengunjung);
      } else {
        // AKTIF — lakukan checkout via provider agar list ter-update
        if (mounted) {
          await context.read<PengunjungProvider>().checkout(pengunjung.id);
        }
        // Ambil data terbaru setelah checkout
        final updated = await PengunjungRepository().getById(rawValue);
        result = _ScanResult.success(updated ?? pengunjung);
      }
    }

    if (!mounted) return;

    // Tampilkan hasil — user pilih "Scan Lagi" atau "Selesai"
    final scanAgain = await _showResultSheet(result);

    if (!mounted) return;

    if (scanAgain) {
      setState(() => _isProcessing = false);
      await _controller.start();
    } else {
      Navigator.pop(context);
    }
  }

  /// UUID v4 regex — QR dari app ini selalu UUID v4
  bool _isValidUuid(String value) {
    final re = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return re.hasMatch(value);
  }

  /// Tampilkan bottom sheet hasil scan.
  /// Return true jika user pilih "Scan Lagi", false jika "Selesai".
  Future<bool> _showResultSheet(_ScanResult result) async {
    final scanAgain = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,   // user harus pilih salah satu tombol
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResultSheet(
        result: result,
        slotLabels: _slotLabels,
      ),
    );
    return scanAgain ?? false;
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan QR Checkout',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Tombol flashlight
          ValueListenableBuilder(
            valueListenable: _controller.torchState,
            builder: (_, state, __) {
              final isOn = state == TorchState.on;
              return IconButton(
                icon: Icon(
                  isOn ? Icons.flash_on : Icons.flash_off,
                  color: isOn ? Colors.yellow : Colors.white,
                ),
                tooltip: isOn ? 'Matikan Flash' : 'Nyalakan Flash',
                onPressed: () => _controller.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Kamera full screen
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (ctx, err, child) => _CameraError(error: err),
          ),

          // Overlay gelap dengan lubang transparan di tengah
          CustomPaint(
            size: Size.infinite,
            painter: _ScanOverlayPainter(),
          ),

          // Instruksi di atas area scan
          const Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Arahkan kamera ke QR Code pengunjung',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(blurRadius: 8, color: Colors.black),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading indicator saat sedang proses
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF0088FF)),
                    SizedBox(height: 16),
                    Text(
                      'Memproses...',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Scan Overlay ────────────────────────────────────────────────

/// Custom painter yang menggambar:
/// 1. Background gelap semi-transparan
/// 2. Lubang transparan persegi di tengah (area scan)
/// 3. Penanda sudut berwarna biru di keempat pojok
class _ScanOverlayPainter extends CustomPainter {
  static const _scanAreaRatio = 0.65; // ukuran area scan relatif terhadap lebar layar
  static const _cornerLength = 24.0;
  static const _cornerWidth = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final scanSize = size.width * _scanAreaRatio;
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 40),
      width: scanSize,
      height: scanSize,
    );

    // Background gelap dengan lubang (Path difference)
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(
            scanRect, const Radius.circular(14))),
      ),
      Paint()..color = Colors.black.withOpacity(0.62),
    );

    // Penanda sudut biru
    final cornerPaint = Paint()
      ..color = const Color(0xFF0088FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cornerWidth
      ..strokeCap = StrokeCap.round;

    final l = scanRect.left;
    final t = scanRect.top;
    final r = scanRect.right;
    final b = scanRect.bottom;

    // Sudut kiri atas
    canvas.drawLine(Offset(l, t + _cornerLength), Offset(l, t), cornerPaint);
    canvas.drawLine(Offset(l, t), Offset(l + _cornerLength, t), cornerPaint);
    // Sudut kanan atas
    canvas.drawLine(Offset(r - _cornerLength, t), Offset(r, t), cornerPaint);
    canvas.drawLine(Offset(r, t), Offset(r, t + _cornerLength), cornerPaint);
    // Sudut kiri bawah
    canvas.drawLine(Offset(l, b - _cornerLength), Offset(l, b), cornerPaint);
    canvas.drawLine(Offset(l, b), Offset(l + _cornerLength, b), cornerPaint);
    // Sudut kanan bawah
    canvas.drawLine(Offset(r - _cornerLength, b), Offset(r, b), cornerPaint);
    canvas.drawLine(Offset(r, b), Offset(r, b - _cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Scan Result ─────────────────────────────────────────────────

enum _ScanResultType { success, alreadyCheckedOut, notFound, invalidQr }

class _ScanResult {
  final _ScanResultType type;
  final Pengunjung? pengunjung;
  final String? rawValue; // untuk debug jika invalidQr

  const _ScanResult._({
    required this.type,
    this.pengunjung,
    this.rawValue,
  });

  factory _ScanResult.success(Pengunjung p) =>
      _ScanResult._(type: _ScanResultType.success, pengunjung: p);

  factory _ScanResult.alreadyCheckedOut(Pengunjung p) =>
      _ScanResult._(type: _ScanResultType.alreadyCheckedOut, pengunjung: p);

  factory _ScanResult.notFound() =>
      const _ScanResult._(type: _ScanResultType.notFound);

  factory _ScanResult.invalidQr(String raw) =>
      _ScanResult._(type: _ScanResultType.invalidQr, rawValue: raw);
}

// ── Result Bottom Sheet ─────────────────────────────────────────

class _ResultSheet extends StatelessWidget {
  final _ScanResult result;
  final Map<String, String> slotLabels;

  const _ResultSheet({required this.result, required this.slotLabels});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Icon + judul
          _buildHeader(),
          const SizedBox(height: 16),

          // Konten spesifik per result type
          _buildContent(),
          const SizedBox(height: 28),

          // Tombol aksi
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    late IconData icon;
    late Color iconBg;
    late Color iconColor;
    late String title;

    switch (result.type) {
      case _ScanResultType.success:
        icon = Icons.check_circle_outline;
        iconBg = Colors.green.shade50;
        iconColor = const Color(0xFF22C55E);
        title = 'Checkout Berhasil';
      case _ScanResultType.alreadyCheckedOut:
        icon = Icons.info_outline;
        iconBg = Colors.orange.shade50;
        iconColor = Colors.orange.shade700;
        title = 'Sudah Checkout';
      case _ScanResultType.notFound:
        icon = Icons.search_off;
        iconBg = Colors.red.shade50;
        iconColor = Colors.red.shade600;
        title = 'Pengunjung Tidak Ditemukan';
      case _ScanResultType.invalidQr:
        icon = Icons.qr_code_scanner;
        iconBg = Colors.red.shade50;
        iconColor = Colors.red.shade600;
        title = 'QR Tidak Valid';
    }

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 36),
        ),
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildContent() {
    switch (result.type) {
      case _ScanResultType.success:
        return _buildSuccessContent();
      case _ScanResultType.alreadyCheckedOut:
        return _buildAlreadyCheckedOutContent();
      case _ScanResultType.notFound:
        return _buildSimpleMessage(
          'Data pengunjung dengan QR ini tidak ada\ndi database aplikasi.',
        );
      case _ScanResultType.invalidQr:
        return _buildSimpleMessage(
          'Format QR tidak dikenali.\nPastikan QR berasal dari aplikasi Kebun Rojo Camp.',
        );
    }
  }

  Widget _buildSuccessContent() {
    final p = result.pengunjung!;
    final slots = p.slotIds
        .map((id) => slotLabels[id] ?? id)
        .join(', ');
    final checkoutTime = p.waktuCheckout != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(p.waktuCheckout!))
        : DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Nama', p.nama),
          const SizedBox(height: 6),
          _infoRow('Tenda', slots.isEmpty ? '-' : slots),
          const SizedBox(height: 6),
          _infoRow('Checkout', checkoutTime),
        ],
      ),
    );
  }

  Widget _buildAlreadyCheckedOutContent() {
    final p = result.pengunjung!;
    final time = p.waktuCheckout != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(p.waktuCheckout!))
        : '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Nama', p.nama),
          const SizedBox(height: 6),
          _infoRow('Checkout sebelumnya', time),
          const SizedBox(height: 8),
          Text(
            'Rombongan ini sudah pernah checkout sebelumnya.\nTidak ada perubahan data.',
            style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMessage(String message) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ),
        const Text(': ',
            style: TextStyle(fontSize: 13, color: Colors.grey)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, true), // Scan Lagi
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            label: const Text('Scan Lagi'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, false), // Selesai
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Selesai',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Camera Error ────────────────────────────────────────────────

/// Ditampilkan jika kamera tidak bisa diakses (permission ditolak, dll).
class _CameraError extends StatelessWidget {
  final MobileScannerException error;

  const _CameraError({required this.error});

  @override
  Widget build(BuildContext context) {
    String message;
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        message = 'Izin kamera ditolak.\n\n'
            'Buka Pengaturan > Aplikasi > Rojo Camp\n'
            'dan aktifkan izin Kamera.';
      case MobileScannerErrorCode.unsupported:
        message = 'Perangkat tidak mendukung\nfitur scan kamera.';
      default:
        message = 'Kamera tidak bisa diakses.\n(${error.errorCode})';
    }

    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined,
                  color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
