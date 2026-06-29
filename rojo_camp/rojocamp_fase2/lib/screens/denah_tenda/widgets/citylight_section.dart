// lib/screens/denah_tenda/widgets/citylight_section.dart

import 'package:flutter/material.dart';
import '../../../data/models/slot_tenda.dart';
import 'slot_button.dart';

/// Section Citylight: 31 slot dikelompokkan per Ground (1–9).
/// Tiap Ground punya header label dan slot-nya ditampilkan dalam baris 3 kolom.
///
/// Ground 1: A, B, C            (3 slot)
/// Ground 2: A, B, C            (3 slot)
/// Ground 3: A, B, C, D, E, F   (6 slot — 2 baris)
/// Ground 4: A, B, C, D, E, F   (6 slot — 2 baris)
/// Ground 5: G, H, I, J         (4 slot — 2 baris: G,H / I,J)
/// Ground 6: A, B, C            (3 slot)
/// Ground 7: A, B               (2 slot)
/// Ground 8: A, B               (2 slot)
/// Ground 9: A, B               (2 slot)
class CitylightSection extends StatelessWidget {
  final List<SlotTenda> slots;

  const CitylightSection({super.key, required this.slots});

  /// Kelompokkan slot berdasarkan nomor Ground.
  /// Ambil dari labelDisplay: "Ground 4 C" → Ground 4
  Map<int, List<SlotTenda>> _groupByGround() {
    final map = <int, List<SlotTenda>>{};
    for (final s in slots) {
      // labelDisplay format: "Ground N X"
      final parts = s.labelDisplay.split(' ');
      final groundNum = int.tryParse(parts[1]) ?? 0;
      map.putIfAbsent(groundNum, () => []).add(s);
    }
    // Pastikan urutan by nomor ground
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupByGround();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Citylight'),
        const SizedBox(height: 10),
        ...groups.entries.map((entry) {
          final groundNum = entry.key;
          final groundSlots = entry.value;

          // Bagi slot ke baris masing-masing 3 kolom
          final rows = <List<SlotTenda>>[];
          for (int i = 0; i < groundSlots.length; i += 3) {
            rows.add(
              groundSlots.sublist(i, (i + 3).clamp(0, groundSlots.length)),
            );
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ground $groundNum',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                ...rows.map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        for (int i = 0; i < row.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          Expanded(
                            child: SlotButton(
                              slotId: row[i].id,
                              // Tampilkan hanya hurufnya: "Ground 4 C" → "C"
                              displayLabel: row[i].labelDisplay.split(' ').last,
                              height: 44,
                            ),
                          ),
                        ],
                        // Filler jika baris tidak penuh (misal 2 slot di baris terakhir)
                        for (int i = row.length; i < 3; i++) ...[
                          const SizedBox(width: 6),
                          const Expanded(child: SizedBox()),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
