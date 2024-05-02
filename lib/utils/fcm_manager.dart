import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lexichat/config/config.dart';
import 'package:lexichat/models/Chat.dart';
import 'package:lexichat/models/User.dart';
import 'package:lexichat/utils/db.dart';

class FCMManager {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final StreamController<Map<User, Conversation>> _newUserChatStreamController =
      StreamController<Map<User, Conversation>>.broadcast();
  Stream<Map<User, Conversation>> get newUserChatStream =>
      _newUserChatStreamController.stream;

  Future<void> initState() async {
    await requestPermission();
    setupFCMListeners();
  }

  Future<void> requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  void handleReceivingFCMData(RemoteMessage message) async {
    final data = message.data;
    print("received data: ${data}");
    if (data != null && data.containsKey('NewUserChat')) {
      // Data represents a new channel creation
      try {
        final jsonData = jsonDecode(data['NewUserChat']);
        final channelData = Channel.fromMap(jsonData['channel']);
        final senderUserData = User.fromJson(jsonData['sender_user']);
        final firstMessage = Conversation.fromServer(jsonData['first_message']);
        final userIDs = (jsonData['channel_users'] as String).split(',');

        await populateChannelAndChannelUsersLocally(
            DBClient, channelData.id, "", senderUserData.userID);

        await PopulateUserTableIfNotExists(senderUserData, DBClient);

        // store message
        await writeConversation(DBClient, firstMessage);

        // notify home screen ui
        _newUserChatStreamController.sink.add({senderUserData: firstMessage});

        // add to wsManager
        wsManager.addNewWSConnection(channelData.id);
      } catch (e) {
        print('Error unmarshalling NewUserChat data: $e');
      }
    } else if (data != null && data.containsKey('Message')) {
      // Data represents a new message
      try {
        final jsonData = jsonDecode(data['Message']);
        final messageData = Conversation.fromMap(jsonData);

        // Call writeMessage
        writeConversation(DBClient, messageData);
      } catch (e) {
        print('Error unmarshalling message data: $e');
      }
    } else if (data.containsKey("status")) {
      try {
        // update status
      } catch (e) {
        print("Error unmarshalling message status updates. ${e}");
      }
    } else {
      // Unknown data format
      print('Unknown data format: $data');
    }
  }

  void setupFCMListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      handleReceivingFCMData(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleReceivingFCMData(message);
    });

    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  }
}

@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print("l1 message received: ${message.data}");
  FCMManager().handleReceivingFCMData(message);
}
