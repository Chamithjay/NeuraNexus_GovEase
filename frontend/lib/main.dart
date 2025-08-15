import 'package:flutter/material.dart';
import 'screens/search_hotels_page.dart';
import 'screens/bungalows_list_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bungalow Search',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          // remove const if SearchHotelsPage constructor is not const
          return MaterialPageRoute(builder: (context) => SearchHotelsPage());
        } else if (settings.name == '/results') {
          // cast arguments safely
          final args = settings.arguments as List<dynamic>?; 
          if (args != null) {
            return MaterialPageRoute(
              builder: (context) => BungalowsListPage(bungalows: args),
            );
          }
        }
        return null;
      },
    );
  }
}
