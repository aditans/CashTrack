// expense_analysis_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/sms_model.dart';

const Map<String, IconData> categoryIcons = {
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

class ExpenseAnalysisPage extends StatefulWidget {
  const ExpenseAnalysisPage({super.key});

  @override
  State<ExpenseAnalysisPage> createState() => _ExpenseAnalysisPageState();
}

class _ExpenseAnalysisPageState extends State<ExpenseAnalysisPage> {
  int touchedIndex = -1;
  String selectedPeriod = 'This Month';
  DateTime? startDate;
  DateTime? endDate;

  final List<String> periods = [
    'This Week',
    'This Month',
    'Last Month',
    'Last 3 Months',
    'This Year',
    'Custom Range'
  ];

  @override
  void initState() {
    super.initState();
    _setDateRange();
  }

  void _setDateRange() {
    final now = DateTime.now();
    switch (selectedPeriod) {
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = now;
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = now;
        break;
      case 'Last Month':
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0);
        break;
      case 'Last 3 Months':
        startDate = DateTime(now.year, now.month - 3, 1);
        endDate = now;
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        endDate = now;
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
        endDate = now;
    }
  }

  // Calculate expense data by tags for the selected period
  Map<String, ExpenseData> _calculateExpenseByTag() {
    final smsBox = Hive.box<SmsModel>('smsBox');
    final Map<String, ExpenseData> expenseData = {};

    for (final sms in smsBox.values) {
      if (sms.type == 'debit' &&
          sms.amount != null &&
          sms.amount! > 0 &&
          (startDate == null || sms.receivedAt.isAfter(startDate!)) &&
          (endDate == null || sms.receivedAt.isBefore(endDate!.add(const Duration(days: 1))))) {

        final tag = (sms.tag?.toLowerCase() ?? 'others');

        if (expenseData.containsKey(tag)) {
          expenseData[tag]!.amount += sms.amount!;
          expenseData[tag]!.transactionCount++;
        } else {
          expenseData[tag] = ExpenseData(
            tag: tag,
            amount: sms.amount!,
            transactionCount: 1,
            icon: categoryIcons[tag] ?? Icons.category,
          );
        }
      }
    }

    return expenseData;
  }

  // Generate pie chart sections with enhanced visuals
  List<PieChartSectionData> _generatePieChartSections(Map<String, ExpenseData> data) {
    final colors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFFF44336), // Red
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFFE91E63), // Pink
      const Color(0xFF8BC34A), // Light Green
    ];

    final total = data.values.fold(0.0, (sum, value) => sum + value.amount);
    if (total == 0) return [];

    final sections = <PieChartSectionData>[];
    int colorIndex = 0;

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.amount.compareTo(a.value.amount));

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final percentage = (entry.value.amount / total) * 100;
      final isTouched = touchedIndex == i;
      final radius = isTouched ? 130.0 : 100.0;
      final fontSize = isTouched ? 16.0 : 12.0;

      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: entry.value.amount,
          title: percentage >= 5 ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
          badgeWidget: isTouched
              ? Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              entry.value.icon,
              size: 16,
              color: colors[colorIndex % colors.length],
            ),
          )
              : null,
        ),
      );

      colorIndex++;
    }

    return sections;
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        selectedPeriod = 'Custom Range';
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  final Color robinEggBlue = const Color(0xFF00CCE7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: robinEggBlue,
      appBar: AppBar(
        backgroundColor: robinEggBlue,
        elevation: 0,
        title: const Text(
          'Expense Analysis',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 26,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range, color: Colors.black),
            onSelected: (value) {
              setState(() {
                selectedPeriod = value;
                if (value == 'Custom Range') {
                  _selectCustomDateRange();
                } else {
                  _setDateRange();
                }
              });
            },
            itemBuilder: (context) => periods.map((period) {
              return PopupMenuItem(
                value: period,
                child: Text(period),
              );
            }).toList(),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<SmsModel>('smsBox').listenable(),
        builder: (context, Box<SmsModel> box, _) {
          final expenseData = _calculateExpenseByTag();

          if (expenseData.isEmpty) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No expense data available',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                    Text(
                      'for the selected period',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          final total = expenseData.values.fold(0.0, (sum, value) => sum + value.amount);
          final transactionCount = expenseData.values.fold(0, (sum, value) => sum + value.transactionCount);

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period and totals header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE3F9FD), Color(0xFFB2F9FC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedPeriod,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0277BD),
                              ),
                            ),
                            Text(
                              '$transactionCount transactions',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF0277BD),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Expenses',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0277BD),
                              ),
                            ),
                            Text(
                              '₹${NumberFormat('#,##,###.##').format(total)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),

                  const SizedBox(height: 16),




                  // Interactive Pie Chart
                  Container(
                    height: 350,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 3,
                        centerSpaceRadius: 60,
                        sections: _generatePieChartSections(expenseData),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Category breakdown header
                  const Text(
                    'Category Breakdown',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Enhanced Legend with transaction details
                  ...expenseData.entries.map((entry) {
                    final colors = [
                      const Color(0xFF2196F3), const Color(0xFFF44336),
                      const Color(0xFF4CAF50), const Color(0xFFFF9800),
                      const Color(0xFF9C27B0), const Color(0xFF00BCD4),
                      const Color(0xFF795548), const Color(0xFF607D8B),
                      const Color(0xFFE91E63), const Color(0xFF8BC34A),
                    ];

                    final index = expenseData.keys.toList().indexOf(entry.key);
                    final percentage = (entry.value.amount / total) * 100;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              touchedIndex = index;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: touchedIndex == index
                                  ? colors[index % colors.length].withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: touchedIndex == index
                                    ? colors[index % colors.length]
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: colors[index % colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    entry.value.icon,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key.toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        '${entry.value.transactionCount} transactions',
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${NumberFormat('#,##,###.##').format(entry.value.amount)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      '${percentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: colors[index % colors.length],
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Helper class for expense data
class ExpenseData {
  final String tag;
  double amount;
  int transactionCount;
  final IconData icon;

  ExpenseData({
    required this.tag,
    required this.amount,
    required this.transactionCount,
    required this.icon,
  });
}
