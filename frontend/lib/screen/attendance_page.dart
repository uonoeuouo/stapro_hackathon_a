import 'package:flutter/material.dart';
import 'dart:async'; // タイマーを使うために必要
import '../data/employee.dart'; // Employeeモデルをインポート
import '../main.dart'; // プロジェクト名に合わせて修正してください

class AttendanceScreen extends StatefulWidget {
  final Employee employee;

  const AttendanceScreen({
    super.key,
    required this.employee,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now(); // 現在の日時を保持
  final int _timeoutSeconds = 5; // タイムアウト時間（5秒）

  @override
  void initState() {
    super.initState();
    // 画面が表示された瞬間に実行

    // 5秒後にホーム画面へ自動遷移するタイマーを開始
    _startTimeoutTimer();
  }

  void _startTimeoutTimer() {
    _timer = Timer(Duration(seconds: _timeoutSeconds), () {
      // 5秒経過したら実行される処理
      _navigateToHome();
    });
  }

  void _navigateToHome() {
    // Navigator.popAll を使って、ルート（ホーム画面）以外のすべての画面を閉じる
    // 今回は main.dart の MyApp() がルートだと仮定して、そこに戻ります。
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (context) => MyApp()), // MyApp はホーム画面のウィジェットに置き換えてください
      (Route<dynamic> route) => false, // すべてのルートを削除
    );
  }

  @override
  void dispose() {
    // 画面が閉じられるときにタイマーを停止する（メモリリーク防止）
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 日付と時刻のフォーマット
    String dateStr = '${_now.year}年${_now.month}月${_now.day}日';
    String timeStr =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('出勤完了'),
        automaticallyImplyLeading: false, // 戻るボタンを非表示にする
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
              'おはようございます、\n${widget.employee.name}さん！',
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
          ],
        ),
      ),
    );
  }
}
