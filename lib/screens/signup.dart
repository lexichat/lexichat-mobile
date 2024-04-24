import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lexichat/models/User.dart';
import 'package:lexichat/screens/home.dart';
import 'package:lexichat/screens/loading.dart';
import 'package:lexichat/utils/loading.dart';
import 'package:lexichat/utils/signup.dart';
import 'package:lexichat/config/config.dart' as config;
import 'dart:io';

import 'package:image_picker/image_picker.dart';

String PhoneNumberExtension = "+91";

class SignUpScreen extends StatefulWidget {
  SignUpScreen();

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberController = TextEditingController();
  String? _phoneNumberError;

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }

    if (value.length != 10) {
      return 'Please enter a valid 10-digit phone number';
    }

    if (isPhoneNumberInUse(value)) {
      return 'Phone number already in use';
    }

    return null;
  }

  void _showOTPScreen() async {
    setState(() {
      _phoneNumberError = _validatePhoneNumber(_phoneNumberController.text);
    });

    if (_formKey.currentState!.validate()) {
      bool isConnected = await checkBackendConnection();
      if (isConnected) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OTPScreen(phoneNumber: _phoneNumberController.text),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Unable to connect to backend. Please try again later.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bg-welcome-signup.jpg"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.grey.withOpacity(0.23),
              BlendMode.srcATop,
            ),
          ),
        ),
        child: Center(
          child: SizedBox(
              width: 360,
              height: 310,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _phoneNumberController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              errorText: _phoneNumberError,
                            ),
                            validator: _validatePhoneNumber,
                          ),
                          SizedBox(height: 12.0),
                          Text(
                            'You will receive OTP and will also be redirected to your browser for auto captcha.',
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontSize: 12.0,
                            ),
                          ),
                          SizedBox(height: 12.0),
                          const Text(
                            'By signing up, you agree with terms and conditions.',
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 12.0,
                            ),
                          ),
                          SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: _showOTPScreen,
                            child: Text('Next'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
        ),
      ),
    );
  }
}

class OTPScreen extends StatefulWidget {
  final String phoneNumber;

  OTPScreen({required this.phoneNumber});

  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _requestFirebaseForOTP(PhoneNumberExtension + widget.phoneNumber);
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _requestFirebaseForOTP(phoneNumber) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await sendVerificationCode(phoneNumber);
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleOTPVerification() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        bool isOTPValid = await verifyCode(_otpController.text.trim());
        if (isOTPValid) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => GetUserDetails(
                    phoneNumber: widget.phoneNumber,
                  )));
        } else {
          setState(() {
            _retryCount++;
          });
          if (_retryCount >= 3) {
            // Show maximum retry reached message
          } else {
            // Show wrong OTP message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Wrong OTP. Please try again.'),
              ),
            );
          }
        }
      } catch (e) {
        // Handle error
        print(e);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/bg-welcome-signup.jpg"),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.grey.withOpacity(0.23),
                BlendMode.srcATop,
              ),
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 360,
              height: 300,
              child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(),
                            )
                          : Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Enter the OTP sent to\n',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '$PhoneNumberExtension ${widget.phoneNumber}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors
                                                .black, // You can customize the color if needed
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 14.0),
                                  TextFormField(
                                    controller: _otpController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'OTP',
                                    ),
                                    validator: (value) {
                                      if (value!.length != 6) {
                                        return 'Please enter a valid 6-digit OTP';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 20.0),
                                  ElevatedButton(
                                    onPressed: _handleOTPVerification,
                                    child: Text('Verify'),
                                  ),
                                  SizedBox(height: 25.0),
                                  const Center(
                                    child: Text(
                                      'resend OTP',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  )),
            ),
          ),
        ));
  }
}

class GetUserDetails extends StatefulWidget {
  final String phoneNumber;
  GetUserDetails({required this.phoneNumber});

  @override
  _GetUserDetailsState createState() => _GetUserDetailsState();
}

class _GetUserDetailsState extends State<GetUserDetails> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _userIDController = TextEditingController();

  // File? _imageFile;
  Uint8List? _imgFileData;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 25);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      int fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        // File size check (5MB limit)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected image exceeds 5MB limit.'),
          ),
        );
      } else {
        setState(() {
          _imgFileData = imageFile.readAsBytesSync();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/bg-welcome-signup.jpg"),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.grey.withOpacity(0.23),
                BlendMode.srcATop,
              ),
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 360,
              height: 550,
              child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Enter your details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _userIDController,
                            decoration: InputDecoration(
                              labelText: 'UserID',
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username',
                            ),
                          ),
                          SizedBox(height: 16.0),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                                image: _imgFileData != null
                                    ? DecorationImage(
                                        image: MemoryImage(_imgFileData!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _imgFileData == null
                                  ? Icon(Icons.camera_alt, size: 40)
                                  : null,
                            ),
                          ),
                          SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: () async {
                              // print('userId : ${_userIDController.text}');
                              // print('Username: ${_usernameController.text}');
                              User userDetails = User(
                                userID: _userIDController.text,
                                userName: _usernameController.text,
                                phoneNumber: (PhoneNumberExtension +
                                    " " +
                                    widget.phoneNumber),
                                fcmToken: config.FCMToken,
                                profilePicture: _imgFileData,
                                createdAt: '',
                              );

                              // create user
                              String? err = await createUser(
                                  _userIDController.text,
                                  _usernameController.text,
                                  (PhoneNumberExtension +
                                      " " +
                                      widget.phoneNumber),
                                  config.FCMToken,
                                  _imgFileData,
                                  context);

                              if (err == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User created successfully!'),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                                // store local state of user deets
                                LocalUserState.updateUserDetails(userDetails);
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (context) => HomeScreen()),
                                  (route) => false,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(err),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                            child: Text('Save'),
                          ),
                        ],
                      ),
                    ),
                  )),
            ),
          ),
        ));
  }
}
