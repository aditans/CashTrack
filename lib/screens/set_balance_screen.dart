import 'package:flutter/material.dart';
import '../services/balance_service.dart';

class SetBalanceModal extends StatefulWidget {
  const SetBalanceModal({super.key});

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
    final balance = await _service.getManualBalance();
    if (balance != null) {
      _controller.text = balance.toString();
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
    await _service.setManualBalance(value);
    Navigator.of(context).pop(true); // returning true; trigger reload
  }

  Future<void> _reset() async {
    await _service.clearManualBalance();
    Navigator.of(context).pop(true); // returning true; trigger reload
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Wrap(
        runSpacing: 20,
        children: [
          Center(child: Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
                color: Colors.grey[300], borderRadius: BorderRadius.circular(2)
            ),
          )),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Enter balance',
              border: OutlineInputBorder(),
            ),
          ),
          ElevatedButton(
              onPressed: _save,
              child: const Text('Save')
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
