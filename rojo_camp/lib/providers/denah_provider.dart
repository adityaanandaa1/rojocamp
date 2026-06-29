// lib/providers/denah_provider.dart

import 'package:flutter/foundation.dart';
import '../data/repositories/slot_repository.dart';

enum SlotState { available, selected, booked }

class DenahProvider extends ChangeNotifier {
  final SlotRepository _repo = SlotRepository();

  Set<String> _selectedSlotIds = {};
  Set<String> _bookedSlotIds = {};
  bool _isLoading = true;

  String _tanggalMulai = '';
  String _tanggalSelesai = '';

  // Gunakan Set.unmodifiable agar tidak bisa diubah dari luar
  Set<String> get selected => Set.unmodifiable(_selectedSlotIds);
  Set<String> get booked => _bookedSlotIds;
  bool get isLoading => _isLoading;
  int get selectedCount => _selectedSlotIds.length;
  String get tanggalMulai => _tanggalMulai;
  String get tanggalSelesai => _tanggalSelesai;

  /// Inisialisasi: set slot yang sudah dipilih sebelumnya,
  /// lalu query DB untuk slot yang sudah terpesan di rentang tanggal tersebut.
  Future<void> init({
    required String tanggalMulai,
    required String tanggalSelesai,
    required Set<String> initialSelected,
    String? excludePengunjungId, // untuk mode edit — slot milik sendiri tidak ikut dihitung
  }) async {
    _tanggalMulai = tanggalMulai;
    _tanggalSelesai = tanggalSelesai;
    _selectedSlotIds = Set.from(initialSelected);
    _isLoading = true;
    notifyListeners();

    _bookedSlotIds = await _repo.getBookedSlotIds(
      tanggalMulai: tanggalMulai,
      tanggalSelesai: tanggalSelesai,
      excludePengunjungId: excludePengunjungId,
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Kembalikan state visual sebuah slot.
  /// Dipanggil per-slot via context.select() agar hanya slot yang berubah yang di-rebuild.
  SlotState getState(String slotId) {
    if (_bookedSlotIds.contains(slotId)) return SlotState.booked;
    if (_selectedSlotIds.contains(slotId)) return SlotState.selected;
    return SlotState.available;
  }

  /// Toggle pilihan slot. Slot yang sudah terpesan tidak bisa dipilih.
  void toggleSlot(String slotId) {
    if (_bookedSlotIds.contains(slotId)) return;
    if (_selectedSlotIds.contains(slotId)) {
      _selectedSlotIds.remove(slotId);
    } else {
      _selectedSlotIds.add(slotId);
    }
    notifyListeners();
  }
}
