import 'package:flutter/material.dart';
import 'dart:async'; // Timerを使うために必要

import 'scan_page.dart';
import '../services/scan_service.dart';
import '../data/employee.dart';
class RegistrationSuccessScreen extends StatefulWidget {
  final String registeredName;
  final int registeredFare;
  final EmployeeData employeeData;

  const RegistrationSuccessScreen({
    super.key,
    required this.registeredName,
    required this.registeredFare,
    required this.employeeData,
  });

  @override
  State<RegistrationSuccessScreen> createState() =>
      _RegistrationSuccessScreenState();
}

class _RegistrationSuccessScreenState extends State<RegistrationSuccessScreen> {
  Timer? _timer;
  final int _timeoutSeconds = 3; // タイムアウト時間

  @override
  void initState() {
    super.initState();
    // 画面表示後、5秒後にホーム画面へ自動遷移
    _startTimeoutTimer();
  }

  void _startTimeoutTimer() {
    _timer = Timer(Duration(seconds: _timeoutSeconds), () {
      _navigateToScanPage();
    });
  }

  void _navigateToScanPage() {
    // 登録完了後はスキャン画面（ホーム）へ戻す
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => ScanPage(scanService: RealScanService()),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    // 画面が破棄されるときにタイマーを停止する
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登録完了'),
        automaticallyImplyLeading: false, // 戻るボタンを非表示
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 100,
            ),
            const SizedBox(height: 30),
            const Text(
              '交通費プリセットを登録しました！',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              '登録名: ${widget.registeredName}',
              style: const TextStyle(fontSize: 20),
            ),
            Text(
              '登録金額: ${widget.registeredFare}円',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 40),
            Text(
              '退勤登録画面に戻ります',
              style: const TextStyle(fontSize: 16, color: Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }
}
