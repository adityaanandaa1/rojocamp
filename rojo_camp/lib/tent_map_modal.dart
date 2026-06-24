import 'package:flutter/material.dart';
import 'database_helper.dart';

class TentMapModal extends StatefulWidget {
  const TentMapModal({super.key});

  @override
  State<TentMapModal> createState() => _TentMapModalState();
}

class _TentMapModalState extends State<TentMapModal> {
  String? _selected;
  List<String> _bookedTents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookedTents();
  }

  void _loadBookedTents() async {
    final booked = await DatabaseHelper.instance.getBookedTents();
    setState(() {
      _bookedTents = booked;
      _isLoading = false;
    });
  }

  Widget _buildButton(String backendId, String displayLabel) {
    bool isBooked = _bookedTents.contains(backendId);
    bool isSelected = _selected == backendId;

    Color bgColor = isBooked ? Colors.grey.shade500 : isSelected ? const Color(0xFF2563EB) : Colors.white;
    Color textColor = isBooked ? Colors.white : isSelected ? Colors.white : Colors.black87;
    Color borderColor = isBooked ? Colors.grey.shade500 : const Color(0xFF2563EB);

    return GestureDetector(
      onTap: isBooked ? null : () {
        setState(() => _selected = backendId);
      },
      child: Container(
        height: 40,
        margin: const EdgeInsets.all(4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Text(displayLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _buildBlock(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF93C5FD).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildGround(String name, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF93C5FD).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 6),
          ...rows,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Denah Tenda", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildBlock([
                        _buildButton('VIP 5', 'VIP 5'),
                        _buildButton('VIP 4', 'VIP 4'),
                        _buildButton('VIP 3', 'VIP 3'),
                        _buildButton('VIP 2', 'VIP 2'),
                        _buildButton('Mini Ground', 'Mini Ground'),
                        _buildButton('VIP 1', 'VIP 1'),
                      ]),

                      _buildBlock([
                        Row(children: [Expanded(child: _buildButton('Kavling B', 'B')), Expanded(child: _buildButton('Kavling A', 'A'))]),
                        Row(children: [Expanded(child: _buildButton('Kavling D', 'D')), Expanded(child: _buildButton('Kavling C', 'C'))]),
                        Row(children: [Expanded(child: _buildButton('Kavling F', 'F')), Expanded(child: _buildButton('Kavling E', 'E'))]),
                        Row(children: [Expanded(child: _buildButton('Kavling H', 'H')), Expanded(child: _buildButton('Kavling G', 'G'))]),
                        Row(children: [Expanded(child: _buildButton('Kavling J', 'J')), Expanded(child: _buildButton('Kavling I', 'I'))]),
                      ]),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Citylight', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),

                      _buildGround('Ground 1', [Row(children: [Expanded(child: _buildButton('Ground 1-C', 'C')), Expanded(child: _buildButton('Ground 1-B', 'B')), Expanded(child: _buildButton('Ground 1-A', 'A'))])]),
                      _buildGround('Ground 2', [Row(children: [Expanded(child: _buildButton('Ground 2-C', 'C')), Expanded(child: _buildButton('Ground 2-B', 'B')), Expanded(child: _buildButton('Ground 2-A', 'A'))])]),
                      _buildGround('Ground 3', [
                        Row(children: [Expanded(child: _buildButton('Ground 3-C', 'C')), Expanded(child: _buildButton('Ground 3-B', 'B')), Expanded(child: _buildButton('Ground 3-A', 'A'))]),
                        Row(children: [Expanded(child: _buildButton('Ground 3-F', 'F')), Expanded(child: _buildButton('Ground 3-E', 'E')), Expanded(child: _buildButton('Ground 3-D', 'D'))]),
                      ]),
                      _buildGround('Ground 4', [
                        Row(children: [Expanded(child: _buildButton('Ground 4-C', 'C')), Expanded(child: _buildButton('Ground 4-B', 'B')), Expanded(child: _buildButton('Ground 4-A', 'A'))]),
                        Row(children: [Expanded(child: _buildButton('Ground 4-F', 'F')), Expanded(child: _buildButton('Ground 4-E', 'E')), Expanded(child: _buildButton('Ground 4-D', 'D'))]),
                      ]),
                      _buildGround('Ground 5', [
                        Row(children: [Expanded(child: _buildButton('Ground 5-H', 'H')), Expanded(child: _buildButton('Ground 5-G', 'G'))]),
                        Row(children: [Expanded(child: _buildButton('Ground 5-J', 'J')), Expanded(child: _buildButton('Ground 5-I', 'I'))]),
                      ]),
                      _buildGround('Ground 6', [Row(children: [Expanded(child: _buildButton('Ground 6-C', 'C')), Expanded(child: _buildButton('Ground 6-B', 'B')), Expanded(child: _buildButton('Ground 6-A', 'A'))])]),
                      _buildGround('Ground 7', [Row(children: [Expanded(child: _buildButton('Ground 7-B', 'B')), Expanded(child: _buildButton('Ground 7-A', 'A'))])]),
                      _buildGround('Ground 8', [Row(children: [Expanded(child: _buildButton('Ground 8-B', 'B')), Expanded(child: _buildButton('Ground 8-A', 'A'))])]),
                      _buildGround('Ground 9', [Row(children: [Expanded(child: _buildButton('Ground 9-B', 'B')), Expanded(child: _buildButton('Ground 9-A', 'A'))])]),
                    ],
                  ),
                ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selected == null ? null : () {
                  Navigator.pop(context, _selected);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Pilih Denah", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          )
        ],
      ),
    );
  }
}