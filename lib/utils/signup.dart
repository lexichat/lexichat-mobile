import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lexichat/config/config.dart' as config;
import 'package:lexichat/models/User.dart' as lexichat;
import 'package:lexichat/utils/jwt.dart';
import 'package:flutter/material.dart';

String? _verificationId;
String? _phoneNumber;

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
  String userID,
  String username,
  String phoneNumber,
  String fcm_token,
  Uint8List? profilePicture,
  BuildContext context,
) async {
  final url = Uri.parse(config.BASE_API_URL! + "/api/v1/users/create");
  final user = lexichat.User(
    userID: userID,
    userName: username,
    phoneNumber: phoneNumber,
    fcmToken: fcm_token,
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

      config.JWT_Token = token;

      await JwtUtil.setJwtToken(token);
      await JwtUtil.setUserId(userId);

      print(await JwtUtil.getJwtToken());

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
