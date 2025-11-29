import 'package:flutter/material.dart';
import 'screens/scan_page.dart';
import 'services/scan_service.dart';

void main() {
  runApp(const ScanApp());
}

class ScanApp extends StatelessWidget {
  const ScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Change this to false to use the real backend
    bool useMock = true;

    return MaterialApp(
      title: 'Card Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: ScanPage(
        scanService: useMock ? MockScanService() : RealScanService(),
      ),
    );
  }
}
