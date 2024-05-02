import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lexichat/config/config.dart' as config;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexichat/models/Chat.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:uuid/uuid.dart';

class AIChatScreen extends StatefulWidget {
  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  List<AIConversation> messages = [];

  late TextEditingController _messagingController;
  static const bg1 = Color(0xFFF5F5F5);
  static const bg2 = Color(0xFFF5F5DC);
  static const bg3 = Color(0xFFFBF7F2);

  @override
  void initState() {
    super.initState();
    _messagingController = TextEditingController();
    initializeData();
  }

  initializeData() async {
    if (!(await isLlamaCppApiAvailable())) {
      // show AppSnackbar saying setup llm locally
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set up LLM locally'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _messagingController.dispose();
    super.dispose();
  }

  Future<bool> isLlamaCppApiAvailable() async {
    final url = Uri.parse('http://127.0.0.1:8080');
    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.head(url, headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      print('Error checking API availability: $e');
      return false;
    }
  }

  String promptInstruction(String context, String intendedMessage) {
    String paraphrasing_prompt =
        """Below is a conversation between two people, along with the context that led to one person's intended message. Your task is to paraphrase the intended message in a corporate-facing and professional manner, using appropriate vocabulary.

            ### Conversation Context: 
            $context

            ### User's Intended Message: 
            $intendedMessage

            ### Paraphrased Response: 
            """
        "";
    print(paraphrasing_prompt);

    return paraphrasing_prompt;
  }

  Future<void> queryLlamaCpp(String context, String intendedMessage) async {
    if (await isLlamaCppApiAvailable()) {
      final url = Uri.parse('http://127.0.0.1:8080/completion');
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({
        'prompt': promptInstruction(context, intendedMessage),
        'stream': true,
      });

      final request = http.Request('POST', url);
      request.headers.addAll(headers);
      request.body = body;

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        String serverResponse = '';
        await for (var data
            in streamedResponse.stream.transform(utf8.decoder)) {
          serverResponse += data;
          print(serverResponse);
          // update message tile
        }

        // Create a new AIConversation instance with the server response
        final conversation = AIConversation(
          id: Uuid().v4().toString(),
          message: serverResponse,
          fromUserId: 'server',
          status: MessageStatuses.sent.toString(),
          createdAt: DateTime.now(),
        );

        // Add the conversation to the messages list
        setState(() {
          messages.add(conversation);
        });
      } else {
        print('Request failed with status: ${streamedResponse.statusCode}');
      }
    } else {
      print('Llama.cpp API is not available');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg3,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text("Paraphrase AI"),
        backgroundColor: bg1,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text('Start Chatting with AI'),
                  )
                : ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return MessageTile(
                        message: message.message,
                        isCurrentUser:
                            message.fromUserId == config.userDetails.userID,
                        status: message.status,
                        timestamp: message.createdAt.toString(),
                      );
                    },
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messagingController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: bg3,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: bg3,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: Colors.green,
                    ),
                    onPressed: () async {
                      final message = AIConversation(
                        id: Uuid().v4().toString(),
                        message: _messagingController.text,
                        fromUserId: config.userDetails.userID,
                        status: MessageStatuses.sent.toString(),
                        createdAt: DateTime.now(),
                      );
                      sendMessage(message);
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void sendMessage(AIConversation message) {
    print("message id: ${message.id}");
    setState(() {
      messages.add(message);
    });
    queryLlamaCpp("", message.message);
    _messagingController.clear();
  }
}

class AIConversation {
  final String id;
  final String message;
  final String fromUserId;
  final String status;
  final DateTime createdAt;

  AIConversation({
    required this.id,
    required this.message,
    required this.fromUserId,
    required this.status,
    required this.createdAt,
  });
}

class MessageTile extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final String status;
  final String timestamp;

  MessageTile({
    required this.message,
    required this.isCurrentUser,
    required this.status,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final msgTextStyle = TextStyle(
      color: isCurrentUser ? Colors.white : Colors.black,
      fontSize: 14,
    );

    final msgContainerWidthAddition = 50;

    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: isCurrentUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                width: getTextWidth(message, msgTextStyle) +
                            msgContainerWidthAddition >
                        mediaQuery.size.width * 0.7
                    ? mediaQuery.size.width * 0.7
                    : getTextWidth(message, msgTextStyle) +
                        msgContainerWidthAddition,
                decoration: BoxDecoration(
                  color: isCurrentUser ? Colors.blueGrey : Colors.grey[300],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                    bottomLeft: isCurrentUser
                        ? Radius.circular(16.0)
                        : Radius.circular(0.0),
                    bottomRight: isCurrentUser
                        ? Radius.circular(0.0)
                        : Radius.circular(16.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    message,
                    style: msgTextStyle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 1.0, right: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('hh:mm a').format(DateTime.parse(timestamp)),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.0,
                      ),
                    ),
                    if (isCurrentUser)
                      SizedBox(
                        width: 4.0,
                        child: getStatusIcon(status),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double getTextWidth(String text, TextStyle style) {
    final textSpan = TextSpan(
      text: text,
      style: style,
    );
    final tp =
        TextPainter(text: textSpan, textDirection: painting.TextDirection.ltr);
    tp.layout();
    return tp.width;
  }

  Widget getStatusIcon(String status) {
    if (status == MessageStatuses.pending.toString()) {
      return const Icon(
        ChatIcons.accessTime,
        color: Colors.black,
        size: 16.0,
      );
    } else if (status == MessageStatuses.sent.toString()) {
      return const Icon(
        ChatIcons.done,
        color: Colors.black,
        size: 16.0,
      );
    } else if (status == MessageStatuses.delivered.toString()) {
      return const Icon(
        ChatIcons.doneAll,
        color: Colors.black,
        size: 16.0,
      );
    } else if (status == MessageStatuses.read.toString()) {
      return const Icon(
        ChatIcons.doneAll,
        color: Colors.green,
        size: 16.0,
      );
    }
    return SizedBox();
  }
}

class ChatIcons {
  ChatIcons._();

  static const _kFontFam = 'ChatIcons';
  static const String? _kFontPkg = null;

  static const IconData done =
      IconData(0xe800, fontFamily: _kFontFam, fontPackage: _kFontPkg);
  static const IconData doneAll =
      IconData(0xe801, fontFamily: _kFontFam, fontPackage: _kFontPkg);
  static const IconData accessTime =
      IconData(0xe802, fontFamily: _kFontFam, fontPackage: _kFontPkg);
}
