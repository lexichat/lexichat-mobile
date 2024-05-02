import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lexichat/models/Chat.dart';
import 'package:lexichat/models/User.dart';
import 'package:lexichat/utils/db.dart';
import 'package:sqflite/sqflite.dart';
import 'package:web_socket_channel/io.dart';
import 'package:lexichat/config/config.dart' as config;

// late final WebSocketManager wsManager;

final WS_PREFIX_URL = "${config.BASE_WS_URL! + "/ws?channel="}";

class InBoundMessageAck {
  final String status;
  final String messageID;

  InBoundMessageAck({
    required this.status,
    required this.messageID,
  });

  factory InBoundMessageAck.fromJson(Map<String, dynamic> json) {
    return InBoundMessageAck(
      status: json["Status"]['status'],
      messageID: json["Status"]['message_id'],
    );
  }
  _processAcknowledgment() async {
    print("update status for: ${messageID}");
    await updateStatus(DBClient, messageID, 'sent'); // local update

    // broadcast chatscreen UI
  }
}

class InBoundMessageMsg {
  Conversation Message;
  InBoundMessageMsg({required this.Message});

  Future<void> _processIncomingMessage() async {
    print("processing message");
    // insert into messages table
    await writeConversation(DBClient, Message);
  }

  factory InBoundMessageMsg.fromJson(Map<String, dynamic> json) {
    return InBoundMessageMsg(
      Message: Conversation.fromServer(json['Message']),
    );
  }
}

class InBoundMessageNewChatInit {
  final Channel channel;
  final User user;

  InBoundMessageNewChatInit({
    required this.channel,
    required this.user,
  });

  Future<void> initializeNewChat(Database db) async {
    await PopulateChannelLocally(db, channel);
    await PopulateUserTableIfNotExists(user, db);
    await populateChannelUsersLocally(db, channel.id, [user.userID]);
  }
}

class OutBoundMessage {
  String Message;
  String MessageID;

  OutBoundMessage({required this.Message, required this.MessageID});

  Map<String, dynamic> toJson() {
    return {
      'message': Message,
      'message_id': MessageID,
    };
  }
}

class WebSocketManager {
  final List<String> _wsUrls;
  final Map<String, IOWebSocketChannel> _sockets = {};

  final StreamController<Conversation> _messageStreamController =
      StreamController<Conversation>.broadcast();
  final StreamController<InBoundMessageAck>
      _messageStatusUpdateStreamController =
      StreamController<InBoundMessageAck>.broadcast();
  Stream<Conversation> get messageStream => _messageStreamController.stream;
  Stream<InBoundMessageAck> get messageStatusUpdateStream =>
      _messageStatusUpdateStreamController.stream;

  WebSocketManager(this._wsUrls) {
    _initializeWebSockets();
  }

  Map<String, dynamic> headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
    'Authorization': '${config.JWT_Token}',
  };

  void _initializeWebSockets() {
    for (final url in _wsUrls) {
      _connectToWebSocket(url);
    }
  }

  Future<void> addNewWSConnection(int channel_id) async {
    String url = WS_PREFIX_URL + "$channel_id";
    await _connectToWebSocket(url);
  }

  Future<void> _connectToWebSocket(String url) async {
    await Future.microtask(() {
      IOWebSocketChannel? channel;
      try {
        print("url: $url");
        print("headers: $headers");
        channel = IOWebSocketChannel.connect(
          Uri.parse(url),
          headers: headers,
        );
        print("Connection to $url established.");
        _sockets[url] = channel;
        channel.stream.listen(
          (data) {
            print("incoming data ${data}");
            _handleIncomingData(data, url);
          },
          onError: (error) => _retryConnection(url),
          onDone: () =>
              _retryConnection(url), // Trigger retry when connection is lost
        );
      } on SocketException catch (e) {
        print("Network error: ${e}");

        if (e.osError != null && e.osError!.errorCode == 7) {
          // showNetworkNotFoundDialog()
          print("Check your network connection");
        } else {
          print("unknown network error. ${e}");
        }
      } catch (e) {
        print("Error connecting to $url: $e");
        _retryConnection(url);
      }
    });
  }

  void _retryConnection(String url) {
    Timer(const Duration(seconds: 5), () => _connectToWebSocket(url));
  }

  void _handleIncomingData(dynamic data, String url) {
    final jsonData = jsonDecode(data);

    if (jsonData != null) {
      // Check if the data is a message or an acknowledgment
      if (jsonData.containsKey('Message')) {
        // Handle incoming message
        print(jsonData);
        final inboundMessage = InBoundMessageMsg.fromJson(jsonData);
        inboundMessage._processIncomingMessage();

        print("in bound message map, ${inboundMessage.Message.toMap()}");
        _messageStreamController.sink.add(inboundMessage.Message);
      } else if (jsonData.containsKey('Status')) {
        // Handle acknowledgment
        final acknowledgment = InBoundMessageAck.fromJson(jsonData);
        acknowledgment._processAcknowledgment();
        _messageStatusUpdateStreamController.sink.add(acknowledgment);
      } else {
        // Handle unknown data format
        print('Unknown data format: $jsonData');
      }
    } else {
      print("received null data");
    }
  }

  // Stream<Map<String, dynamic>> get dataStream => _dataStreamController.stream;

  void sendMessage(OutBoundMessage outBoundMessage, int channelId) {
    var message = outBoundMessage.toJson();
    print("json data: ${jsonEncode(message)}");

    String wsUrl = "${WS_PREFIX_URL}$channelId";
    IOWebSocketChannel? socket = _sockets[wsUrl];

    if (socket != null) {
      socket.sink.add(jsonEncode(message));
    } else {
      print("WebSocket channel not found for channelId: $channelId");
    }
  }

  bool isWebSocketConnected(String url) {
    return _sockets.containsKey(url);
  }

  void dispose() {
    for (final socket in _sockets.values) {
      socket.sink.close();
    }
  }

  void showNetworkNotFoundDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Network Error'),
        content: const Text(
            'Network not found. Please check your internet connection.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

Future<List<String>> fetchWSUrls() async {
  // fetch all channel ids
  List<int> channelIDs = await fetchAllChannelIds(DBClient);
  List<String> wsURLs =
      channelIDs.map((id) => "${WS_PREFIX_URL}${id}").toList();
  print("WsUrls: ${wsURLs}");
  return wsURLs;
}

class MessageProvider extends ChangeNotifier {
  List<Conversation> _messages = [];

  List<Conversation> get messages => _messages;

  void addMessage(Conversation message) {
    _messages.add(message);
    notifyListeners();
  }
}

Future<void> InitializeWebSocketManager() async {
  final List<String> urls = await fetchWSUrls();
  config.wsManager = WebSocketManager(urls);
}
