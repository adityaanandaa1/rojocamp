// lib/screens/denah_tenda/widgets/reguler_section.dart

import 'package:flutter/material.dart';
import '../../../data/models/slot_tenda.dart';
import 'slot_button.dart';

/// Section Reguler: 10 slot (A–J) dalam grid 2 kolom.
/// Pair: A-B, C-D, E-F, G-H, I-J
class RegulerSection extends StatelessWidget {
  final List<SlotTenda> slots;

  const RegulerSection({super.key, required this.slots});

  @override
  Widget build(BuildContext context) {
    // Kelompokkan 2 slot per baris
    final rows = <List<SlotTenda>>[];
    for (int i = 0; i < slots.length; i += 2) {
      rows.add(
        slots.sublist(i, (i + 2).clamp(0, slots.length)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Reguler'),
        const SizedBox(height: 10),
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (int i = 0; i < row.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: SlotButton(
                      slotId: row[i].id,
                      displayLabel: row[i].labelDisplay, // "A", "B", ...
                      height: 52,
                    ),
                  ),
                ],
                // Jika baris terakhir hanya 1 slot, tambah spacer agar sejajar
                if (row.length < 2) ...[
                  const SizedBox(width: 8),
                  const Expanded(child: SizedBox()),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
