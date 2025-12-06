import 'package:flutter/material.dart';

class AttendancePage extends StatelessWidget {
  final String userName;
  final VoidCallback onConfirm;

  const AttendancePage({
    super.key,
    required this.userName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('出勤確認'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              'おはようございます、\n$userNameさん！',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '出勤しますか？',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: const Text('出勤する', style: TextStyle(fontSize: 24)),
            ),
             const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Cancel
              child: const Text('キャンセル', style: TextStyle(fontSize: 18, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
