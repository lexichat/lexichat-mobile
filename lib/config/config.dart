import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lexichat/models/User.dart';
import 'package:lexichat/utils/fcm_manager.dart';
import 'package:lexichat/utils/ws_manager.dart';

late String FCMToken;
late String JWT_Token;
String? BASE_API_URL = dotenv.env["BASE_API_URL"];
String? BASE_WS_URL = dotenv.env["BASE_WS_URL"];

// user details
late User userDetails;

late FCMManager fcmManager;

late WebSocketManager wsManager;
