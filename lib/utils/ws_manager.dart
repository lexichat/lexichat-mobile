import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:lexichat/config/config.dart' as config;

late final WebSocketManager wsManager;

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
  final StreamController<Map<String, dynamic>> _dataStreamController =
      StreamController.broadcast();

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

  Future<void> _connectToWebSocket(String url) async {
    await Future.microtask(() {
      IOWebSocketChannel? channel;
      try {
        print("url: $url");
        channel = IOWebSocketChannel.connect(
          Uri.parse(url),
          headers: headers,
        );
        print("Connection to $url established.");
        _sockets[url] = channel;
        channel.stream.listen(
          (data) {
            print(data);
            _handleIncomingData(data);
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

  void _handleIncomingData(dynamic data) {
    final jsonData = jsonDecode(data);
    _dataStreamController.sink.add(jsonData);
  }

  Stream<Map<String, dynamic>> get dataStream => _dataStreamController.stream;

  void sendMessage(OutBoundMessage outBoundMessage) {
    var message = outBoundMessage.toJson();
    print("json data: ${jsonEncode(message)}");
    for (final socket in _sockets.values) {
      socket.sink.add(jsonEncode(message));
    }
  }

  bool isWebSocketConnected(String url) {
    return _sockets.containsKey(url);
  }

  void dispose() {
    for (final socket in _sockets.values) {
      socket.sink.close();
    }
    _dataStreamController.close();
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
