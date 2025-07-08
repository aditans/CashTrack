/*import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../models/sms_model.dart';

class TagSelectionScreen extends StatefulWidget {
  final String smsData;
  final int? smsKey; // smsKey is now optional

  const TagSelectionScreen({
    super.key,
    required this.smsData,
    this.smsKey,
  });

  @override
  State<TagSelectionScreen> createState() => _TagSelectionScreenState();
}

class _TagSelectionScreenState extends State<TagSelectionScreen> {
  late SmsModel sms;
  String? selectedTag;
  final List<String> tags = [
    'Food', 'Shopping', 'Bills', 'Salary', 'Travel', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    sms = SmsModel.fromJson(widget.smsData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Categorize Transaction',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  '${sms.sender}\n${sms.body}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: tags.map((tag) {
                    final isSelected = selectedTag == tag;
                    return ChoiceChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (_) => setState(() => selectedTag = tag),
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.blue[200],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blue[800] : Colors.black,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                    ),
                    ElevatedButton(
                      onPressed: selectedTag == null ? null : () => _saveTransaction(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                      ),
                      child: const Text('Save', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    final updatedSms = sms.copyWith(tag: selectedTag);
    final smsBox = Hive.box<SmsModel>('smsBox');
    if (widget.smsKey != null) {
      // Update existing SMS
      await smsBox.put(widget.smsKey, updatedSms);
    } else {
      // Add as new SMS if key is not available (notification flow)
      await smsBox.add(updatedSms);
    }
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('pending_sms');
    Navigator.pop(context);
  }
}
*/