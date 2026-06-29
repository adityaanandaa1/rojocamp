// lib/data/models/slot_tenda.dart

class SlotTenda {
  final String id;          // Kode unik: 'VIP1', 'REG_A', 'CL_4C', dll
  final String kategori;    // 'VIP' | 'REGULER' | 'CITYLIGHT'
  final String labelDisplay; // Label tampilan: 'VIP 1', 'A', 'Ground 4 C', dll
  final int sortOrder;

  const SlotTenda({
    required this.id,
    required this.kategori,
    required this.labelDisplay,
    required this.sortOrder,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'kategori': kategori,
        'label_display': labelDisplay,
        'sort_order': sortOrder,
      };

  factory SlotTenda.fromMap(Map<String, dynamic> map) => SlotTenda(
        id: map['id'] as String,
        kategori: map['kategori'] as String,
        labelDisplay: map['label_display'] as String,
        sortOrder: map['sort_order'] as int,
      );
}
