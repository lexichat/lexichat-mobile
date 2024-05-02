import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lexichat/config/config.dart' as config;
import 'package:lexichat/models/User.dart';
import 'package:lexichat/utils/jwt.dart';
import 'package:http/http.dart' as http;
import 'package:lexichat/utils/ws_manager.dart';
import 'package:lexichat/utils/loading.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String? jwtToken;
  bool isBackendConnected = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.wait([
      _getJwtToken(),
      _checkBackendConnection(),
    ]);

    if (jwtToken == null || jwtToken == "") {
      Navigator.pushReplacementNamed(context, '/welcome');
    } else {
      await Future.wait([
        _populateUserDetails(),
        InitializeWebSocketManager(),
      ]);

      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _getJwtToken() async {
    String? token = await JwtUtil.getJwtToken();
    print("token $token");
    config.JWT_Token = token;
    setState(() {
      jwtToken = token;
    });
  }

  Future<void> _checkBackendConnection() async {
    bool isConnected = await checkBackendConnection();
    setState(() {
      isBackendConnected = isConnected;
    });
    // _showBackendConnectionStatus();
  }

  Future<void> _populateUserDetails() async {
    User user = await LocalUserState.fetchUserConfigData();
    print("local user state ${user.userID}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      body: Center(
        child: Image.asset(
          'assets/images/app_logo.png',
          height: 200,
          width: 200,
        ),
      ),
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
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

Future<bool> checkBackendConnection() async {
  try {
    String? baseApiUrl = config.BASE_API_URL;
    if (baseApiUrl == null || baseApiUrl.isEmpty) {
      print("BASE_API_URL not found or empty in the .env file");
      return false;
    }

    final response = await http.get(Uri.parse(baseApiUrl + "/api/ping"));
    print("response: ${response.body}");
    return response.statusCode == 200;
  } catch (e) {
    if (e is SocketException) {
      //treat SocketException
      print("Socket exception: ${e.toString()}");
    } else if (e is TimeoutException) {
      //treat TimeoutException
      print("Timeout exception: ${e.toString()}");
    } else
      print("Unhandled exception: ${e.toString()}");
  }
  return false;
}
