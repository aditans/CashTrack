import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  'entertainment': Icons.tv_sharp,
  'salary': Icons.money_rounded,
  'gaming': Icons.videogame_asset,
  'utilities': Icons.electrical_services,
  'education': Icons.school,
  'fuel': Icons.local_gas_station,
  'fitness': Icons.fitness_center,
  'clothing': Icons.shopping_bag,


};

class TransactionDetailPage extends StatefulWidget {
  final SmsModel transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  late String selectedTag;
  List<String> customTags = [];

  final List<String> defaultTags = [
    'food', 'groceries', 'travel', 'medicines', 'shopping', 'bills', 'rent', 'others','entertainment',
    'salary',
    'gaming',
    'utilities',
    'education',
    'fuel',
    'fitness',
    'clothing'
  ];

  List<String> get allTags =>
      [...defaultTags, ...customTags.where((t) => !defaultTags.contains(t))];

  @override
  void initState() {
    super.initState();
    selectedTag = widget.transaction.tag ?? 'others';
    _loadCustomTags();
  }

  Future<void> _loadCustomTags() async {
    final tagBox = Hive.box<Map>('tagBox');
    final stored = tagBox.get('customTags', defaultValue: <String, int>{})!.keys.cast<String>().toList();
    setState(() => customTags = stored);
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
            title: const Text('New Tag', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Tag name',
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                  onChanged: (v) => newTag = v.trim(),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: iconOptions.map((ic) {
                    final sel = selectedIcon == ic;
                    return ChoiceChip(
                      avatar: Icon(ic, size: 20),
                      label: sel ? const Icon(Icons.check) : const SizedBox.shrink(),
                      selected: sel,
                      onSelected: (_) => setSB(() => selectedIcon = ic),
                      selectedColor: Colors.teal.withOpacity(0.3),
                      backgroundColor: Colors.grey[800],
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
                child: const Text('Save', style: TextStyle(color: Colors.tealAccent)),
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
      customTags = stored.keys.cast<String>().toList();
      _saveTag(tag);
    });
  }

  void _saveTag(String tag) {
    setState(() => selectedTag = tag);
    widget.transaction.tag = tag;
    widget.transaction.save();
  }

  Future<void> _confirmDeleteTag(String tag) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Delete "$tag"?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will remove the tag from the selection list.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final tagBox = Hive.box<Map>('tagBox');
    final stored = tagBox.get('customTags', defaultValue: <String, int>{})!.cast<String, int>();
    stored.remove(tag);
    await tagBox.put('customTags', stored);

    setState(() {
      customTags = stored.keys.toList();
      if (selectedTag == tag) {
        _saveTag('others');
      }
    });

    bool? removeFromTransactions = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Remove from existing transactions?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Do you want to clear this tag from all transactions where it is used?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (removeFromTransactions == true) {
      final smsBox = Hive.box<SmsModel>('smsBox');
      for (var sms in smsBox.values) {
        if (sms.tag == tag) {
          sms.tag = 'others';
          sms.save();
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "$tag" from all transactions.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = widget.transaction.type == 'credit';
    final tagBox = Hive.box<Map>('tagBox');
    final stored = tagBox.get('customTags', defaultValue: <String, int>{})!.cast<String, int>();
    final code = stored[selectedTag] ??
        tagIconMap[selectedTag.toLowerCase()]?.codePoint ??
        Icons.label_outline.codePoint;
    final displayedIcon = Icon(IconData(code, fontFamily: 'MaterialIcons'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Detail'),
        backgroundColor: Colors.cyan.shade700,
      ),
      backgroundColor: Colors.cyan.shade50,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isCredit ? 'Received from' : 'Paid to',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 4),
                Text(widget.transaction.sender,
                    style: TextStyle(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text('Amount', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(
                  '₹${widget.transaction.amount?.toStringAsFixed(2) ?? '0.00'}',
                  style: TextStyle(
                    color: isCredit ? Colors.green : Colors.red,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Date & Time', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a • dd MMM yyyy')
                      .format(widget.transaction.receivedAt),
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text('Original SMS', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(widget.transaction.body,
                    style: TextStyle(color: Colors.grey[800])),
                const SizedBox(height: 24),
                Row(children: [
                  displayedIcon,
                  const SizedBox(width: 8),
                  Text('Tag:', style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedTag,
                    dropdownColor: Colors.grey[200],
                    items: allTags
                        .map((tag) => DropdownMenuItem(
                      value: tag,
                      child: Text(tag, style: TextStyle(color: Colors.black)),
                    ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) _saveTag(val);
                    },
                  ),

                  TextButton.icon(
                    onPressed: _showAddCustomTagDialog,
                    icon: const Icon(Icons.add, color: Colors.cyan),
                    label: const Text('Tag', style: TextStyle(color: Colors.cyan ,fontSize: 12)),
                  ),
                ]),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  children: allTags.map((tag) {
                    final sel = tag == selectedTag;
                    Widget chip = ChoiceChip(
                      label: Text(tag),
                      selected: sel,
                      selectedColor: Colors.cyan,
                      backgroundColor: Colors.grey.shade200,
                      labelStyle: TextStyle(color: Colors.black),
                      onSelected: (_) => _saveTag(tag),
                    );
                    if (customTags.contains(tag)) {
                      chip = GestureDetector(
                        onLongPress: () => _confirmDeleteTag(tag),
                        child: chip,
                      );
                    }
                    return chip;
                  }).toList(),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
