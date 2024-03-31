import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lexichat/screens/llm_setup.dart';
import 'package:lexichat/utils/signup.dart';
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

  void _showOTPScreen() {
    setState(() {
      _phoneNumberError = _validatePhoneNumber(_phoneNumberController.text);
    });

    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OTPScreen(phoneNumber: _phoneNumberController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  errorText: _phoneNumberError,
                ),
                validator: _validatePhoneNumber,
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
      appBar: AppBar(
        title: Text('OTP Verification'),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Enter the OTP sent to ${widget.phoneNumber}'),
                    SizedBox(height: 16.0),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'OTP',
                      ),
                      validator: (value) {
                        if (value!.length != 6) {
                          return 'Please enter a valid 6-digit OTP';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _handleOTPVerification,
                      child: Text('Verify'),
                    ),
                  ],
                ),
              ),
            ),
    );
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
      appBar: AppBar(
        title: Text('Get User Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                print('Username: ${_usernameController.text}');
                // create user
                String? err = await createUser(
                    _usernameController.text,
                    (PhoneNumberExtension + " " + widget.phoneNumber),
                    _imgFileData,
                    context);

                if (err == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User created successfully!'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LLMSetupScreen()),
                    (route) => false,
                  );
                } else {
                  // tell there is error through snackbar
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
    );
  }
}
