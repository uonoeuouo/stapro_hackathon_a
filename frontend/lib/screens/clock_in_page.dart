import 'package:flutter/material.dart';

class ClockInPage extends StatelessWidget {
  final String userName;
  final VoidCallback onConfirm;

  const ClockInPage({
    super.key,
    required this.userName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('出勤 (Clock In)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('こんにちは, $userName さん', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            const Icon(Icons.login, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text('出勤しますか？', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: const Text('出勤する', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
