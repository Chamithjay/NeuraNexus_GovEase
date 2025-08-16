import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/advacedlevel/al_start_screen.dart';
import 'package:flutter_application_1/screens/advacedlevel/stream_selection_screen.dart' show StreamSelectionScreen;
import 'screens/grade1/education_main_screen.dart';
import 'screens/advacedlevel/application_form_screen.dart';
import 'screens/advacedlevel/school_selection_screen.dart';
import 'screens/advacedlevel/summary_screen.dart';
import 'screens/advacedlevel/payment_screen.dart';
import 'screens/advacedlevel/payment_success.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: EducationalServicesScreen(),
    routes: {
      '/education-main': (context) => EducationalServicesScreen(),
      '/advanced-level': (context) => WelcomeScreen(),
      '/stream-selection': (context) => StreamSelectionScreen(),
      '/application-form': (context) => ApplicationFormScreen(selectedStream: ModalRoute.of(context)?.settings.arguments as String?),
      '/school-selection': (context) => SchoolSelectionScreen(),
      '/summary-screen': (context) => SummaryScreen(),
      '/payment': (context) => PaymentScreen(),
      '/payment-success': (context) => ALPaymentSuccessScreen(),
    },
    
  ));
}