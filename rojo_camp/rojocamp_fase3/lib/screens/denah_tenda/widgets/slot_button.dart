// lib/screens/denah_tenda/widgets/slot_button.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/denah_provider.dart';

/// Tombol satu slot tenda. Warnanya reaktif terhadap DenahProvider:
/// - Putih  = tersedia
/// - Biru   = sedang dipilih admin
/// - Abu-abu = sudah dipesan rombongan lain (tidak bisa dipilih)
///
/// Menggunakan context.select() agar hanya slot ini yang rebuild
/// saat slot lain berubah — penting untuk performa dengan 47 tombol di layar.
class SlotButton extends StatelessWidget {
  final String slotId;
  final String displayLabel; // teks yang ditampilkan di tombol
  final double? height;

  const SlotButton({
    super.key,
    required this.slotId,
    required this.displayLabel,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.select<DenahProvider, SlotState>(
      (p) => p.getState(slotId),
    );

    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (state) {
      case SlotState.selected:
        bgColor = const Color(0xFF0088FF);
        textColor = Colors.white;
        borderColor = const Color(0xFF0088FF);
      case SlotState.booked:
        bgColor = const Color(0xFF7A7979);
        textColor = Colors.white;
        borderColor = const Color(0xFF7A7979);
      case SlotState.available:
        bgColor = Colors.white;
        textColor = Colors.black87;
        borderColor = Colors.grey.shade300;
    }

    return GestureDetector(
      onTap: state == SlotState.booked
          ? null
          : () => context.read<DenahProvider>().toggleSlot(slotId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: state == SlotState.available
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            displayLabel,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// Header tiap section di Denah Tenda.
class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0088FF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0088FF),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
