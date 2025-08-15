import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'grade1_success_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String referenceNumber;
  final Map<String, dynamic> applicationData;
  final String paymentId;

  const OTPVerificationScreen({
    Key? key,
    required this.referenceNumber,
    required this.applicationData,
    required this.paymentId,
  }) : super(key: key);

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  List<TextEditingController> otpControllers = List.generate(6, (index) => TextEditingController());
  List<FocusNode> otpFocusNodes = List.generate(6, (index) => FocusNode());
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _sendOTP();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var focusNode in otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _resendTimer = 60;
    });
    
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3B4CB8),
              Color(0xFF4FC3D7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Verify Payment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Content Card
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Icon and Title
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.security,
                            size: 48,
                            color: Colors.blue[600],
                          ),
                        ),

                        SizedBox(height: 24),

                        Text(
                          'Payment Verification',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          'We\'ve sent a 6-digit verification code to your registered mobile number ending with ${_maskPhoneNumber(widget.applicationData['contact_number'])}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),

                        SizedBox(height: 32),

                        // OTP Input Fields
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(6, (index) {
                            return Container(
                              width: 45,
                              height: 55,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: otpFocusNodes[index].hasFocus 
                                      ? Color(0xFF4FC3D7) 
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: otpControllers[index],
                                focusNode: otpFocusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  border: InputBorder.none,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) {
                                  if (value.isNotEmpty && index < 5) {
                                    otpFocusNodes[index + 1].requestFocus();
                                  } else if (value.isEmpty && index > 0) {
                                    otpFocusNodes[index - 1].requestFocus();
                                  }
                                },
                              ),
                            );
                          }),
                        ),

                        SizedBox(height: 32),

                        // Resend OTP
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Didn\'t receive the code? ',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            if (_resendTimer > 0)
                              Text(
                                'Resend in ${_resendTimer}s',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: _isResending ? null : _resendOTP,
                                child: Text(
                                  _isResending ? 'Sending...' : 'Resend OTP',
                                  style: TextStyle(
                                    color: Color(0xFF4FC3D7),
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        Spacer(),

                        // Verify Button
                        Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _canVerify() ? _verifyOTP : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _canVerify()
                                  ? Color(0xFF2E3B69)
                                  : Colors.grey[400],
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: _isVerifying
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'VERIFY & COMPLETE PAYMENT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length > 4) {
      return '****${phoneNumber.substring(phoneNumber.length - 4)}';
    }
    return phoneNumber;
  }

  bool _canVerify() {
    return otpControllers.every((controller) => controller.text.isNotEmpty) && !_isVerifying;
  }

  String _getOTPString() {
    return otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _sendOTP() async {
    try {
      await http.post(
        Uri.parse('http://192.168.56.1:8000/payment/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'reference_number': widget.referenceNumber,
          'phone_number': widget.applicationData['contact_number'],
          'payment_id': widget.paymentId,
        }),
      );
    } catch (e) {
      // Handle error silently or show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send OTP: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isResending = true;
    });

    try {
      await _sendOTP();
      _startResendTimer();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    setState(() {
      _isVerifying = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.56.1:8000/payment/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'reference_number': widget.referenceNumber,
          'otp_code': _getOTPString(),
          'payment_id': widget.paymentId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Navigate to success screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ApplicationSuccessScreen(
              referenceNumber: widget.referenceNumber,
              applicationData: widget.applicationData,
              paymentData: responseData,
            ),
          ),
        );
      } else {
        throw Exception('OTP verification failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Clear OTP fields
      for (var controller in otpControllers) {
        controller.clear();
      }
      otpFocusNodes[0].requestFocus();
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }
}