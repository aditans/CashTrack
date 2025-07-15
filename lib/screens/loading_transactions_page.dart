import 'dart:convert';

import 'package:cashtrack/screens/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_telephony/telephony.dart' as telephony;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';


import '../models/sms_model.dart';
import '../services/sms_parser.dart';
import 'home_screen.dart';

class LoadingTransactionsPage extends StatefulWidget {
  const LoadingTransactionsPage({super.key});

  @override
  State<LoadingTransactionsPage> createState() => _LoadingTransactionsPageState();
}

class _LoadingTransactionsPageState extends State<LoadingTransactionsPage> {
  final telephony.Telephony telephonyInstance = telephony.Telephony.instance;
  int totalMessages = 0;
  int parsedMessages = 0;
  bool _skipped = false;

  @override
  void initState() {
    super.initState();
    _readInboxOnceWithProgress();
  }



  Future<void> _readInboxOnceWithProgress() async {
    final permissionGranted = await telephonyInstance
        .requestPhoneAndSmsPermissions;
    if (!(permissionGranted ?? false)) return;

    final smsBox = Hive.box<SmsModel>('smsBox');

    final messages = await telephonyInstance.getInboxSms(
      columns: [
        telephony.SmsColumn.ADDRESS,
        telephony.SmsColumn.BODY,
        telephony.SmsColumn.DATE
      ],
      sortOrder: [
        telephony.OrderBy(telephony.SmsColumn.DATE, sort: telephony.Sort.DESC)
      ],
    );

    setState(() => totalMessages = messages.length);

    for (final msg in messages) {
      if (_skipped) return;

      final parsed = parseSms(msg.body ?? '');
      if (parsed['amount'] == null || parsed['type'] == null) {
        setState(() => parsedMessages++);
        continue;
      }

      final timestamp = msg.date ?? 0;
      final keySender = parsed['name'] ?? msg.address ?? 'Unknown';
      ////
      //
      ////
      final exists = smsBox.values.any((s) =>
      s.sender == keySender &&
          s.body == msg.body &&
          s.receivedAt.millisecondsSinceEpoch == timestamp);
      if (!exists) {
        final sms = SmsModel(
          sender: keySender,
          body: msg.body ?? '',
          receivedAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
          amount: parsed['amount'],
          type: parsed['type'],
          tag:  parsed['tag'],
        );
        await smsBox.add(sms);
      }

      setState(() => parsedMessages++);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasReadInboxOnce', true);

    if (context.mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) =>  TransactionsBody()));
    }
  }

  void _skipAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasReadInboxOnce', true);

    setState(() => _skipped = true);

    if (context.mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) =>  TransactionsBody()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = totalMessages == 0 ? 0.0 : parsedMessages / totalMessages;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/transaction_loading.json',
              width: 200,
              repeat: true,
            ),
            const SizedBox(height: 20),
            const Text(
              'Reading Transaction SMSs...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            LinearProgressIndicator(value: percent),
            const SizedBox(height: 20),
            Text('$parsedMessages of $totalMessages messages scanned'),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
            const SizedBox(height: 40),
            TextButton(
              onPressed: _skipAndContinue,
              child: const Text(
                  'Skip', style: TextStyle(color: Colors.blue, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
