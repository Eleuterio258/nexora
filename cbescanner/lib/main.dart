import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const CbEscannerApp());
}

class CbEscannerApp extends StatelessWidget {
  const CbEscannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CB Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
