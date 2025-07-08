import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

import '../models/sms_model.dart';
import '../services/sms_parser.dart';
import 'transactions_page.dart';
import 'transaction_detail_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
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
    final Color robinsEggBlue = Color(0xFF00CCE7);
    final Color turquoiseBlue = Color(0xFF71E9E9);
    final Color shipGray = Color(0xFF424243);
    final Color regentGray = Color(0xFF949FA5);

    return Scaffold(
      backgroundColor: turquoiseBlue,
      appBar: AppBar(
        backgroundColor: turquoiseBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration:
              BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: Image.asset('assets/images/logo.jpg', fit: BoxFit.contain),
            ),
            const SizedBox(width: 8),
            const Text(
              'CASHTRACK',
              style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.menu, color: shipGray)),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.delete_forever, color: Colors.white),
            onPressed: () async {
              await Hive.box<SmsModel>('smsBox').clear();
              setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Account Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: shipGray,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Total Balance', style: TextStyle(color: Colors.white70)),
                      SizedBox(height: 4),
                      Text('₹10534.78',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('↗ Income',
                                    style: TextStyle(color: Colors.greenAccent)),
                                Text('₹13,200', style: TextStyle(color: Colors.white)),
                              ]),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('↘ Expenses',
                                    style: TextStyle(color: Colors.redAccent)),
                                Text('₹2,665.22',
                                    style: TextStyle(color: Colors.white)),
                              ]),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(children: [
                        Icon(Icons.account_balance, color: Colors.white),
                        SizedBox(width: 8),
                        Icon(Icons.credit_card, color: Colors.white),
                        Spacer(),
                        Icon(Icons.more_horiz, color: Colors.white),
                      ]),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Woah, slow down! You have spent 13.6% more than your limit this month.',
                            style: TextStyle(fontSize: 10, color: shipGray),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: Image.asset(
                            'assets/images/Left Peek Chippy.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Shortcuts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _ShortcutIcon(label: 'History', icon: Icons.history),
                _ShortcutIcon(label: 'Wallet', icon: Icons.account_balance_wallet),
                _ShortcutIcon(label: 'Generate', icon: Icons.qr_code),
                _ShortcutIcon(label: 'Accounts', icon: Icons.account_box),
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
                        MaterialPageRoute(builder: (_) => const TransactionsPage()),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Transactions',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: shipGray)),
                        Icon(Icons.chevron_right, color: shipGray),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder(
                    valueListenable: Hive.box<SmsModel>('smsBox').listenable(),
                    builder: (context, Box<SmsModel> box, _) {
                      final messages = box.values
                          .where((msg) => msg.type == 'transaction')
                          .toList()
                        ..sort(((a, b) => b.receivedAt.compareTo(a.receivedAt)));

                      if (messages.isEmpty) {
                        return const Text('No transactions yet');
                      }

                      final latest = messages.take(5).toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: latest.length,
                        itemBuilder: (context, i) {
                          final sms = latest[i];
                          final isCredit = sms.body.toLowerCase().contains('credited with');
                          final time = DateFormat('hh:mm a dd, MMM').format(sms.receivedAt);

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TransactionDetailPage(transaction: sms),
                                ),
                              );
                            },
                            child: _TransactionTile(
                              name: sms.sender,
                              tag: sms.type ?? 'Unknown',
                              amount: sms.amount ?? 0,
                              isCredit: isCredit,
                              time: time,
                              tagIcon: Icons.label,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF7A5AF8),
        child: Icon(Icons.add),
        onPressed: () {},
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: robinsEggBlue,
        unselectedItemColor: regentGray,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'SkillUp'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Transactions'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Splits'),
        ],
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
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(tagIcon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCredit ? 'Received from $name' : 'Paid to $name',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(tag, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(time, style: const TextStyle(color: Colors.white38, fontSize: 10)),
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
