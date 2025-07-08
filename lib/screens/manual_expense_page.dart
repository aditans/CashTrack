import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/sms_model.dart';

const tagIconMap = {
  'food': Icons.fastfood,
  'groceries': Icons.local_grocery_store,
  'travel': Icons.directions_bus,
  'medicines': Icons.local_hospital,
  'shopping': Icons.shopping_bag,
  'bills': Icons.receipt,
  'rent': Icons.home,
  'others': Icons.category,
};

class ManualExpensePage extends StatefulWidget {
  const ManualExpensePage({super.key});

  @override
  State<ManualExpensePage> createState() => _ManualExpensePageState();
}

class _ManualExpensePageState extends State<ManualExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'debit';
  String selectedTag = 'Others';
  List<String> customTags = [];
  final Color robinsEggBlue = const Color(0xFF00CCE7);

  final List<String> defaultTags = [
    'Food', 'Groceries', 'Travel', 'Medicines', 'Shopping', 'Bills', 'Rent', 'Others'
  ];

  List<String> get allTags => [
    ...defaultTags,
    ...customTags.where((t) => !defaultTags.map((d) => d.toLowerCase()).contains(t.toLowerCase())),
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomTags();
  }

  Future<void> _loadCustomTags() async {
    final tagBox = Hive.box<Map>('tagBox');
    final stored = tagBox.get('customTags', defaultValue: <String, int>{})!;
    setState(() {
      customTags = stored.keys.cast<String>().toList();
    });
  }

  Future<void> _showAddCustomTagDialog() async {
    String newTag = '';
    IconData? selectedIcon;
    final iconOptions = [
      Icons.fastfood,
      Icons.shopping_bag,
      Icons.local_grocery_store,
      Icons.home,
      Icons.directions_bus,
      Icons.local_hospital,
      Icons.category,
      Icons.coffee,
    ];

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setSB) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('New Tag', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Tag name',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                  ),
                  onChanged: (v) => newTag = v.trim(),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: iconOptions.map((ic) {
                    final sel = selectedIcon == ic;
                    return ChoiceChip(
                      avatar: Icon(ic, size: 20, color: sel ? Colors.lightBlueAccent : Colors.white70),
                      label: sel ? const Icon(Icons.check, color: Colors.tealAccent) : const SizedBox.shrink(),
                      selected: sel,
                      onSelected: (_) => setSB(() => selectedIcon = ic),
                      selectedColor: robinsEggBlue,
                      backgroundColor: Colors.grey[800],
                      labelStyle: const TextStyle(color: Colors.white),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
              TextButton(
                onPressed: newTag.isNotEmpty && selectedIcon != null
                    ? () {
                  Navigator.pop(context);
                  _saveCustomTagWithIcon(newTag, selectedIcon!);
                }
                    : null,
                child: const Text('Save', style: TextStyle(color: Colors.lightBlueAccent)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveCustomTagWithIcon(String tag, IconData icon) async {
    final tagBox = Hive.box<Map>('tagBox');
    final stored = tagBox.get('customTags', defaultValue: <String, int>{})!.cast<String, int>();
    stored[tag] = icon.codePoint;
    await tagBox.put('customTags', stored);
    setState(() {
      customTags = stored.keys.toList();
      selectedTag = tag;
    });
  }

  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final sms = SmsModel(
      sender: 'Cash ${_selectedType == 'debit' ? 'Expense' : 'Income'}',
      body: _descriptionController.text,
      receivedAt: _selectedDate,
      amount: amount,
      type: _selectedType,
      tag: selectedTag,
    );
    Hive.box<SmsModel>('smsBox').add(sms);
    Navigator.of(context).pop();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.lightBlueAccent,
            surface: Colors.black,
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: Colors.grey[900],
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color bgGradient1 = Colors.tealAccent.shade100;
    final Color bgGradient2 = Colors.blue.shade200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Manual Transaction'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgGradient1, bgGradient2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('Expense', style: TextStyle(fontWeight: FontWeight.bold)),
                          selected: _selectedType == 'debit',
                          selectedColor: Colors.redAccent.shade100,
                          labelStyle: TextStyle(
                              color: _selectedType == 'debit'
                                  ? Colors.red.shade900
                                  : Colors.black),
                          onSelected: (_) => setState(() => _selectedType = 'debit'),
                        ),
                        const SizedBox(width: 16),
                        ChoiceChip(
                          label: const Text('Income', style: TextStyle(fontWeight: FontWeight.bold)),
                          selected: _selectedType == 'credit',
                          selectedColor: Colors.greenAccent.shade100,
                          labelStyle: TextStyle(
                              color: _selectedType == 'credit'
                                  ? Colors.green.shade900
                                  : Colors.black),
                          onSelected: (_) => setState(() => _selectedType = 'credit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _amountController,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: Icon(Icons.currency_rupee, color: Colors.teal.shade700),
                        filled: true,
                        fillColor: Colors.teal.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || double.tryParse(val) == null || double.parse(val) <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        filled: true,
                        fillColor: Colors.teal.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'Add a description' : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text('Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _pickDate(context),
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: const Text('Change Date'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text('Tag:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 10),
                        TextButton.icon(
                          onPressed: _showAddCustomTagDialog,
                          icon: const Icon(Icons.add, color: Colors.cyan),
                          label: const Text('New Tag', style: TextStyle(color: Colors.cyan)),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allTags.map((tag) {
                        final isSelected = selectedTag.toLowerCase() == tag.toLowerCase();
                        final tagBox = Hive.box<Map>('tagBox');
                        final iconCode = tagBox.get('customTags', defaultValue: <String, int>{})?[tag] ??
                            tagIconMap[tag.toLowerCase()]?.codePoint ??
                            Icons.label_outline.codePoint;

                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(IconData(iconCode, fontFamily: 'MaterialIcons'), size: 16),
                              const SizedBox(width: 4),
                              Text(tag),
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: Colors.teal,
                          onSelected: (_) => setState(() => selectedTag = tag),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _saveTransaction,
                        icon: const Icon(Icons.save),
                        label: const Text('Save', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
