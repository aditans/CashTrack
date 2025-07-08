import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';
import 'skillup_page.dart';
import 'splits_page.dart';

import '../models/sms_model.dart';
import 'transaction_detail_page.dart';

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
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String filterType = 'all';
  DateTime? startDate;
  DateTime? endDate;
  List<String> selectedTags = [];

  int selectedIndex = 2;

  void _onBottomNavTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SkillupPage()),
      );
    } else if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) =>  HomeScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GroupsSplitsFriendsPage()),
      );
    }
  }

  void _openFilterSheet() {
    final tagBox = Hive.box<Map>('tagBox');
    final tagMap = tagBox.get('customTags') ?? {};
    final allTags = tagMap.keys.toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF424243),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Filter Transactions',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: ['all', 'credit', 'debit'].map((type) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(type.toUpperCase()),
                            selected: filterType == type,
                            onSelected: (_) => setModalState(() => filterType = type),
                            selectedColor: const Color(0xFF00CCE7),
                            backgroundColor: Colors.grey[800],
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('From:', style: TextStyle(color: Colors.white)),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setModalState(() => startDate = picked);
                          },
                          child: Text(
                            startDate != null
                                ? DateFormat('dd MMM yyyy').format(startDate!)
                                : 'Select',
                            style: const TextStyle(color: Color(0xFF00CCE7)),
                          ),
                        ),
                        const Text('To:', style: TextStyle(color: Colors.white)),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setModalState(() => endDate = picked);
                          },
                          child: Text(
                            endDate != null
                                ? DateFormat('dd MMM yyyy').format(endDate!)
                                : 'Select',
                            style: const TextStyle(color: Color(0xFF00CCE7)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (allTags.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Tags:', style: TextStyle(color: Colors.white)),
                      ),
                      Wrap(
                        spacing: 8,
                        children: allTags.map((tag) {
                          final isSelected = selectedTags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: isSelected,
                            selectedColor: const Color(0xFF71E9E9),
                            backgroundColor: Colors.grey[700],
                            labelStyle: const TextStyle(color: Colors.white),
                            onSelected: (val) {
                              setModalState(() {
                                isSelected
                                    ? selectedTags.remove(tag)
                                    : selectedTags.add(tag);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00CCE7),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {});
                      },
                      child: const Text('Apply Filters'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          filterType = 'all';
                          startDate = null;
                          endDate = null;
                          selectedTags.clear();
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.refresh, color: Colors.orangeAccent),
                      label: const Text('Clear Filters',
                          style: TextStyle(color: Colors.orangeAccent)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _matchesFilters(SmsModel sms) {
    if (!(sms.type == 'credit' || sms.type == 'debit')) return false;
    if (filterType != 'all' && sms.type != filterType) return false;
    if (startDate != null && sms.receivedAt.isBefore(startDate!)) return false;
    if (endDate != null && sms.receivedAt.isAfter(endDate!)) return false;
    if (selectedTags.isNotEmpty && !selectedTags.contains(sms.tag)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final Color pageBg = const Color(0xFFB2F9FC); // Light cyan
    final Color cardBg = Colors.black;
    final Color subTextColor = Colors.grey[400]!;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        title: const Text(
          'All Transactions',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: _openFilterSheet,
          ),
        ],
      ),

      body: ValueListenableBuilder(
        valueListenable: Hive.box<SmsModel>('smsBox').listenable(),
        builder: (context, Box<SmsModel> box, _) {
          final messages = box.values.where(_matchesFilters).toList()
            ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: messages.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 100),
                child: Text(
                  "No transactions match filters",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final sms = messages[index];
                final isCredit = sms.type == 'credit';
                final time = DateFormat('hh:mm a dd, MMM').format(sms.receivedAt);

                final tagBox = Hive.box<Map>('tagBox');
                final iconCode = tagBox.get('customTags')?[sms.tag] ??
                    tagIconMap[sms.tag?.toLowerCase()]?.codePoint ??
                    Icons.label.codePoint;
                final tagIcon = Icon(
                  IconData(iconCode, fontFamily: 'MaterialIcons'),
                  color: Colors.white,
                );

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailPage(transaction: sms),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      image: DecorationImage(image: Image.asset('assets/transcations_card.png').image ,fit: BoxFit.cover),
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: tagIcon,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isCredit
                                    ? 'Received from ${sms.sender}'
                                    : 'Paid to ${sms.sender}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(sms.tag ?? 'Untagged',
                                  style: TextStyle(color: subTextColor, fontSize: 12)),
                              Text(time,
                                  style: TextStyle(color: subTextColor, fontSize: 10)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCredit ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (isCredit ? '+' : '-') +
                                '₹${sms.amount?.toStringAsFixed(2) ?? '0.00'}',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),

    );
  }
}
