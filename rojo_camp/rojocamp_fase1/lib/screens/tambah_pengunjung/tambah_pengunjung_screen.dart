// lib/screens/tambah_pengunjung/tambah_pengunjung_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/pengunjung.dart';
import '../../data/models/slot_tenda.dart';
import '../../data/repositories/slot_repository.dart';
import '../../providers/pengunjung_provider.dart';

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
  List<SlotTenda> _semuaSlot = [];

  String _jenisPesanan = 'RESERVASI';
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  bool _isSaving = false;

  static const _uuid = Uuid();
  final _slotRepo = SlotRepository();

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _alamatCtrl.dispose();
    _jumlahCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    final slots = await _slotRepo.getAll();
    if (mounted) setState(() => _semuaSlot = slots);
  }

  // ── Tanggal Picker ──────────────────────────────────────────

  Future<void> _pilihTanggal(bool isMulai) async {
    final initialDate = isMulai
        ? (_tanggalMulai ?? DateTime.now())
        : (_tanggalSelesai ??
            (_tanggalMulai?.add(const Duration(days: 1)) ?? DateTime.now()));

    final firstDate = isMulai
        ? DateTime.now().subtract(const Duration(days: 365))
        : (_tanggalMulai?.add(const Duration(days: 1)) ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0088FF)),
        ),
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;
    setState(() {
      if (isMulai) {
        _tanggalMulai = picked;
        // Reset tanggal selesai jika sekarang lebih awal dari mulai
        if (_tanggalSelesai != null &&
            !_tanggalSelesai!.isAfter(picked)) {
          _tanggalSelesai = null;
        }
        // Reset slot pilihan karena tanggal berubah (conflict detection akan beda)
        _selectedSlotIds.clear();
      } else {
        _tanggalSelesai = picked;
      }
    });
  }

  // ── Slot Picker (Phase 1: bottom sheet checklist) ───────────

  Future<void> _pilihSlot() async {
    if (_semuaSlot.isEmpty) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SlotPickerSheet(
        semuaSlot: _semuaSlot,
        initialSelected: Set.from(_selectedSlotIds),
        onConfirm: (selected) =>
            setState(() {
              _selectedSlotIds
                ..clear()
                ..addAll(selected);
            }),
      ),
    );
  }

  String _jenisLabel() {
    if (_selectedSlotIds.isEmpty) return 'Pilih lokasi tenda...';
    return _semuaSlot
        .where((s) => _selectedSlotIds.contains(s.id))
        .map((s) => s.labelDisplay)
        .join(', ');
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

    final fmt = DateFormat('yyyy-MM-dd');
    final pengunjung = Pengunjung(
      id: _uuid.v4(),
      nama: _namaCtrl.text.trim(),
      alamat: _alamatCtrl.text.trim(),
      tanggalMulai: fmt.format(_tanggalMulai!),
      tanggalSelesai: fmt.format(_tanggalSelesai!),
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

    // Tutup screen setelah simpan (provider sudah notify listeners)
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.pop(context);
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              decoration:
                  const InputDecoration(hintText: 'Nama penanggung jawab rombongan'),
            ),

            // ── Pilih Tenda ──
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
                  children: [
                    Expanded(
                      child: Text(
                        _jenisLabel(),
                        style: TextStyle(
                          color: _selectedSlotIds.isEmpty
                              ? Colors.grey.shade500
                              : Colors.black87,
                          fontSize: 14,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
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
                child: Text(
                  '${_selectedSlotIds.length} slot dipilih',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF0088FF)),
                ),
              ),

            _Label('Alamat'),
            TextField(
              controller: _alamatCtrl,
              textCapitalization: TextCapitalization.words,
              decoration:
                  const InputDecoration(hintText: 'Kota / Kabupaten asal'),
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

            _Label('Jumlah Pengunjung'),
            TextField(
              controller: _jumlahCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(hintText: 'Contoh: 4'),
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
              decoration:
                  const InputDecoration(hintText: 'Catatan tambahan...'),
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

// ── Slot Picker Bottom Sheet ────────────────────────────────────
// Phase 2: ganti class ini dengan DenahTendaScreen (visual denah)
// tanpa perlu ubah apapun di TambahPengunjungScreen.

class _SlotPickerSheet extends StatefulWidget {
  final List<SlotTenda> semuaSlot;
  final Set<String> initialSelected;
  final void Function(Set<String>) onConfirm;

  const _SlotPickerSheet({
    required this.semuaSlot,
    required this.initialSelected,
    required this.onConfirm,
  });

  @override
  State<_SlotPickerSheet> createState() => _SlotPickerSheetState();
}

class _SlotPickerSheetState extends State<_SlotPickerSheet> {
  late Set<String> _selected;
  late Map<String, List<SlotTenda>> _grouped;

  static const _kategoris = ['VIP', 'REGULER', 'CITYLIGHT'];
  static const _labelMap = {
    'VIP': 'VIP',
    'REGULER': 'Reguler A–J',
    'CITYLIGHT': 'Citylight',
  };

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
    _grouped = {};
    for (final s in widget.semuaSlot) {
      _grouped.putIfAbsent(s.kategori, () => []).add(s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pilih Tenda',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              children: [
                for (final kat in _kategoris) ...[
                  // Category header
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 4),
                    child: Text(
                      _labelMap[kat] ?? kat,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0088FF),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Slot checkboxes
                  for (final slot in _grouped[kat] ?? [])
                    CheckboxListTile(
                      title: Text(slot.labelDisplay,
                          style: const TextStyle(fontSize: 14)),
                      value: _selected.contains(slot.id),
                      activeColor: const Color(0xFF0088FF),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onChanged: (v) => setState(() =>
                          v == true
                              ? _selected.add(slot.id)
                              : _selected.remove(slot.id)),
                    ),
                  const Divider(height: 16),
                ],
              ],
            ),
          ),

          // Footer
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () {
                          widget.onConfirm(_selected);
                          Navigator.pop(context);
                        },
                  child: Text(
                    _selected.isEmpty
                        ? 'Pilih Tenda'
                        : 'Pilih (${_selected.length} slot)',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
