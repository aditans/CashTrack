import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:hive/hive.dart';

class SetLimitModal extends StatefulWidget {
  final DateTime selectedDate;
  const SetLimitModal({super.key,required this.selectedDate});

  @override
  State<SetLimitModal> createState() => _SetLimitModalState();
}

class _SetLimitModalState extends State<SetLimitModal> {
  final TextEditingController _limitController = TextEditingController();
  String get _limitKey =>
      'limit_${widget.selectedDate.year}_${widget.selectedDate.month}';
  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> setMonthlyLimit(double value) async {
    final box = await Hive.openBox('settingsBox');
    await box.put(_limitKey, value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Set Monthly Limit for ${DateFormat('MMMM yyyy').format(widget.selectedDate)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _limitController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monthly limit (in ₹)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () async {
              final value = double.tryParse(_limitController.text) ?? 0;
              if (value > 0) {
                await setMonthlyLimit(value);
                if (context.mounted) Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
    );
  }
}
