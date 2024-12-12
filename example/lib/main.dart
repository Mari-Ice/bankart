import 'package:flutter/material.dart';
import 'package:bankart/bankart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';



  @override
  void initState() {
    super.initState();

   // initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.

  void onPay() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment successful!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
            Bankart('your-shared-secret',
            onSuccess: (token) => print('Tokenization successful! Token: $token)'),
            onError: (error) => print('Tokenization error! Error: $error'),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
