import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lexichat/screens/home.dart';
import 'package:lexichat/screens/loading.dart';
import 'package:lexichat/screens/signup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lexichat/screens/welcome.dart';
import 'package:lexichat/utils/db.dart';
import 'package:lexichat/utils/fcm_manager.dart';
import 'firebase_options.dart';
import 'package:lexichat/config/config.dart' as config;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  await setupFirebaseMessaging();
  await initializeAndConnectDB("test.db");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "LexiChat",
      theme: ThemeData(
        splashColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/welcome': (context) => WelcomeScreen(),
        // '/chat': (context) => const ChatScreen(),
        // '/message': (context) => const MessageScreen(),
        // '/profile': (context) => const ProfileScreen(),
        // '/login': (context) => const LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/loading': (context) => const LoadingScreen(),
        '/home': (context) => HomeScreen(),
      },
      initialRoute: '/loading',
    );
  }
}

Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  try {
    String? fcmToken = await messaging.getToken();
    print('FCM Token: $fcmToken');

    if (fcmToken != null && fcmToken.isNotEmpty) {
      config.FCMToken = fcmToken;
      config.fcmManager = FCMManager();
      await config.fcmManager.initState();
    } else {
      throw Exception("FCM token is empty or null");
    }
  } catch (e) {
    print('Error getting FCM token: $e');
    throw Exception("Couldn't generate FCM token");
  }
}
