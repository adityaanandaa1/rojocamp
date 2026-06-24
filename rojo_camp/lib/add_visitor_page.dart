import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'pengunjung.dart';
import 'tent_map_modal.dart';

class AddVisitorPage extends StatefulWidget {
  final VoidCallback onSave;
  const AddVisitorPage({super.key, required this.onSave});

  @override
  State<AddVisitorPage> createState() => _AddVisitorPageState();
}

class _AddVisitorPageState extends State<AddVisitorPage> {
  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _keteranganController = TextEditingController();
  
  String? _selectedTenda; 
  String _selectedPesanan = 'Reservasi'; 
  
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;

  Future<void> _pilihTanggal(BuildContext context, bool isMulai) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isMulai) {
          _tanggalMulai = picked;
        } else {
          _tanggalSelesai = picked;
        }
      });
    }
  }

  void _simpanData() async {
    if (_namaController.text.isEmpty || _alamatController.text.isEmpty || _tanggalMulai == null || _tanggalSelesai == null || _jumlahController.text.isEmpty || _selectedTenda == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon isi semua data & Pilih Denah Tenda!")),
      );
      return;
    }

    final pengunjungBaru = Pengunjung(
      nama: _namaController.text,
      alamat: _alamatController.text,
      jenisTenda: _selectedTenda!,
      tanggalMasuk: DateFormat('dd MMM yyyy').format(DateTime.now()),
      tanggalMulai: DateFormat('dd MMM yyyy').format(_tanggalMulai!),
      tanggalSelesai: DateFormat('dd MMM yyyy').format(_tanggalSelesai!),
      jumlahPengunjung: int.tryParse(_jumlahController.text) ?? 1,
      jenisPesanan: _selectedPesanan,
      keterangan: _keteranganController.text.isEmpty ? "-" : _keteranganController.text,
    );

    await DatabaseHelper.instance.insertPengunjung(pengunjungBaru);
    
    if (!mounted) return;

    _namaController.clear();
    _alamatController.clear();
    _jumlahController.clear();
    _keteranganController.clear();
    setState(() {
      _tanggalMulai = null;
      _tanggalSelesai = null;
      _selectedTenda = null;
    });
    
    widget.onSave(); 
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Data Pengunjung Berhasil Disimpan!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Pengunjung", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Nama Pengunjung"),
            _buildTextField(_namaController, "Masukkan nama..."),
            
            _buildLabel("Pilih Denah Tenda"),
            InkWell(
              onTap: () async {
                final result = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const TentMapModal(),
                );
                if (result != null) {
                  setState(() => _selectedTenda = result);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedTenda ?? "Pilih lokasi tenda...",
                      style: TextStyle(
                        color: _selectedTenda == null ? Colors.grey.shade600 : Colors.black,
                        fontSize: 15,
                        fontWeight: _selectedTenda == null ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.map, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ),

            _buildLabel("Alamat"),
            _buildTextField(_alamatController, "Masukkan alamat kota...", maxLines: 3),
            
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildDatePicker("Tanggal Mulai", _tanggalMulai, true)),
                const SizedBox(width: 16),
                Expanded(child: _buildDatePicker("Tanggal Selesai", _tanggalSelesai, false)),
              ],
            ),
            
            _buildLabel("Jumlah Pengunjung"),
            TextField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: _inputDeco(hint: "Misal: 4"),
            ),

            _buildLabel("Jenis Pesanan"),
            DropdownButtonFormField<String>(
              initialValue: _selectedPesanan, // <-- Diperbaiki agar tidak kuning
              decoration: _inputDeco(),
              items: ['Reservasi', 'Walk-in / Piknik'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _selectedPesanan = val!),
            ),

            _buildLabel("Keterangan"),
            _buildTextField(_keteranganController, "Catatan tambahan (opsional)..."),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _simpanData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Tambah Pengunjung", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  InputDecoration _inputDeco({String? hint}) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: _inputDeco(hint: hint),
    );
  }

  Widget _buildDatePicker(String label, DateTime? selectedDate, bool isMulai) {
    return InkWell(
      onTap: () => _pilihTanggal(context, isMulai),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDate == null ? label : DateFormat('dd MMM yyyy').format(selectedDate),
              style: TextStyle(color: selectedDate == null ? Colors.grey.shade600 : Colors.black, fontSize: 13),
            ),
            const Icon(Icons.calendar_today, size: 16),
          ],
        ),
      ),
    );
  }
}