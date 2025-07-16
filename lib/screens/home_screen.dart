import 'dart:async';

import 'package:another_telephony/telephony.dart' as telephony;
import 'package:cashtrack/screens/omni_model_screen.dart';
import 'package:cashtrack/screens/pdf_generation.dart';
import 'package:cashtrack/screens/set_balance_screen.dart';
import 'package:cashtrack/screens/skillup_page.dart';
import 'package:cashtrack/screens/transaction_detail_page.dart';
import 'package:cashtrack/screens/transactions_page.dart';
import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sms_advanced/sms_advanced.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/sms_model.dart';
import '../services/balance_service.dart';
import '../services/sms_parser.dart';
import 'expense_analysis_page.dart';
import 'manual_expense_page.dart';

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

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class Home extends StatefulWidget {
  //final WebViewController controller;

  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  late final WebViewController controller;
  bool isExpanded = false;

  final telephony.Telephony telephonyInstance = telephony.Telephony.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  DateTime? _lastSmsCheck;
  bool _isLoadingSms = false;
  Timer? _smsLoaderDebounce;
  final BalanceService _balanceService = BalanceService();
  double? _manualBalance;
  DateTime? _manualTimestamp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(android: androidInit),
    );
    //_readInboxOnce();
    _loadSmsIncrementally();
    _loadManualBalance();
  }
  Future<void> _loadManualBalance() async {
    final balance = await _balanceService.getManualBalance();
    final timestamp = await _balanceService.getManualBalanceTimestamp();
    setState(() {
      _manualBalance = balance;
      _manualTimestamp = timestamp;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _smsLoaderDebounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // _readInboxOnce();
      _debounceIncrementalSmsLoad();
    }
  }

  void _debounceIncrementalSmsLoad() {
    _smsLoaderDebounce?.cancel();
    _smsLoaderDebounce =
        Timer(const Duration(milliseconds: 700), _loadSmsIncrementally);
  }

  Future<void> _loadSmsIncrementally() async {
    if (_isLoadingSms) return;

    setState(() => _isLoadingSms = true);
    try {
      final permissionGranted =
          await telephonyInstance.requestPhoneAndSmsPermissions;
      if (!(permissionGranted ?? false)) return;

      if (!Hive.isBoxOpen('smsBox')) return;
      final smsBox = Hive.box<SmsModel>('smsBox');

      // Fast lookup: Set of keyStrings for already-known messages
      final Set<String> existingMessages = {
        for (final s in smsBox.values)
          '${s.sender ?? ''}_${s.body ?? ''}_${s.receivedAt.millisecondsSinceEpoch}'
      };

      // Find timestamp of latest saved SMS, to fetch only newer
      final latestTime = smsBox.values.isEmpty
          ? 0
          : smsBox.values
              .map((s) => s.receivedAt.millisecondsSinceEpoch)
              .reduce((a, b) => a > b ? a : b);

      // If your plugin supports filtering by date, use it.
      final messages = await telephonyInstance.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        // Only fetch new messages if possible.
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
        // TODO: If `getInboxSms` supports a date filter, use it:
        // filter: SmsFilter.where(SmsColumn.DATE).greaterThan(latestTime.toString()),
      );

      final List<SmsModel> newSmsList = [];
      for (final msg in messages) {
        final parsed = parseSms(msg.body ?? '');
        final timestamp = msg.date ?? 0;
        if (timestamp < latestTime)
          break; // Messages should be descending by date

        final keySender = parsed['name'] ?? msg.address ?? 'Unknown';
        final msgKey = '${keySender}_${msg.body}_${timestamp}';

        if (existingMessages.contains(msgKey)) continue;

        final sms = SmsModel(
          sender: keySender,
          body: msg.body ?? '',
          receivedAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
          amount: parsed['amount'],
          type: parsed['type'],
          tag: parsed['tag'],
        );

        newSmsList.add(sms);
        existingMessages.add(msgKey);
      }

      if (newSmsList.isNotEmpty) await smsBox.addAll(newSmsList);
      _lastSmsCheck = DateTime.now();
    } catch (e) {
      print('Error loading SMS: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSms = false);
    }
  }

  Future<void> _readInboxOnce() async {
    final permissionGranted =
        await telephonyInstance.requestPhoneAndSmsPermissions;
    if (!(permissionGranted ?? false)) return;

    final smsBox = Hive.box<SmsModel>('smsBox');
    final messages = await telephonyInstance.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    for (final msg in messages) {
      final parsed = parseSms(msg.body ?? '');
      final timestamp = msg.date ?? 0;
      final keySender = parsed['name'] ?? msg.address ?? 'Unknown';

      final exists = smsBox.values.any((s) =>
          s.sender == keySender &&
          s.body == msg.body &&
          s.receivedAt.millisecondsSinceEpoch == timestamp);

      if (exists) continue;

      final sms = SmsModel(
        sender: keySender,
        body: msg.body ?? '',
        receivedAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
        amount: parsed['amount'],
        type: parsed['type'],
        tag: parsed['tag'],
      );

      smsBox.add(sms);

      if (sms.type == 'credit' || sms.type == 'debit') {
        const androidDetails = AndroidNotificationDetails(
          'sms_channel',
          'SMS Notifications',
          channelDescription: 'Notification when SMS is received',
          importance: Importance.max,
          priority: Priority.high,
          playSound: false,
        );
        const notificationDetails =
            NotificationDetails(android: androidDetails);

        // await flutterLocalNotificationsPlugin.show(
        //   DateTime.now().millisecondsSinceEpoch ~/ 1000,
        //   'New transaction detected',
        //   '₹${sms.amount?.toStringAsFixed(2) ?? 'Amount'} from ${sms.sender}',
        //   notificationDetails,
        // );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color robinsEggBlue = Color(0xFF00CCE7);
    final Color turquoiseBlue = Color(0xFF71E9E9);
    final Color shipGray = Color(0xFF424243);
    final Color regentGray = Color(0xFF949FA5);
    return Stack(
      children: [
        ValueListenableBuilder(
            valueListenable: Hive.box<SmsModel>('smsBox').listenable(),
            builder: (context, Box<SmsModel> box, _) {
              // Compute dynamic totals on every change!
              final transactions = box.values
                  .where((msg) => msg.type == 'credit' || msg.type == 'debit')
                  .toList();

              double totalIncome = 0;
              double totalExpense = 0;
              for (final sms in transactions) {
                final amt = sms.amount ?? 0;
                if (sms.type == 'credit') {
                  totalIncome += amt;
                } else if (sms.type == 'debit') {
                  totalExpense += amt;
                }
              }final defaultBalance = totalIncome - totalExpense;
              double totalBalance;
              if (_manualBalance != null && _manualTimestamp != null) {
                double deltaCredit = 0, deltaDebit = 0;

                for (final sms in transactions) {
                  if (sms.receivedAt.isAfter(_manualTimestamp!)) {
                    final amt = sms.amount ?? 0;
                    if (sms.type == 'credit') deltaCredit += amt;
                    if (sms.type == 'debit') deltaDebit += amt;
                  }
                }

                totalBalance = _manualBalance! + deltaCredit - deltaDebit;
              } else {
                totalBalance = totalIncome - totalExpense;
              }

              // Recent transactions
              final messages = transactions
                ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
              final latest = messages.take(5).toList();
              final tagBox =
                  Hive.isBoxOpen('tagBox') ? Hive.box<Map>('tagBox') : null;

              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        // Account Summary Card
                        AspectRatio(
                          aspectRatio: 497 / 293,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/home_card.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Balance',
                                        style:
                                            TextStyle(color: Colors.white70)),
                                    const SizedBox(height: 4),
                                    Text(
                                      "₹${totalBalance.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('↗ Income',
                                                  style: TextStyle(
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      color: Colors.greenAccent,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13)),
                                              Text(
                                                  '₹${totalIncome.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      fontSize: 15)),
                                            ]),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('↘ Expenses',
                                                style: TextStyle(
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    color: Colors.redAccent,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13)),
                                            Text(
                                                '₹${totalExpense.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 15)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(children: [
                                      Icon(Icons.account_balance,
                                          color: Colors.white),
                                      SizedBox(width: 8),
                                      Icon(Icons.credit_card,
                                          color: Colors.white),
                                      SizedBox(width: 18),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white24),
                                        icon: const Icon(Icons.edit, color: Colors.white),
                                        label: const Text('Set Balance', style: TextStyle(color: Colors.white)),
                                        onPressed: () async {
                                          final result = await showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            useSafeArea: true,
                                            shape: const RoundedRectangleBorder(
                                                borderRadius: BorderRadius.vertical(top: Radius.circular(24))
                                            ),
                                            builder: (_) => const SetBalanceModal(),
                                          );
                                          if (result == true) _loadManualBalance();
                                        },
                                      ),

                                      Spacer(),
                                      Icon(Icons.more_horiz,
                                          color: Colors.white),
                                    ]),
                                  ],
                                ),
                                Positioned(
                                  right: 1,
                                  bottom: 50,
                                  width: MediaQuery.of(context).size.width/3,
                                  child: Column(

                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white70,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Woah, slow down! You have spent\n${(totalIncome + totalExpense) > 0 ? ((totalExpense / (totalIncome + totalExpense)) * 100).toStringAsFixed(1) : "0"}% more than your limit this month.',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: shipGray,
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: Image.asset(
                                          'assets/Left Peek Chippy.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Shortcuts
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ExpenseAnalysisPage(),
                                    ),
                                  );
                                },
                                child: const _ShortcutIcon(
                                    label: 'History', icon: Icons.history)),
                            const _ShortcutIcon(
                                label: 'Wallet',
                                icon: Icons.account_balance_wallet),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => PdfEmailPage()),
                                );
                              },
                              child: const _ShortcutIcon(
                                label: 'Generate',
                                icon: Icons.qr_code,
                              ),
                            ),
                            const _ShortcutIcon(
                                label: 'Accounts', icon: Icons.account_box),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Recent Transactions
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const TransactionsPage()),
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Recent Transactions',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: shipGray)),
                                    Icon(Icons.chevron_right, color: shipGray),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              latest.isEmpty
                                  ? const Text('No transactions yet')
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: latest.length,
                                      itemBuilder: (context, i) {
                                        final sms = latest[i];
                                        final isCredit = sms.type == 'credit';
                                        final time =
                                            DateFormat('hh:mm a dd, MMM')
                                                .format(sms.receivedAt);

                                        // Tag logic: custom tag icon or default
                                        IconData tagIconData =
                                            Icons.label_outline;
                                        if (tagBox != null && sms.tag != null) {
                                          final customTagIconCode = tagBox
                                              .get('customTags')?[sms.tag];
                                          if (customTagIconCode != null) {
                                            tagIconData = IconData(
                                                customTagIconCode,
                                                fontFamily: 'MaterialIcons');
                                          } else {
                                            tagIconData = tagIconMap[
                                                    sms.tag?.toLowerCase()] ??
                                                Icons.label_outline;
                                          }
                                        } else {
                                          tagIconData = tagIconMap[
                                                  sms.tag?.toLowerCase()] ??
                                              Icons.label_outline;
                                        }
                                        final tagLabel = sms.tag ?? 'Untagged';

                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    TransactionDetailPage(
                                                        transaction: sms),
                                              ),
                                            );
                                          },
                                          child: _TransactionTile(
                                            name: sms.sender,
                                            tag: tagLabel,
                                            amount: sms.amount ?? 0,
                                            isCredit: isCredit,
                                            time: time,
                                            tagIcon: tagIconData,
                                          ),
                                        );
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
        if (_isLoadingSms)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: const LinearProgressIndicator(),
          ),
      ],
    );
  }
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final Telephony telephony = Telephony.instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _readInboxOnce();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _readInboxOnce();
    }
  }

  Future<void> _readInboxOnce() async {
    final permissionGranted = await telephony.requestPhoneAndSmsPermissions;
    if (!(permissionGranted ?? false)) return;

    final smsBox = Hive.box<SmsModel>('smsBox');

    final messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    for (final msg in messages) {
      final parsed = parseSms(msg.body ?? '');
      final timestamp = msg.date ?? 0;

      final alreadyExists = smsBox.values.any((s) =>
          s.sender == (msg.address ?? 'Unknown') &&
          s.body == (msg.body ?? '') &&
          s.receivedAt.millisecondsSinceEpoch == timestamp);

      if (alreadyExists) continue;

      final sms = SmsModel(
        sender: msg.address ?? 'Unknown',
        body: msg.body ?? '',
        receivedAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
        amount: parsed['amount'],
        type: parsed['type'],
      );

      smsBox.add(sms);

      if (sms.type == 'transaction') {
        const androidDetails = AndroidNotificationDetails(
          'sms_channel',
          'SMS Notifications',
          channelDescription: 'Notification when SMS is received',
          importance: Importance.max,
          priority: Priority.high,
          playSound: false,
        );

        const notificationDetails =
            NotificationDetails(android: androidDetails);

        await flutterLocalNotificationsPlugin.show(
          0,
          'New transaction detected',
          '₹${sms.amount?.toStringAsFixed(2) ?? 'Amount'} from ${sms.sender}',
          notificationDetails,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final smsBox = Hive.box<SmsModel>('smsBox');

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              await smsBox.clear();
              setState(() {});
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: smsBox.listenable(),
        builder: (context, Box<SmsModel> box, _) {
          final messages = box.values.toList()
            ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

          if (messages.isEmpty) {
            return const Center(child: Text("No messages yet"));
          }

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (_, index) {
              final sms = messages[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(sms.sender),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sms.body),
                      const SizedBox(height: 4),
                      Text("Type: ${sms.type ?? 'Unknown'}"),
                    ],
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (sms.amount != null)
                        Text('₹${sms.amount!.toStringAsFixed(2)}'),
                      Text(
                          DateFormat('dd MMM, hh:mm a').format(sms.receivedAt)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ShortcutIcon extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ShortcutIcon({required this.label, required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(icon, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black)),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String name;
  final String tag;
  final double amount;
  final bool isCredit;
  final String time;
  final IconData tagIcon;
  final bool isSplit;

  const _TransactionTile({
    required this.name,
    required this.tag,
    required this.amount,
    required this.isCredit,
    required this.time,
    required this.tagIcon,
    this.isSplit = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        image: DecorationImage(
            image: Image.asset('assets/transcations_card.png').image,
            fit: BoxFit.cover),
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Color.fromRGBO(168, 168, 168, 0.20392156862745098),
            child: Icon(tagIcon, size: 18, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCredit ? 'Received from $name' : 'Paid to $name',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(tag,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(time,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          if (isSplit) Icon(Icons.call_split, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCredit ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              (isCredit ? '+' : '-') + '₹${amount.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
