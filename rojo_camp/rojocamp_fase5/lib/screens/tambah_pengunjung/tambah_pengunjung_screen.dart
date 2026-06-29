// lib/screens/tambah_pengunjung/tambah_pengunjung_screen.dart
// Phase 2: field "Jenis Tenda" sekarang membuka DenahTendaScreen (visual denah)
// menggantikan _SlotPickerSheet (bottom sheet checklist dari Phase 1).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/seed_data.dart';
import '../../data/models/pengunjung.dart';
import '../../providers/pengunjung_provider.dart';
import '../denah_tenda/denah_tenda_screen.dart';

class TambahPengunjungScreen extends StatefulWidget {
  const TambahPengunjungScreen({super.key});

  @override
  State<TambahPengunjungScreen> createState() =>
      _TambahPengunjungScreenState();
}

class _TambahPengunjungScreenState extends State<TambahPengunjungScreen> {
  final _namaCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _jumlahCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();

  final Set<String> _selectedSlotIds = {};

  String _jenisPesanan = 'RESERVASI';
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  bool _isSaving = false;

  static const _uuid = Uuid();
  static final _fmt = DateFormat('yyyy-MM-dd');

  // Cache label untuk field display — gunakan kSemuaSlot (data statis)
  static final Map<String, String> _labelCache = {
    for (final s in kSemuaSlot) s.id: s.labelDisplay,
  };

  @override
  void dispose() {
    _namaCtrl.dispose();
    _alamatCtrl.dispose();
    _jumlahCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  // ── Tanggal Picker ──────────────────────────────────────────

  Future<void> _pilihTanggal(bool isMulai) async {
    final initial = isMulai
        ? (_tanggalMulai ?? DateTime.now())
        : (_tanggalSelesai ??
            (_tanggalMulai?.add(const Duration(days: 1)) ??
                DateTime.now()));

    final firstDate = isMulai
        ? DateTime.now().subtract(const Duration(days: 365))
        : (_tanggalMulai?.add(const Duration(days: 1)) ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFF0088FF)),
        ),
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isMulai) {
        _tanggalMulai = picked;
        if (_tanggalSelesai != null &&
            !_tanggalSelesai!.isAfter(picked)) {
          _tanggalSelesai = null;
        }
        // Reset slot saat tanggal berubah karena conflict detection berbeda
        _selectedSlotIds.clear();
      } else {
        _tanggalSelesai = picked;
      }
    });
  }

  // ── Slot Picker (Denah Tenda) ───────────────────────────────

  Future<void> _pilihSlot() async {
    if (_tanggalMulai == null || _tanggalSelesai == null) {
      _showSnack('Isi tanggal mulai & selesai terlebih dahulu');
      return;
    }

    // Navigasi ke DenahTendaScreen dan tunggu hasilnya
    final result = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => DenahTendaScreen(
          tanggalMulai: _fmt.format(_tanggalMulai!),
          tanggalSelesai: _fmt.format(_tanggalSelesai!),
          initialSelected: Set.from(_selectedSlotIds),
        ),
      ),
    );

    // result == null jika user menekan X (batal pilih)
    if (result != null && mounted) {
      setState(() {
        _selectedSlotIds
          ..clear()
          ..addAll(result);
      });
    }
  }

  String _jenisLabel() {
    if (_selectedSlotIds.isEmpty) return 'Pilih lokasi tenda...';
    return _selectedSlotIds
        .map((id) => _labelCache[id] ?? id)
        .join('\n');
  }

  // ── Validasi & Simpan ───────────────────────────────────────

  bool get _isFormValid =>
      _namaCtrl.text.trim().isNotEmpty &&
      _alamatCtrl.text.trim().isNotEmpty &&
      _tanggalMulai != null &&
      _tanggalSelesai != null &&
      _jumlahCtrl.text.trim().isNotEmpty &&
      _selectedSlotIds.isNotEmpty;

  Future<void> _simpan() async {
    if (!_isFormValid) {
      _showSnack('Lengkapi semua field dan pilih minimal 1 slot tenda');
      return;
    }

    final jumlah = int.tryParse(_jumlahCtrl.text.trim());
    if (jumlah == null || jumlah < 1) {
      _showSnack('Jumlah pengunjung harus berupa angka positif');
      return;
    }

    setState(() => _isSaving = true);

    final pengunjung = Pengunjung(
      id: _uuid.v4(),
      nama: _namaCtrl.text.trim(),
      alamat: _alamatCtrl.text.trim(),
      tanggalMulai: _fmt.format(_tanggalMulai!),
      tanggalSelesai: _fmt.format(_tanggalSelesai!),
      jumlahPengunjung: jumlah,
      jenisPesanan: _jenisPesanan,
      keterangan: _keteranganCtrl.text.trim().isEmpty
          ? null
          : _keteranganCtrl.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );

    await context
        .read<PengunjungProvider>()
        .tambah(pengunjung, _selectedSlotIds.toList());

    if (!mounted) return;
    setState(() => _isSaving = false);

    _showSnack('Pengunjung berhasil ditambahkan ✓', isSuccess: true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.pop(context);
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess
            ? Colors.green.shade600
            : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Tambah Pengunjung'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Label('Nama Pengunjung'),
            TextField(
              controller: _namaCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  hintText: 'Nama penanggung jawab rombongan'),
            ),

            // ── Pilih Tenda (sekarang buka DenahTendaScreen) ──
            _Label('Jenis Tenda'),
            InkWell(
              onTap: _pilihSlot,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _jenisLabel(),
                        style: TextStyle(
                          color: _selectedSlotIds.isEmpty
                              ? Colors.grey.shade500
                              : Colors.black87,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.map_outlined,
                        color: Color(0xFF0088FF), size: 20),
                  ],
                ),
              ),
            ),
            if (_selectedSlotIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: Color(0xFF0088FF)),
                    const SizedBox(width: 4),
                    Text(
                      '${_selectedSlotIds.length} slot dipilih',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF0088FF)),
                    ),
                  ],
                ),
              ),

            _Label('Alamat'),
            TextField(
              controller: _alamatCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  hintText: 'Kota / Kabupaten asal'),
            ),

            _Label('Tanggal'),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Mulai',
                    date: _tanggalMulai,
                    onTap: () => _pilihTanggal(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'Selesai',
                    date: _tanggalSelesai,
                    onTap: () => _pilihTanggal(false),
                  ),
                ),
              ],
            ),
            if (_tanggalMulai != null && _tanggalSelesai == null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Pilih tanggal selesai untuk bisa pilih tenda',
                  style: TextStyle(
                      fontSize: 11, color: Colors.orange.shade700),
                ),
              ),

            _Label('Jumlah Pengunjung'),
            TextField(
              controller: _jumlahCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Contoh: 4'),
            ),

            _Label('Jenis Pesanan'),
            DropdownButtonFormField<String>(
              value: _jenisPesanan,
              decoration: const InputDecoration(),
              items: const [
                DropdownMenuItem(
                  value: 'RESERVASI',
                  child: Text('Reservasi (via WhatsApp)'),
                ),
                DropdownMenuItem(
                  value: 'ONSITE',
                  child: Text('Onsite (datang langsung)'),
                ),
              ],
              onChanged: (v) =>
                  setState(() => _jenisPesanan = v ?? 'RESERVASI'),
            ),

            _Label('Keterangan (opsional)'),
            TextField(
              controller: _keteranganCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Catatan tambahan...'),
            ),

            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _simpan,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Tambah Pengunjung'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87),
        ),
      );
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final display = date == null
        ? label
        : DateFormat('dd MMM yyyy').format(date!);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                display,
                style: TextStyle(
                  fontSize: 13,
                  color: date == null
                      ? Colors.grey.shade500
                      : Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.calendar_today,
                size: 15, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
