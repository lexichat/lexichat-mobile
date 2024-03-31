import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lexichat/screens/llm_setup.dart';
import 'package:lexichat/screens/signup.dart';
import 'package:lexichat/utils/jwt.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? jwtToken;
  bool isBackendConnected = false;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _getJwtToken();
    _checkBackendConnection();
  }

  Future<void> _getJwtToken() async {
    String token = await JwtUtil.getJwtToken();
    print("token ${token}");
    setState(() {
      jwtToken = token;
    });
  }

  Future<void> _checkBackendConnection() async {
    bool isConnected = await checkBackendConnection();
    setState(() {
      isBackendConnected = isConnected;
    });
    _showBackendConnectionStatus();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: jwtToken == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/app_logo.png'),
                    SizedBox(height: 6),
                    Text('Loading...'),
                  ],
                ),
              )
            : jwtToken != ""
                ? LLMSetupScreen()
                : SignUpScreen(),
      ),
      scaffoldMessengerKey: _scaffoldMessengerKey,
    );
  }

  void _showBackendConnectionStatus() {
    final scaffoldMessenger = _scaffoldMessengerKey.currentState;
    if (scaffoldMessenger != null) {
      final message = isBackendConnected
          ? 'Connected to backend'
          : 'Unable to connect to backend';
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

Future<bool> checkBackendConnection() async {
  try {
    final response =
        await http.get(Uri.parse(dotenv.env["BASE_API_URL"]! + "/api/ping"));
    print("response: ${response.body}");
    return response.statusCode == 200;
  } on SocketException catch (_) {
    // Unable to connect to the backend server
    return false;
  } catch (e) {
    // Other errors
    print("Error: $e");
    return false;
  }
}
