import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String applicationId = '';
  String fullName = '';
  double amount = 0.0;
  String description = '';
  String school = '';
  String stream = '';
  
  String selectedPaymentMethod = '';
  bool isProcessing = false;
  
  final List<PaymentMethod> paymentMethods = [
    PaymentMethod(
      id: 'visa',
      name: 'Visa/Mastercard',
      icon: Icons.credit_card,
      description: 'Pay with your credit or debit card',
    ),
    PaymentMethod(
      id: 'bank_transfer',
      name: 'Bank Transfer',
      icon: Icons.account_balance,
      description: 'Direct bank transfer',
    ),
    PaymentMethod(
      id: 'digital_wallet',
      name: 'Digital Wallet',
      icon: Icons.account_balance_wallet,
      description: 'eZ Cash, Dialog Pay, etc.',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      applicationId = args['applicationId'] ?? '';
      fullName = args['fullName'] ?? '';
      amount = args['amount'] ?? 0.0;
      description = args['description'] ?? '';
      school = args['school'] ?? '';
      stream = args['stream'] ?? '';
    }
  }

  Future<void> _processPayment() async {
    if (selectedPaymentMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      // Simulate payment processing
      await Future.delayed(Duration(seconds: 3));
      
      // Here you would integrate with actual payment gateway
      // For now, we'll simulate a successful payment
      
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/al_schools/payment/confirm'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "application_id": applicationId,
          "payment_method": selectedPaymentMethod,
          "amount": amount,
          "status": "completed",
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Navigate to success page
        Navigator.pushNamed(
          context,
          '/payment-success',
          arguments: {
            'applicationId': applicationId,
            'fullName': fullName,
            'amount': amount,
            'paymentMethod': selectedPaymentMethod,
            'transactionId': responseData['transaction_id'] ?? 'TXN${DateTime.now().millisecondsSinceEpoch}',
            'school': school,
            'stream': stream,
          },
        );
      } else {
        throw Exception('Payment processing failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF3B4B8C),
      appBar: AppBar(
        backgroundColor: Color(0xFF3B4B8C),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payment',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B4B8C), Color(0xFF4A90E2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Payment Summary Header
              Container(
                margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.school, color: Color(0xFF3B4B8C), size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'A/L School Application',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3B4B8C),
                                ),
                              ),
                              Text(
                                'Application ID: $applicationId',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Application Fee',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'LKR ${amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B4B8C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Payment Methods
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Payment Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B4B8C),
                        ),
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: paymentMethods.length,
                          itemBuilder: (context, index) {
                            final method = paymentMethods[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedPaymentMethod = method.id;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: selectedPaymentMethod == method.id
                                            ? Color(0xFF3B4B8C)
                                            : Colors.grey[300]!,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: selectedPaymentMethod == method.id
                                          ? Color(0xFF3B4B8C).withOpacity(0.05)
                                          : Colors.white,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: selectedPaymentMethod == method.id
                                                ? Color(0xFF3B4B8C)
                                                : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            method.icon,
                                            color: selectedPaymentMethod == method.id
                                                ? Colors.white
                                                : Colors.grey[600],
                                            size: 24,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                method.name,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: selectedPaymentMethod == method.id
                                                      ? Color(0xFF3B4B8C)
                                                      : Colors.black87,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                method.description,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (selectedPaymentMethod == method.id)
                                          Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF3B4B8C),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pay Button
              Container(
                margin: EdgeInsets.all(20),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3B4B8C),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isProcessing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'PROCESSING PAYMENT...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'PAY LKR ${amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final IconData icon;
  final String description;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });
}