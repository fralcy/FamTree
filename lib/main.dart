import 'package:flutter/material.dart';

void main() {
  runApp(const FamTreeApp());
}

class FamTreeApp extends StatelessWidget {
  const FamTreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fam Tree',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(body: Center(child: Text('Fam Tree'))),
    );
  }
}
