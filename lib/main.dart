import 'package:flutter/material.dart';
import 'package:lexichat/screens/signup.dart';
import 'package:lexichat/utils/jwt.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? jwtToken;

  @override
  void initState() {
    super.initState();
    _getJwtToken();
  }

  Future<void> _getJwtToken() async {
    String token = await JwtUtil.getJwtToken();
    setState(() {
      jwtToken = token;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: jwtToken == null
          ? Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/app_logo.png'),
                    SizedBox(height: 6),
                    Text('Loading...'),
                  ],
                ),
              ),
            )
          : SignUpScreen(jwtKey: jwtToken!),
    );
  }
}
