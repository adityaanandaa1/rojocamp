// lib/screens/denah_tenda/widgets/vip_section.dart

import 'package:flutter/material.dart';
import '../../../data/models/slot_tenda.dart';
import 'slot_button.dart';

/// Section VIP: 6 slot (VIP1–VIP5 + Mini Ground) dalam list vertikal full-width.
/// Urutan sesuai sort_order: VIP5 → VIP4 → VIP3 → VIP2 → Mini Ground → VIP1
class VipSection extends StatelessWidget {
  final List<SlotTenda> slots;

  const VipSection({super.key, required this.slots});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'VIP'),
        const SizedBox(height: 10),
        ...slots.map(
          (slot) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SlotButton(
              slotId: slot.id,
              displayLabel: slot.labelDisplay,
              height: 50,
            ),
          ),
        ),
      ],
    );
  }
}
