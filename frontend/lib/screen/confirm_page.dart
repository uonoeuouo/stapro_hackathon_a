import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // MyAppをインポート
import 'dart:async';

class ConfirmationScreen extends StatefulWidget {
  final int fare;
  final int timeoutSeconds = 5;

  const ConfirmationScreen({super.key, required this.fare});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 5秒後に自動遷移するタイマーを開始
    _startTimeoutTimer();
  }

  @override
  void dispose() {
    // 画面が破棄される前にタイマーをキャンセル
    _timer?.cancel();
    super.dispose();
  }

  void _startTimeoutTimer() {
    _timer = Timer(Duration(seconds: widget.timeoutSeconds), () {
      _navigateToHome();
    });
  }

  Future<void> _navigateToHome() async {
    // SharedPreferencesから保存された教室名を取得
    final prefs = await SharedPreferences.getInstance();
    final savedClassroom = prefs.getString('selected_classroom');
    if (!mounted) return;
    // Navigator.popAll を使って、ルート（ホーム画面）以外のすべての画面を閉じる
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          // 取得した savedClassroom を渡す
          builder: (context) => MyApp(initialClassroom: savedClassroom)),
      (Route<dynamic> route) => false, // すべてのルートを削除
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('退勤確認')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.celebration, color: Colors.amber, size: 80),
            const SizedBox(height: 20),
            const Text(
              '退勤処理が完了しました！',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              '登録交通費: ${widget.fare}円',
              style: const TextStyle(fontSize: 24, color: Colors.green),
            ),
            Text(
              '${widget.timeoutSeconds}秒後に自動的にホーム画面に戻ります...',
              style: const TextStyle(fontSize: 14, color: Colors.blueAccent),
            ),
            const SizedBox(height: 40),
            // 緊急でホームに戻るためのボタン（任意）
            ElevatedButton(
              onPressed: _navigateToHome,
              child: const Text('今すぐホーム画面に戻る'),
            ),
          ],
        ),
      ),
    );
  }
}