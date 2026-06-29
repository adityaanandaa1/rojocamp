// lib/data/database/seed_data.dart
// Master data semua slot tenda — statis, tidak berubah saat runtime.
// Di-insert ke tabel slot_tenda saat pertama kali install.

import '../models/slot_tenda.dart';

const List<SlotTenda> kSemuaSlot = [
  // ─── VIP (6 slot) ───────────────────────────────────────────
  SlotTenda(id: 'VIP5',     kategori: 'VIP', labelDisplay: 'VIP 5',       sortOrder: 1),
  SlotTenda(id: 'VIP4',     kategori: 'VIP', labelDisplay: 'VIP 4',       sortOrder: 2),
  SlotTenda(id: 'VIP3',     kategori: 'VIP', labelDisplay: 'VIP 3',       sortOrder: 3),
  SlotTenda(id: 'VIP2',     kategori: 'VIP', labelDisplay: 'VIP 2',       sortOrder: 4),
  SlotTenda(id: 'VIP_MINI', kategori: 'VIP', labelDisplay: 'Mini Ground', sortOrder: 5),
  SlotTenda(id: 'VIP1',     kategori: 'VIP', labelDisplay: 'VIP 1',       sortOrder: 6),

  // ─── REGULER (10 slot, A–J) ──────────────────────────────────
  SlotTenda(id: 'REG_A', kategori: 'REGULER', labelDisplay: 'A', sortOrder: 7),
  SlotTenda(id: 'REG_B', kategori: 'REGULER', labelDisplay: 'B', sortOrder: 8),
  SlotTenda(id: 'REG_C', kategori: 'REGULER', labelDisplay: 'C', sortOrder: 9),
  SlotTenda(id: 'REG_D', kategori: 'REGULER', labelDisplay: 'D', sortOrder: 10),
  SlotTenda(id: 'REG_E', kategori: 'REGULER', labelDisplay: 'E', sortOrder: 11),
  SlotTenda(id: 'REG_F', kategori: 'REGULER', labelDisplay: 'F', sortOrder: 12),
  SlotTenda(id: 'REG_G', kategori: 'REGULER', labelDisplay: 'G', sortOrder: 13),
  SlotTenda(id: 'REG_H', kategori: 'REGULER', labelDisplay: 'H', sortOrder: 14),
  SlotTenda(id: 'REG_I', kategori: 'REGULER', labelDisplay: 'I', sortOrder: 15),
  SlotTenda(id: 'REG_J', kategori: 'REGULER', labelDisplay: 'J', sortOrder: 16),

  // ─── CITYLIGHT (31 slot) ─────────────────────────────────────
  // Ground 1 — A, B, C
  SlotTenda(id: 'CL_1A', kategori: 'CITYLIGHT', labelDisplay: 'Ground 1 A', sortOrder: 17),
  SlotTenda(id: 'CL_1B', kategori: 'CITYLIGHT', labelDisplay: 'Ground 1 B', sortOrder: 18),
  SlotTenda(id: 'CL_1C', kategori: 'CITYLIGHT', labelDisplay: 'Ground 1 C', sortOrder: 19),
  // Ground 2 — A, B, C
  SlotTenda(id: 'CL_2A', kategori: 'CITYLIGHT', labelDisplay: 'Ground 2 A', sortOrder: 20),
  SlotTenda(id: 'CL_2B', kategori: 'CITYLIGHT', labelDisplay: 'Ground 2 B', sortOrder: 21),
  SlotTenda(id: 'CL_2C', kategori: 'CITYLIGHT', labelDisplay: 'Ground 2 C', sortOrder: 22),
  // Ground 3 — A, B, C, D, E, F
  SlotTenda(id: 'CL_3A', kategori: 'CITYLIGHT', labelDisplay: 'Ground 3 A', sortOrder: 23),
  SlotTenda(id: 'CL_3B', kategori: 'CITYLIGHT', labelDisplay: 'Ground 3 B', sortOrder: 24),
  SlotTenda(id: 'CL_3C', kategori: 'CITYLIGHT', labelDisplay: 'Ground 3 C', sortOrder: 25),
  SlotTenda(id: 'CL_3D', kategori: 'CITYLIGHT', labelDisplay: 'Ground 3 D', sortOrder: 26),
  SlotTenda(id: 'CL_3E', kategori: 'CITYLIGHT', labelDisplay: 'Ground 3 E', sortOrder: 27),
  SlotTenda(id: 'CL_3F', kategori: 'CITYLIGHT', labelDisplay: 'Ground 3 F', sortOrder: 28),
  // Ground 4 — A, B, C, D, E, F
  SlotTenda(id: 'CL_4A', kategori: 'CITYLIGHT', labelDisplay: 'Ground 4 A', sortOrder: 29),
  SlotTenda(id: 'CL_4B', kategori: 'CITYLIGHT', labelDisplay: 'Ground 4 B', sortOrder: 30),
  SlotTenda(id: 'CL_4C', kategori: 'CITYLIGHT', labelDisplay: 'Ground 4 C', sortOrder: 31),
  SlotTenda(id: 'CL_4D', kategori: 'CITYLIGHT', labelDisplay: 'Ground 4 D', sortOrder: 32),
  SlotTenda(id: 'CL_4E', kategori: 'CITYLIGHT', labelDisplay: 'Ground 4 E', sortOrder: 33),
  SlotTenda(id: 'CL_4F', kategori: 'CITYLIGHT', labelDisplay: 'Ground 4 F', sortOrder: 34),
  // Ground 5 — G, H, I, J
  SlotTenda(id: 'CL_5G', kategori: 'CITYLIGHT', labelDisplay: 'Ground 5 G', sortOrder: 35),
  SlotTenda(id: 'CL_5H', kategori: 'CITYLIGHT', labelDisplay: 'Ground 5 H', sortOrder: 36),
  SlotTenda(id: 'CL_5I', kategori: 'CITYLIGHT', labelDisplay: 'Ground 5 I', sortOrder: 37),
  SlotTenda(id: 'CL_5J', kategori: 'CITYLIGHT', labelDisplay: 'Ground 5 J', sortOrder: 38),
  // Ground 6 — A, B, C
  SlotTenda(id: 'CL_6A', kategori: 'CITYLIGHT', labelDisplay: 'Ground 6 A', sortOrder: 39),
  SlotTenda(id: 'CL_6B', kategori: 'CITYLIGHT', labelDisplay: 'Ground 6 B', sortOrder: 40),
  SlotTenda(id: 'CL_6C', kategori: 'CITYLIGHT', labelDisplay: 'Ground 6 C', sortOrder: 41),
  // Ground 7 — A, B
  SlotTenda(id: 'CL_7A', kategori: 'CITYLIGHT', labelDisplay: 'Ground 7 A', sortOrder: 42),
  SlotTenda(id: 'CL_7B', kategori: 'CITYLIGHT', labelDisplay: 'Ground 7 B', sortOrder: 43),
  // Ground 8 — A, B
  SlotTenda(id: 'CL_8A', kategori: 'CITYLIGHT', labelDisplay: 'Ground 8 A', sortOrder: 44),
  SlotTenda(id: 'CL_8B', kategori: 'CITYLIGHT', labelDisplay: 'Ground 8 B', sortOrder: 45),
  // Ground 9 — A, B
  SlotTenda(id: 'CL_9A', kategori: 'CITYLIGHT', labelDisplay: 'Ground 9 A', sortOrder: 46),
  SlotTenda(id: 'CL_9B', kategori: 'CITYLIGHT', labelDisplay: 'Ground 9 B', sortOrder: 47),
];
