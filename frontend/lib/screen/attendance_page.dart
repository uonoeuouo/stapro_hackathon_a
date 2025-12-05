import 'package:flutter/material.dart';
import 'dart:async';

class AttendancePage extends StatefulWidget {
  final String userName;
  final VoidCallback onConfirm;

  const AttendancePage({
    super.key,
    required this.userName,
    required this.onConfirm,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  Timer? _timer;
  final int _timeoutSeconds = 5;

  @override
  void initState() {
    super.initState();
    _startTimeoutTimer();
  }

  void _startTimeoutTimer() {
    _timer = Timer(Duration(seconds: _timeoutSeconds), () {
      widget.onConfirm();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String dateStr = '${now.year}年${now.month}月${now.day}日';
    String timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('出勤完了'),
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
              'おはようございます、\n${widget.userName}さん！',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '出勤しました！',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              dateStr,
              style: const TextStyle(fontSize: 20, color: Colors.grey),
            ),
            Text(
              timeStr,
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 40),
            Text(
              '$_timeoutSeconds秒後に自動的にホーム画面に戻ります...',
              style: const TextStyle(fontSize: 14, color: Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: widget.onConfirm,
              child: const Text('ホームへ戻る'),
            ),
          ],
        ),
      ),
    );
  }
}
