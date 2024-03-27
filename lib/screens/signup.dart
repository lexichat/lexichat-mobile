import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lexichat/screens/home.dart';
import 'package:lexichat/utils/signup.dart';

class SignUpScreen extends StatefulWidget {
  final String jwtKey;

  SignUpScreen({required this.jwtKey});

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

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _handleOTPVerification() async {
    if (_formKey.currentState!.validate()) {
      bool isOTPValid = await verifyOTP(_otpController.text);
      if (isOTPValid) {
        // Navigate to HomeScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (route) => false,
        );
      } else {
        // Show wrong OTP message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wrong OTP. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OTP Verification'),
      ),
      body: Padding(
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
