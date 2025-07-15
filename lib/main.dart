import 'dart:async';
import 'dart:convert';

import 'package:another_telephony/telephony.dart' as telephony;
import 'package:cashtrack/screens/loading_transactions_page.dart';
import 'package:cashtrack/screens/transactions_screen.dart';
import 'package:cashtrack/services/permissions.dart';
import 'package:easy_sms_receiver/easy_sms_receiver.dart' as easy;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:another_telephony/telephony.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'models/friend_model.dart';
import 'models/group_model.dart';
import 'models/individual_chat_model.dart';
import 'models/split_model.dart';
import 'models/sms_model.dart';
import 'services/sms_parser.dart';
import 'screens/signin_screen.dart';
import 'screens/home_screen.dart';

final _notifPlugin = FlutterLocalNotificationsPlugin();
final easySmsReceiver = easy.EasySmsReceiver.instance;


@pragma('vm:entry-point')
Future<void> _backgroundSmsHandler(SmsMessage msg) async {
  await Hive.initFlutter();
  Hive.registerAdapter(SmsModelAdapter());
  //await Hive.openBox<String>('tagBox');
  final smsBox = Hive.box<SmsModel>('smsBox');

  final parsed = parseSms(msg.body ?? '');

  final sms = SmsModel(
    sender: msg.address ?? 'Unknown',
    body: msg.body ?? '',
    receivedAt: DateTime.now(),
    amount: parsed['amount'],
    type: parsed['type'],
    tag: parsed['tag'],
  );
  await smsBox.add(sms);



 //notification
  const androidDetails = AndroidNotificationDetails(
    'sms_channel', 'SMS Notifications',
    channelDescription: 'Background SMS',
    importance: Importance.max,
    priority: Priority.high,
  );
  await _notifPlugin.show(
    msg.hashCode,
    'New SMS from ${sms.sender}',
    sms.body,
    NotificationDetails(android: androidDetails),
  );



}

Future<Map<String, String>>  fetchTagForSender(List<String> senders) async {
  try {

    Map<String, dynamic> data = {
      "From": "",
      "secret_key":"83ff2da7b5278d22ab0f4998591c2989",
      "unique_session_id":"27bdbd63-4cd1-4d83-afea-9b1d4d983cff", //"802d5f2a-6d54-40a5-932b-e98924b96e1c" "db60b026-8728-4408-9ec1-43a76e4c19a4" "b4a75ba6-12d3-4afa-bb28-45fce007ecb1"
      "user_message":senders.toString(),
    };
    print(senders.toString());
    String jsonBody = json.encode(data);

    final response = await http.post(
      Uri.parse('https://www.omnidim.io/chat/start_chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonBody,
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = json.decode(response.body);
      debugPrint('\n=======================================\n');
      debugPrint('Tags: ${decoded['cycle_data']['content']}');
      Map<String, dynamic>? tagSection;
      if (decoded['cycle_data'] != null && decoded['cycle_data']['content'] != null) {
        Map<String, dynamic> content = json.decode(decoded['cycle_data']?['content']);
        if (content is Map<String, dynamic>) {
          tagSection = content;
        } else if (content is Map) {
          tagSection = Map<String, dynamic>.from(content);
        } else if (decoded['response'] != null) {
          tagSection = decoded['response'];
        }

      } else if (decoded['response'] != null) {
        tagSection = decoded['response'];
      }
      //debugPrint('Tags: ${decoded}');
      if (tagSection != null) {
        // Make sure tagSection is Map<String, dynamic>
        return tagSection.map((k, v) => MapEntry(k, v.toString()));
      }

    }
  } catch (e) {
    debugPrint('Tag fetch failed for ${senders.toString()}: $e');
  }
  return {for (var s in senders) s: 'Untagged'};
}
Future<void> _tagUntaggedSendersInBackground() async {
  print("Starting _tagUntaggedSendersInBackground...");
  final smsBox =  Hive.box<SmsModel>('smsBox');
  print("smsBox has ${smsBox.length} SMSs");
  final tagBox = Hive.box<Map>('tagBox');

  //Box<String> tagBox;
  //final tagBox = await Hive.openBox<String>('tagBox');

  // if (Hive.isBoxOpen('tagBox')) {
  //   // tagBox = Hive.box<String>('tagBox');
  // } else {
  //   // tagBox = await Hive.openBox<String>('tagBox');
  // }


  final smsList = smsBox.values.toList();
  final untaggedSenders = smsBox.values
      .where((sms) => sms.tag == null || sms.tag == 'Untagged')
      .map((sms) => sms.sender)
      .toSet()
      .toList();
  print("smsBox has ${untaggedSenders} ${smsList}");
  final Set<String> processedSenders = {};

  for (var i = 0; i < untaggedSenders.length; i += 15) {
    final batch = untaggedSenders.skip(i).take(15).toList();

    final tagMap = await fetchTagForSender(batch);

    // Update Hive with the new tags
    for (final sender in batch) {
      final tag = tagMap[sender] ?? 'Untagged';
      tagBox.put(sender, {"tag":tag});
      // Optionally, update the tag in each SMS as well
      for (final sms in smsBox.values.where((sms) => sms.sender == sender)) {
        smsBox.put(sms.key, sms.copyWith(tag: tag));
      }
    }
    if (i + 15 < untaggedSenders.length) {
      await Future.delayed(Duration(seconds: 30));
    }
  }
}

class TaggingService {
  static final TaggingService _instance = TaggingService._internal();
  factory TaggingService() => _instance;
  TaggingService._internal();

  Timer? _timer;

  void start() {

      _tagUntaggedSendersInBackground();

  }


  void stop() {
    _timer?.cancel();
    _timer = null;
  }

// ...add your tagging logic here...
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Hive init
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  Hive.registerAdapter(SmsModelAdapter());
  Hive.registerAdapter(FriendModelAdapter());
  Hive.registerAdapter(GroupModelAdapter());
  Hive.registerAdapter(IndividualChatModelAdapter());
  Hive.registerAdapter(SplitModelAdapter());
  await Hive.openBox<SmsModel>('smsBox');
  print("=================== sms box has ${Hive.box<SmsModel>('smsBox').length} ==================");
  await Hive.openBox<Map>('tagBox'); // For custom tags
  //final tagBox = Hive.box<String>('tagBox');
  // Notifications init
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _notifPlugin.initialize(InitializationSettings(android: androidInit));

  // SMS listener
  final telephonyInstance = telephony.Telephony.instance;
  final telephonyGranted = await telephonyInstance.requestPhoneAndSmsPermissions;
  if (telephonyGranted == true) {
    telephonyInstance.listenIncomingSms(
      onNewMessage: (_) {},
      onBackgroundMessage: _backgroundSmsHandler,
    );
  }
  Future<Map<String, String>>  fetchTagForSender(List<String> senders) async {
    try {

      Map<String, dynamic> data = {
        "From": "",
        "secret_key":"83ff2da7b5278d22ab0f4998591c2989",
        "unique_session_id":"27bdbd63-4cd1-4d83-afea-9b1d4d983cff", //"802d5f2a-6d54-40a5-932b-e98924b96e1c" "db60b026-8728-4408-9ec1-43a76e4c19a4" "b4a75ba6-12d3-4afa-bb28-45fce007ecb1"
        "user_message":senders.toString(),
      };
      print(senders.toString());
      String jsonBody = json.encode(data);

      final response = await http.post(
        Uri.parse('https://www.omnidim.io/chat/start_chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonBody,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);
        debugPrint('\n=======================================\n');
        debugPrint('Tags: ${decoded['cycle_data']['content']}');
        Map<String, dynamic>? tagSection;
        if (decoded['cycle_data'] != null && decoded['cycle_data']['content'] != null) {
          Map<String, dynamic> content = json.decode(decoded['cycle_data']?['content']);
          if (content is Map<String, dynamic>) {
            tagSection = content;
          } else if (content is Map) {
            tagSection = Map<String, dynamic>.from(content);
          } else if (decoded['response'] != null) {
            tagSection = decoded['response'];
          }

        } else if (decoded['response'] != null) {
          tagSection = decoded['response'];
        }
        //debugPrint('Tags: ${decoded}');
        if (tagSection != null) {
          // Make sure tagSection is Map<String, dynamic>
          return tagSection.map((k, v) => MapEntry(k, v.toString()));
        }

      }
    } catch (e) {
      debugPrint('Tag fetch failed for ${senders.toString()}: $e');
    }
    return {for (var s in senders) s: 'Untagged'};
  }
  Future<void> _ONEtagUntaggedSendersInBackground() async {
    print("Starting _tagUntaggedSendersInBackground...");
    final smsBox = Hive.box<SmsModel>('smsBox');
    print("smsBox has ${smsBox.length} SMSs");
    final tagBox = Hive.box<Map>('tagBox');

    //Box<String> tagBox;
    //final tagBox = await Hive.openBox<String>('tagBox');

    // if (Hive.isBoxOpen('tagBox')) {
    //   // tagBox = Hive.box<String>('tagBox');
    // } else {
    //   // tagBox = await Hive.openBox<String>('tagBox');
    // }


    final smsList = smsBox.values.toList();
    final untaggedSenders = smsBox.values
        .where((sms) => sms.tag == null || sms.tag == 'Untagged')
        .map((sms) => sms.sender)
        .toSet()
        .toList();
    print("smsBox has ${untaggedSenders.length} ${smsList.length}");
    final Set<String> processedSenders = {};


      final batch = untaggedSenders.take(1).toList();
      final tagMap = await fetchTagForSender(batch);

      // Update Hive with the new tags
      for (final sender in batch) {
        final tag = tagMap[sender] ?? 'Untagged';
        tagBox.put(sender, {"tag":tag});
        // Optionally, update the tag in each SMS as well
        for (final sms in smsBox.values.where((sms) => sms.sender == sender)) {
          smsBox.put(sms.key, sms.copyWith(tag: tag));
        }
      }

  }

  final foregroundGranted = await requestSmsAndNotificationPermissions();
  if (foregroundGranted) {
    easySmsReceiver.listenIncomingSms(
      onNewMessage: (easy.SmsMessage msg) async {
        final parsed = parseSms(msg.body ?? '');
        final sms = SmsModel(
          sender: parsed['name'] ?? msg.address ?? 'Unknown',
          body: msg.body ?? '',
          receivedAt: DateTime.now(),
          amount: parsed['amount'],
          type: parsed['type'],
          tag: parsed['tag'],
        );
        Hive.box<SmsModel>('smsBox').add(sms);

        //REMOVE THIS

        //notification
        const androidDetails = AndroidNotificationDetails(
          'sms_channel',
          'SMS Notifications',
          channelDescription: 'Foreground SMS',
          importance: Importance.max,
          priority: Priority.high,
        );
        await _notifPlugin.show(
          msg.hashCode,
          'New SMS from ${sms.sender}',
          sms.body,
          NotificationDetails(android: androidDetails),
        );
        _ONEtagUntaggedSendersInBackground();
      },
    );
  }




  //TaggingService().start();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoadingPage(),
    );
  }
}

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[100],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 200),
              Text(
                'CashTrack',
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 40),
                child: Image.asset(
                  'assets/chippy.png',
                  height: 250,
                ),
              ),
              const SizedBox(height: 30),
              const SpinKitFadingCircle(
                color: Color(0xFF00CCE7),
                size: 60.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  Future<bool> hasReadInbox() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasReadInboxOnce') ?? false;
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: hasReadInbox(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (ctx, userSnap) {
            if (userSnap.connectionState != ConnectionState.active) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (userSnap.data == null) {
              return const SignInScreen();
            }

            return snap.data == false
                ? const LoadingTransactionsPage()
                : TransactionsBody();
          },
        );
      },
    );
  }
}


// return snap.data == null
// ?  LoadingTransactionsPage()
//     : TransactionsBody();