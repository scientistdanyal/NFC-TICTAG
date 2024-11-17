import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For MethodChannel
import 'package:provider/provider.dart';
import 'providers/api_provider.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const platform = MethodChannel('com.example.nfc');

  @override
  void initState() {
    super.initState();
    // _setupNfcListener();
  }
  // void _setupNfcListener() {
  //   platform.setMethodCallHandler((call) async {
  //     if (call.method == 'onNfcDetected') {
  //       // Received NFC data from the native side
  //       String tagData = call.arguments;
  //       print('NFC Tag Detected in Dashboard: $tagData');
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => APIProvider(),
      child: Consumer<APIProvider>(builder: (context, apiProvider, child) {
        return MaterialApp(
          title: 'Flutter App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: apiProvider.headers != null ? DashboardPage() : LoginPage(),
          debugShowCheckedModeBanner: false,
        );
      }),
    );
  }
}
