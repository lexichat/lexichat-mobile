import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lexichat/models/User.dart';

late String FCMToken;
late String JWT_Token;
String? BASE_API_URL = dotenv.env["BASE_API_URL"];

// user details
late User userDetails;
