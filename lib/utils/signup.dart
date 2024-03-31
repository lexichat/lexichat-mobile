import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lexichat/models/User.dart' as lexichat;
import 'package:lexichat/utils/jwt.dart';
import 'package:flutter/material.dart';

String? _verificationId;
String? _phoneNumber;
String? BASE_API_URL = dotenv.env["BASE_API_URL"];

Future<void> sendVerificationCode(String phoneNumber) async {
  await FirebaseAuth.instance.verifyPhoneNumber(
    phoneNumber: phoneNumber,
    verificationCompleted: (PhoneAuthCredential credential) {
      // Verification completed automatically
      print('Verification completed automatically');
    },
    verificationFailed: (FirebaseAuthException e) {
      print('Verification failed: ${e.message}');
    },
    codeSent: (String verificationId, int? resendToken) {
      // Save the verification ID and phone number
      _verificationId = verificationId;
      _phoneNumber = phoneNumber;
    },
    codeAutoRetrievalTimeout: (String verificationId) {
      // Called when the auto-retrieval timeout is reached
      print('Auto-retrieval timeout');
    },
  );
}

Future<bool> verifyCode(String code) async {
  if (_verificationId != null && _phoneNumber != null) {
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: code,
    );

    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      print('Phone number ${_phoneNumber} verified successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      print('Error verifying code: ${e.message}');
      return false;
    }
  } else {
    print('Verification ID or phone number not available');
    return false;
  }
}

isPhoneNumberInUse(number) {
  return false;
}

Future<String?> createUser(
  String username,
  String phoneNumber,
  Uint8List? profilePicture,
  BuildContext context,
) async {
  final url = Uri.parse(BASE_API_URL! + "/api/v1/user/create");
  final user = lexichat.User(
    id: null,
    username: username,
    phoneNumber: phoneNumber,
    profilePicture: profilePicture?.toList() ?? [],
    createdAt: null,
  );
  final body = jsonEncode(user.toJson());

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 201) {
      print('User created: ${response.body}');

      // Extract the token and userId from the response body
      final responseData = jsonDecode(response.body);
      final token = responseData['token'];
      final userId = responseData['userId'];

      await JwtUtil.setJwtToken(token);
      await JwtUtil.setUserId(userId);

      return null;
    } else {
      print('Failed to create user: ${response.statusCode} ${response.body}');
      return "Error in creation of user: ${response.statusCode} ${response.body}";
    }
  } catch (e) {
    print('Error: $e');
    return "'Error: $e'";
  }
}
