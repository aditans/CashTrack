import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:typewritertext/typewritertext.dart';

import '../models/sms_model.dart';

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

  Future<void> _getInitialGreeting() async {
    // Send empty message to get AI greeting and add to chat
    String aiReply = await sendJsonData("who r u");
    setState(() {
      _messages.add(ChatMessage(
        text: aiReply,
        timestamp: DateTime.now(),
        isUser: false, // AI message
      ));
    });
  }
  // Returns (cleanedMessage, jsonData) where jsonData is null if no !POST present
  Map<String, dynamic>? extractPostJson(String aiReply, {String marker = "!POST//"}) {
    if (aiReply.contains(marker)) {
      final parts = aiReply.split(marker);
      final cleanedMessage = parts[0].trim();
      final jsonStr = parts[1].trim();
      try {
        final jsonData = json.decode(jsonStr);
        return {
          'message': cleanedMessage,
          'json': jsonData,
        };
      } catch (e) {
        // If JSON parsing fails, just return the original message
        return {
          'message': aiReply,
          'json': null,
        };
      }
    }
    return {
      'message': aiReply,
      'json': null,
    };
  }


  Future<void> _sendMessage() async {
    String userInput = _controller.text.trim();
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        text: _controller.text.trim(),
        timestamp: DateTime.now(),
        isUser: true,
      ));
      _controller.clear();
      _isTyping = true;
    });
    String aiReply = await sendJsonData(userInput);
    print("aiReply========="+aiReply);
    Map<String, dynamic>? result = extractPostJson(aiReply);
    final cleanedMessage = result?['message'];
    final jsonData = result?['json'];
    print(result.toString());
    try{
      print(cleanedMessage+"========="+jsonData);
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
      _tagUntaggedSendersInBackground();

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
  final bitch=null;

  Future<String> sendJsonData(String userInput) async {
    // Your data as a Dart map
    Map<String, dynamic> data = {
      "From": "",
      "user_message": userInput,
    "unique_session_id": "3c1d9ea7-3b5d-47f8-a79a-f6998a2bc92f",
      "secret_key": "6d4617ad886cdea88b20f17d2238ef0d" //fb1d9464ec4c1764190725ab860e2a52            //6d4617ad886cdea88b20f17d2238ef0d
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

              if (_isTyping && index == _messages.length - 1)
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
                              child: Text(
                                message.text,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                // duration: const Duration(milliseconds: 50),
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
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          // duration: const Duration(milliseconds: 50),
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
                      onSubmitted: (value) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Send Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF10B6C5), // Teal blue
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: Text(
                        'Send',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Color.fromRGBO(255, 255, 255, 1.0)),
                      ),
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
