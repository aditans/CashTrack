import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/balance_service.dart';

class SetBalanceModal extends StatefulWidget {
  final DateTime selectedDate;
  const SetBalanceModal({super.key, required this.selectedDate});

  @override
  State<SetBalanceModal> createState() => _SetBalanceModalState();
}

class _SetBalanceModalState extends State<SetBalanceModal> {
  final TextEditingController _controller = TextEditingController();
  final BalanceService _service = BalanceService();

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    // Pass selectedDate for per-month lookup
    final balance = await _service.getManualBalance(widget.selectedDate);
    if (balance != null) {
      _controller.text = balance.toString();
    } else {
      _controller.clear(); // No manual balance for this period
    }
  }

  Future<void> _save() async {
    final value = double.tryParse(_controller.text);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid amount")),
      );
      return;
    }
    // Pass selectedDate for correct key
    await _service.setManualBalance(widget.selectedDate, value);
    if (mounted) Navigator.of(context).pop(true); // returning true; trigger reload
  }

  Future<void> _reset() async {
    // Pass selectedDate to clear only this period
    await _service.clearManualBalance(widget.selectedDate);
    if (mounted) Navigator.of(context).pop(true); // returning true; trigger reload
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Wrap(
        runSpacing: 20,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(
            'Set Manual Balance for ${DateFormat('MMMM yyyy').format(widget.selectedDate)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Enter Total balance',
              border: OutlineInputBorder(),
            ),
          ),
          ElevatedButton(
              onPressed: _save, child: const Text('Save')
          ),
          TextButton(
            onPressed: _reset,
            child: const Text('Reset to calculated balance'),
          ),
        ],
      ),
    );
  }
}
