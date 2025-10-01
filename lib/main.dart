import 'package:flutter/material.dart';
import 'pages/DisplayOutput.dart';

void main() {
  runApp(const CurrPage());
}

class CurrPage extends StatelessWidget {
  const CurrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmPolair',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DisplayOutputPage(),
    );
  }
}