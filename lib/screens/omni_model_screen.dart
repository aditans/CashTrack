import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart' show rootBundle;

import 'package:webview_flutter/webview_flutter.dart';


class OmniModelScreen extends StatefulWidget {

  const OmniModelScreen({super.key});



  @override
  State<OmniModelScreen> createState() => _OmniModelScreenState();
}

class _OmniModelScreenState extends State<OmniModelScreen> {
  late final WebViewController _controller;

  final String htmlData = '''
    <!DOCTYPE html>
    <html>
    <head><meta charset="UTF-8"></head>
    <body>
      <script id="omnidimension-web-widget" async
        src="https://backend.omnidim.io/web_widget.js?secret_key=6d4617ad886cdea88b20f17d2238ef0d">
      </script>
    </body>
    </html>
  ''';


  @override
  void initState() {
    super.initState();

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







  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
      ),
        body: WebViewWidget(controller: _controller), // your main content

      // ✅ Fix: Use bottomSheet instead of bottomNavigationBar
      // bottomSheet: SafeArea(
      //   child: Container(
      //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      //     decoration: BoxDecoration(
      //       color: Colors.grey.shade100,
      //       border: const Border(
      //         top: BorderSide(color: Colors.grey),
      //       ),
      //     ),
      //     child: Row(
      //       children: [
      //         Expanded(
      //           child: TextField(
      //
      //             decoration: const InputDecoration(
      //               hintText: 'Type your message...',
      //               border: InputBorder.none,
      //             ),
      //
      //           ),
      //         ),
      //         IconButton(
      //           icon: const Icon(Icons.send, color: Colors.blueAccent),
      //           onPressed: (){},
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
    );
  }

}
