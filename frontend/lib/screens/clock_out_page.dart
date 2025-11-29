import 'package:flutter/material.dart';

class ClockOutPage extends StatelessWidget {
  final String userName;
  final String cardId;
  final DateTime clockInTime;
  final DateTime clockOutTime;
  final VoidCallback onConfirm;

  const ClockOutPage({
    super.key,
    required this.userName,
    required this.cardId,
    required this.clockInTime,
    required this.clockOutTime,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final duration = clockOutTime.difference(clockInTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Scaffold(
      appBar: AppBar(title: const Text('退勤 (Clock Out)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('お疲れ様でした, $userName さん', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text('Card ID: $cardId', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            const Icon(Icons.logout, size: 100, color: Colors.orange),
            const SizedBox(height: 20),
            Text(
              '退勤時間: ${clockOutTime.hour.toString().padLeft(2, '0')}:${clockOutTime.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '業務時間: $hours時間 $minutes分',
              style: const TextStyle(fontSize: 20, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: const Text('退勤を確定する', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
