import 'dart:async';
import 'dart:convert';


import 'package:cashtrack/screens/home_screen.dart';
import 'package:cashtrack/screens/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cashtrack/screens/skillup_page.dart';
import 'package:cashtrack/screens/splits_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:icons_plus/icons_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/sms_model.dart';
import 'chippy_chat_bot_screen.dart';
import 'manual_expense_page.dart';

int current_index=0
;

//List<Widget> pages=[Home(),SkillUp(),Transaction(),Splits()];

class TransactionsBody extends StatefulWidget {
  const TransactionsBody({super.key});

  @override
  State<TransactionsBody> createState() => _TransactionsBodyState();
}

class _TransactionsBodyState extends State<TransactionsBody> {
  late final WebViewController _controller;

  final String htmlData = '''
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="UTF-8">
    <style>
      html, body {
        background: transparent !important;
        margin: 0;
        padding: 0;
      }
      
    </style>
  </head>
  <body>
    <script id="omnidimension-web-widget" async
      src="https://backend.omnidim.io/web_widget.js?secret_key=6d4617ad886cdea88b20f17d2238ef0d">
    </script>
    <script>
      // Reinforce transparency after widget loads
     
    </script>
  </body>
  </html>
''';




  Timer? _taggingTimer;

  @override
  void initState() {
    super.initState();
    final smsBox = Hive.box<SmsModel>('smsBox');




    _taggingTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _tagUntaggedSendersInBackground();
    });
    _controller = WebViewController()

      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) => debugPrint("Page started: $url"),
        onPageFinished: (url) => debugPrint("Page finished: $url"),
      ))
      ..loadRequest(Uri.dataFromString(
        htmlData,
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8'),
      ));

  }
  Future<void> _tagUntaggedSendersInBackground() async {
    print("Starting _tagUntaggedSendersInBackground...");
    final smsBox = await Hive.openBox<SmsModel>('smsBox');
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
    }
  }



  Future<Map<String, String>>  fetchTagForSender(List<String> senders) async {
    try {

      Map<String, dynamic> data = {
        "From": "",
        "secret_key":"83ff2da7b5278d22ab0f4998591c2989",
        "unique_session_id":"039ea214-6823-47d4-a297-08e94f651d54",
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

  bool isExpanded = false;
  @override
  Widget build(BuildContext context) {
    final Color robinsEggBlue = Color(0xFF00CCE7);
    final Color turquoiseBlue = Color(0xFF71E9E9);
    final Color shipGray = Color(0xFF424243);
    final Color regentGray = Color(0xFF949FA5);
    final deviceWidth = MediaQuery.of(context).size.width;



// Calculate width and height based on isExpanded
    var width = 200.0;
    var height = 100.0;
    List<Widget> pages = [
      Home(controller: _controller),
      SkillUp(),
      ChatBody(),
      SplitsBody(),
    ];
    User? user = FirebaseAuth.instance.currentUser;
    String? photoUrl = user?.photoURL;
    return Scaffold(
      appBar:  AppBar(
        backgroundColor: turquoiseBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
                width: 45,
                height: 45,
              ),
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
              radius: 30,
              backgroundColor: Colors.white,
              backgroundImage: photoUrl != null
                  ? NetworkImage(photoUrl)
                  : AssetImage('assets/logo.png') as ImageProvider,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(),
                ),
              );
            },
          ),
        ],

      ),
      body:Stack(
        children: [
          // Background image

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(255, 255, 255, 0.0), // Start color with opacity
                  Color.fromRGBO(
                    183, 208, 227, 1.0,  ),           // End color (transparent)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Your content goes here
          // ...
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          IndexedStack(
            index: current_index,
            children: pages,
          )
        ],
      ),




      bottomNavigationBar: FractionallySizedBox(


        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          unselectedItemColor: Color.fromRGBO(48, 65, 76, 1.0),
          selectedItemColor: Color.fromRGBO(0, 184, 217, 1.0),
          showUnselectedLabels: true,
          iconSize: 30,
          onTap: (index) {setState(() {
            current_index=index;
          });},
          selectedLabelStyle: TextStyle(fontSize: 13,fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 13),
          currentIndex: current_index,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
              backgroundColor: Colors.white,
              activeIcon: Icon(Icons.home),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              label: 'SkillUp',
              backgroundColor: Colors.white,
              activeIcon: Icon(Icons.school),
            ),
            BottomNavigationBarItem(
              icon: Icon(BoxIcons.bx_chat),
              label: 'Chippy',
              backgroundColor: Colors.white,
              activeIcon: Icon(BoxIcons.bxs_chat),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              backgroundColor: Colors.white,
              activeIcon: Icon(Icons.groups),
              label: 'Splits',
            ),
          ],
        ),
      ),

      floatingActionButton: current_index == 0
          ? FloatingActionButton(
        backgroundColor: Color(0xFF7A5AF8),
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManualExpensePage()),
          );
        },
      )
          : null,

    );
  }
}


