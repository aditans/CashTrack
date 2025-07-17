import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:typewritertext/typewritertext.dart';

import '../models/sms_model.dart';

String chippy = "27f006a4-8dac-475f-89f7-b95dcb2a6c31";
class ChatBody extends StatefulWidget {
  const ChatBody({Key? key}) : super(key: key);

  @override
  _ChatBodyState createState() => _ChatBodyState();
}

class ChatMessage {
  final String text;
  final DateTime timestamp;
  final bool isUser;

  ChatMessage(
      {required this.text, required this.timestamp, required this.isUser});
}

class _ChatBodyState extends State<ChatBody> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _getInitialGreeting();
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


    final batch = untaggedSenders.take(10).toList();
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



  Future<Map<String, String>>  fetchTagForSender(List<String> senders) async {
    try {

      Map<String, dynamic> data = {
        "From": "",
        "secret_key":"83ff2da7b5278d22ab0f4998591c2989",
        "unique_session_id":"4b6bb5d9-4157-4d78-bee4-c799d47a770e", //"802d5f2a-6d54-40a5-932b-e98924b96e1c" "db60b026-8728-4408-9ec1-43a76e4c19a4" "b4a75ba6-12d3-4afa-bb28-45fce007ecb1"
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
          tagSection = content;

        } else if (decoded['response'] != null) {
          tagSection = decoded['response'];
        }
        //debugPrint('Tags: ${decoded}');
        if (tagSection != null) {

          return tagSection.map((k, v) => MapEntry(k, v.toString()));
        }

      }
    } catch (e) {
      debugPrint('Tag fetch failed for ${senders.toString()}: $e');
    }
    return {for (var s in senders) s: 'Untagged'};
  }
  final List<String> filterTypes = ['Month', 'Year', 'Day','Custom'];
  String selectedFilter = 'Month';

  Future<void> _getInitialGreeting() async {

    String aiReply = await sendJsonData("","6d4617ad886cdea88b20f17d2238ef0d",chippy);
    setState(() {
      _messages.add(ChatMessage(
        text: aiReply,
        timestamp: DateTime.now(),
        isUser: false, // AI message
      ));
    });
  }

  String? _pendingAnalysisSelection;

  DateTime? startDate;
  DateTime? endDate;
  String? customDateDisplay;




  void _showAnalysisModal() async {
    final result = await showModalBottomSheet<String>(

      context: context,
      builder: (context) {
        final currentYear = DateTime.now().year;
        final months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        final years = List<String>.generate(10, (index) => (currentYear - index).toString());
        String selected = 'This Week';
        String? selectedMonth = months[DateTime.now().month-1];
        String? selectedYear = years[0];
        DateTime? startDate;
        DateTime? endDate;




        print(years);
        return StatefulBuilder(

          builder: (context, setModalState) {

            if (selected == 'Monthly') {
              selectedMonth ??= months[DateTime.now().month - 1];
              selectedYear ??= years[0];
            }
            if (selected == 'Yearly') {
              selectedYear ??= years[0];
            }


            return Padding(

              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: MediaQuery.of(context).size.width,
                child: Column(


                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Analysis Duration to attach', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(height: 16),
                    DropdownButton<String>(
                      value: selected,
                      items: ['This Week', 'Monthly', 'Yearly', 'Custom']
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (val) {
                        setModalState(() {
                          selected = val!;
                          selectedMonth = null;
                          selectedYear = null;
                        });
                      },
                    ),
                    SizedBox(height: 16),

                    SizedBox(height: 16),
                    if (selected == 'Monthly') ...[
                      Text('Select Month'),
                      DropdownButton<String>(
                        value: selectedMonth ?? months[DateTime.now().month - 1],
                        items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (val) => setModalState(() => selectedMonth = val),
                      ),
                      SizedBox(height: 16),
                      Text('Select Year'),
                      DropdownButton<String>(
                        value: selectedYear ?? years[0],
                        items: years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                        onChanged: (val) => setModalState(() => selectedYear = val),
                      ),
                    ]
                    else if (selected == 'Custom') ...[
                      Text('Select Date Range'),
                      ElevatedButton(
                        onPressed: () async { final DateTimeRange? picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          initialDateRange: startDate != null && endDate != null
                              ? DateTimeRange(start: startDate!, end: endDate!)
                              : DateTimeRange(
                            start: DateTime.now().subtract(const Duration(days: 6)),
                            end: DateTime.now(),
                          ),
                        );
                        if (picked != null) {
                          setModalState(() {
                            startDate = picked.start;
                            endDate = picked.end;
                            customDateDisplay = "${picked.start.toIso8601String().substring(0, 10)} to ${picked.end.toIso8601String().substring(0, 10)}";
                          });
                        }
                        },
                        child: Text(customDateDisplay ?? 'Pick a date range'),                      ),
                    ]

                    else if (selected == 'Yearly') ...[
                      Text('Select Year'),
                      DropdownButton<String>(
                        value: selectedYear ?? years[0],
                        items: years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                        onChanged: (val) => setModalState(() => selectedYear = val),
                      ),
                    ],
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        String result = selected;
                        if (selected == 'Monthly' && selectedMonth != null && selectedYear != null) {
                          result += '|$selectedMonth|$selectedYear';
                        } else if (selected == 'Yearly' && selectedYear != null) {
                          result += '|$selectedYear';
                        } else if (selected == 'Custom' && selectedMonth != null) {
                          result += '|${startDate?.toIso8601String().substring(0, 10)}|${endDate?.toIso8601String().substring(0, 10)}'; // Here, selectedMonth holds the custom date string
                        }
                        setState(() {
                          _pendingAnalysisSelection = result;
                          print(result);
                        });
                        Navigator.pop(context);
                      },

                      child: Text('Attach Analysis'),
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


  Map<String, dynamic>? extractPostJson(String aiReply, {String marker = "!POST//"}) {
    if (aiReply.contains(marker)) {
      final RegExp regExp = RegExp(r'\{([^}]*)\}');
      final parts = aiReply.split(marker);
      final cleanedMessage = parts[0].trim();
      final match = regExp.firstMatch(parts[1].trim());

      if (match != null) {
        // match.group(0): with braces, match.group(1): inside only
        final jsonStr = '{${match.group(1)}}'; // Add braces back for valid JSON
        try {
          final jsonData = json.decode(jsonStr);
          return {
            'message': cleanedMessage,
            'json': jsonData,
          };
        } catch (e) {
          print("ERRRRRRR JSON DECODE ERROR: ${e.toString()}");
          return {
            'message': aiReply,
            'json': null,
          };
        }
      }
    }
    return {
      'message': aiReply,
      'json': null,
    };
  }

  Future<String> _generateAnalysis(String selection) async {
    final smsBox = Hive.box<SmsModel>('smsBox');


    final smsList = smsBox.values.toList().where((sms) => sms.type == 'debit').toList();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    StringBuffer analysis = StringBuffer();

    if (selection.startsWith('This Week')) {
      // Get current week range
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(Duration(days: 6));
      Map<String, double> tagTotals = {};
      for (var sms in smsList) {
        if (sms.amount != null &&
            sms.receivedAt.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
            sms.receivedAt.isBefore(endOfWeek.add(const Duration(days: 1)))) {
          if (sms.tag != null && sms.tag != 'Untagged') {
            tagTotals[sms.tag!] = (tagTotals[sms.tag!] ?? 0) + sms.amount!;
          }
        }
      }
      analysis.writeln("!POST//This Week's Tag Breakdown:");
      tagTotals.forEach((tag, total) => analysis.writeln("$tag: ₹${total.toStringAsFixed(2)}"));
    } else if (selection.startsWith('Monthly')) {
      final parts = selection.split('|');
      if (parts.length >= 3) {
        final monthName = parts[1];
        final yearStr = parts[2];
        final monthIndex = months.indexOf(monthName) + 1;
        final year = int.tryParse(yearStr) ?? DateTime.now().year;
        Map<String, double> tagTotals = {};
        for (var sms in smsList) {
          if (sms.amount != null &&
              sms.receivedAt.year == year &&
              sms.receivedAt.month == monthIndex) {
            if (sms.tag != null && sms.tag != 'Untagged') {
              tagTotals[sms.tag!] = (tagTotals[sms.tag!] ?? 0) + sms.amount!;
            }
          }
        }
        analysis.writeln("!POST//Monthly Tag Breakdown for $monthName $year:");
        tagTotals.forEach((tag, total) => analysis.writeln("$tag: ₹${total.toStringAsFixed(2)}"));
      }
    } else if (selection.startsWith('Yearly')) {
      final parts = selection.split('|');
      if (parts.length >= 2) {
        final yearStr = parts[1];
        final year = int.tryParse(yearStr) ?? DateTime.now().year;
        Map<String, double> tagTotals = {};
        for (var sms in smsList) {
          if (sms.amount != null && sms.receivedAt.year == year) {
            if (sms.tag != null && sms.tag != 'Untagged') {
              tagTotals[sms.tag!] = (tagTotals[sms.tag!] ?? 0) + sms.amount!;
            }
          }
        }
        analysis.writeln("!POST//Yearly Tag Breakdown for $year:");
        tagTotals.forEach((tag, total) => analysis.writeln("$tag: ₹${total.toStringAsFixed(2)}"));
      }
    } else if (selection.startsWith('Custom')) {
      // Format: 'Custom|YYYY-MM-DD|YYYY-MM-DD'
      final parts = selection.split('|');
      if (parts.length >= 3) {
        final startStr = parts[1];
        final endStr = parts[2];
        final start = DateTime.tryParse(startStr);
        final end = DateTime.tryParse(endStr);
        if (start != null && end != null) {
          Map<String, double> tagTotals = {};
          for (var sms in smsList) {
            if (sms.amount != null &&
                !sms.receivedAt.isBefore(start) &&
                !sms.receivedAt.isAfter(end)) {
              if (sms.tag != null && sms.tag != 'Untagged') {
                tagTotals[sms.tag!] = (tagTotals[sms.tag!] ?? 0) + sms.amount!;
              }
            }
          }
          analysis.writeln("!POST//Custom Tag Breakdown for $startStr to $endStr:");
          tagTotals.forEach((tag, total) => analysis.writeln("$tag: ₹${total.toStringAsFixed(2)}"));
        }
      }
    }
    print(analysis.toString());

    return analysis.toString();
  }



  Future<void> _sendMessage(String secret_key,String session) async {
    String userInput = _controller.text.trim();
    if (_controller.text.trim().isEmpty) return;

    String combinedMessage = userInput;
    if (_pendingAnalysisSelection != null) {
      final analysis = await _generateAnalysis(_pendingAnalysisSelection!);
      if (analysis.isNotEmpty) {
        combinedMessage += "\n\n$analysis";
      }
      _pendingAnalysisSelection = null;
    }


    final analysisStart = userInput.indexOf("!POST//");
    String visibleMessage = combinedMessage;
    if (analysisStart != -1) {
      visibleMessage = userInput.substring(0, analysisStart).trim();
    }


    setState(() {
      _messages.add(ChatMessage(
        text: userInput,
        timestamp: DateTime.now(),
        isUser: true,
      ));
      _controller.clear();
      _isTyping = true;
    });
    String aiReply = await sendJsonData(combinedMessage,secret_key,session);
    print("aiReply========="+aiReply);
    Map<String, dynamic>? result = extractPostJson(aiReply);
    final cleanedMessage = result?['message'];
    final jsonData = result?['json'];
    print(result.toString());
    try{
      void printLongString(String text) {
        const int chunkSize = 800;
        for (var i = 0; i < text.length; i += chunkSize) {
          print(text.substring(i, i + chunkSize > text.length ? text.length : i + chunkSize));
        }
      }

      printLongString(cleanedMessage + "=========" + jsonData.toString());

    }
    catch(e)
    {

    }

    if (jsonData != null) {
      final smsBox =  Hive.box<SmsModel>('smsBox');
      final smsList = smsBox.values.toList();
      print("smsBox has  ${smsList}");

      smsBox.add(
        SmsModel(
          sender: jsonData['sender'] ?? '',
          body: "Added By ChatBot:$jsonData", // or jsonData['body'] if provided
          receivedAt: DateTime.parse(jsonData['receivedAt']),
          amount: (jsonData['amount'] is int)
              ? (jsonData['amount'] as int).toDouble()
              : (jsonData['amount'] as num?)?.toDouble(),
          type: jsonData['type'],
          tag: null,

        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction added successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      _ONEtagUntaggedSendersInBackground();

    }

    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(
        text: cleanedMessage,
        timestamp: DateTime.now(),
        isUser: false,
      ));
    });
    _controller.clear();
  }
  //final bitch=null;

  Future<String> sendJsonData(String userInput,String secret_key,String session) async {
    // Your data as a Dart map
    Map<String, dynamic> data = {
      "From": "",
      "user_message": userInput,
    "unique_session_id":session

      ,
      "secret_key":secret_key //fb1d9464ec4c1764190725ab860e2a52            //6d4617ad886cdea88b20f17d2238ef0d
    };

    // Convert Dart map to JSON string
    String jsonBody = json.encode(data);

    // Send POST request with JSON body
    final response = await http.post(
      Uri.parse('https://www.omnidim.io/chat/start_chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonBody,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = json.decode(response.body);
      return decoded['response'];
    } else {
      return 'Failed to get response from Chippy.';
    }
  }

  bool _isTyping = false;
  String getWeekString(DateTime date) {
    // Week number calculation based on ISO 8601
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - 1;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));
    final diff = date.difference(firstMonday).inDays;
    final weekNumber = (diff / 7).ceil();
    return "${date.year}-W$weekNumber";
  }


  Future<void> _attachAnalysisToInput() async {
    String userInput = _controller.text.trim();
    if (userInput.isEmpty) return; // Only proceed if input is not empty

    final smsBox =  Hive.box<SmsModel>('smsBox');
    final smsList = smsBox.values.toList();

    Map<String, double> weeklyTotals = {};
    Map<String, double> tagTotals = {};

    for (var sms in smsList) {
      if (sms.amount != null) {
        final week = getWeekString(sms.receivedAt);
        weeklyTotals[week] = (weeklyTotals[week] ?? 0) + sms.amount!;
        if (sms.tag != null && sms.tag != 'Untagged') {
          tagTotals[sms.tag!] = (tagTotals[sms.tag!] ?? 0) + sms.amount!;
        }
      }
    }

    StringBuffer analysis = StringBuffer();
    analysis.writeln("!POST//Weekly Spend:");
    weeklyTotals.forEach((week, total) => analysis.writeln("$week: ₹${total.toStringAsFixed(2)}"));
    analysis.writeln("Tag Breakdown:");
    tagTotals.forEach((tag, total) => analysis.writeln("$tag: ₹${total.toStringAsFixed(2)}"));
    print("$userInput\n\n${analysis.toString()}");

    // Append analysis to the input field (not sending)
    _controller.text = "$userInput\n\n${analysis.toString()}";
    // Optionally, move the cursor to the end
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  List<InlineSpan> parseMarkdownLines(String message) {
    final lines = message.split('\n');
    final spans = <InlineSpan>[];

    final boldRegex = RegExp(r'\*\*(.*?)\*\*');

    for (final line in lines) {
      if (line.trim().startsWith('### ')  )  {
        // Header line
        spans.add(
          TextSpan(
            text: line.replaceFirst('### ', '') + '\n\n',
            style: TextStyle(
              fontWeight: FontWeight.w900, // Extra bold
              fontSize: 20,
              color: Color.fromRGBO(0, 212, 255, 1.0),
            ),
          ),
        );
      }
      else if(line.trim().startsWith('## '))
        {
          spans.add(
            TextSpan(
              text: line.replaceFirst('## ', '') + '\n\n',
              style: TextStyle(
                fontWeight: FontWeight.w900, // Extra bold
                fontSize: 20,
                color: Color.fromRGBO(2, 255, 218, 1.0),
              ),
            ),
          );

        }
      else {
        // Normal line, parse for **bold**
        int start = 0;
        final innerSpans = <TextSpan>[];

        for (final match in boldRegex.allMatches(line)) {
          if (match.start > start) {
            innerSpans.add(TextSpan(text: line.substring(start, match.start)));
          }
          innerSpans.add(TextSpan(
            text: match.group(1),
            style: TextStyle(fontWeight: FontWeight.w900, color: Color.fromRGBO(
                125, 169, 179, 1.0),), // Extra bold
          ));
          start = match.end;
        }
        if (start < line.length) {
          innerSpans.add(TextSpan(text: line.substring(start)));
        }
        // Add the line and a newline
        spans.add(TextSpan(
          children: innerSpans,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ));
        spans.add(const TextSpan(text: '\n'));
      }
    }
    return spans;
  }





  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            // reverse: true,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final formattedTime =
                  TimeOfDay.fromDateTime(message.timestamp).format(context);

              if (_isTyping && index == _messages.length - 1) {
                return Column(
                  children: [
                    Container(
                      padding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      alignment: message.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: message.isUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: message.isUser
                                    ? Color.fromRGBO(126, 225, 208, 1.0)
                                    : Color.fromRGBO(60, 80, 89, 1.0),
                                borderRadius: BorderRadius.circular(12),
                                border:  Border.all(color: message.isUser
                                    ?Color.fromRGBO(98, 175, 164, 1.0):Color.fromRGBO(
                                    102, 115, 122, 1.0),width: 3,),
                              ),
                              padding: EdgeInsets.all(12),
                              child: RichText(
                                text: TextSpan(
                                  children: parseMarkdownLines(message.text),
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ),

                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color.fromRGBO(38, 50, 56, 1.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          child: TypingIndicator(),
                        ),
                      ),
                    ),

                  ],
                );
              }
              return Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                alignment: message.isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: message.isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: message.isUser
                              ? Color.fromRGBO(126, 225, 208, 1.0)
                              : Color.fromRGBO(60, 80, 89, 1.0),
                          borderRadius: BorderRadius.circular(12),
                          border:  Border.all(color: message.isUser
                              ?Color.fromRGBO(98, 175, 164, 1.0):Color.fromRGBO(
                              102, 115, 122, 1.0),width: 3,),
                        ),
                        padding: EdgeInsets.all(12),
                        child: RichText(
                          text: TextSpan(
                            children: parseMarkdownLines(message.text),
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color.fromRGBO(38, 50, 56, 1.0),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Divider(height: 1),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Color.fromRGBO(169, 234, 246, 1.0),
              child: Row(
                children: [
                  // DropdownButton<String>(
                  //   value: selectedFilter,
                  //   items: filterTypes.map((String value) {
                  //     return DropdownMenuItem<String>(
                  //       value: value,
                  //       child: Text(value),
                  //     );
                  //   }).toList(),
                  //   onChanged: (String? newValue) {
                  //     setState(() {
                  //       selectedFilter = newValue!;
                  //       // Optionally update the UI to show the relevant picker
                  //     });
                  //   },
                  // ),

                  SizedBox(
                    height: 48,
                    width: 48,
                    child: TextButton(
                      onPressed: _showAnalysisModal,
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Color(0xFF10B6C5),
                      ),
                      child: Icon(Icons.attach_file, color: Color.fromRGBO(38, 50, 56, 1.0)),
                    )

                  ),

                  SizedBox(width: 8),


                  // Rounded TextField
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.grey.shade300, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.grey.shade400, width: 1.5),
                        ),
                      ),
                      onSubmitted: (value) =>_pendingAnalysisSelection != null?_sendMessage("32510dc17e1a7d11120ca32bcf0339a5","bbdf34ee-8528-4989-8fc8-cfc27a930549") :_sendMessage("6d4617ad886cdea88b20f17d2238ef0d",chippy),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Send Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _pendingAnalysisSelection != null?_sendMessage("32510dc17e1a7d11120ca32bcf0339a5","bbdf34ee-8528-4989-8fc8-cfc27a930549") :_sendMessage("6d4617ad886cdea88b20f17d2238ef0d",chippy),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF10B6C5), // Teal blue
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child:Icon(
                          Icons.send,
                        color: Colors.white,
                      )
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: Color.fromRGBO(169, 234, 246, 1.0),
              child: Text(
                'Powered by OmniDimension',
                style: TextStyle(
                  fontSize: 13,
                  color: Color.fromRGBO(38, 50, 56, 1.0),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        )
      ],
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 1500))
          ..repeat();
    _animation1 = Tween<double>(begin: 0.8, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0.0, 0.6, curve: Curves.easeInOut)),
    );
    _animation2 = Tween<double>(begin: 0.8, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0.2, 0.8, curve: Curves.easeInOut)),
    );
    _animation3 = Tween<double>(begin: 0.8, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0.4, 1.0, curve: Curves.easeInOut)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Transform.scale(
        scale: animation.value,
        child: child,
      ),
      child: Container(
        width: 14,
        height: 14,
        margin: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
            color: Color.fromRGBO(94, 104, 104, 1.0),
            shape: BoxShape.circle,

        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 50,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(

          color: Color.fromRGBO(38, 50, 56, 1.0),
          borderRadius: BorderRadius.circular(12),
        border:  Border.all(color: Color.fromRGBO(70, 86, 92, 1.0),width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(_animation1),
          _buildDot(_animation2),
          _buildDot(_animation3),
        ],
      ),
    );
  }
}
