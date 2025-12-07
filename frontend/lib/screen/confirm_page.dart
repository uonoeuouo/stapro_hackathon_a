import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // MyAppをインポート
import 'dart:async';

class ConfirmationScreen extends StatefulWidget {
  final int fare;
  final int timeoutSeconds = 3; // Changed to 3 seconds

  const ConfirmationScreen({super.key, required this.fare});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 3秒後に自動遷移するタイマーを開始
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
        builder: (context) => MyApp(initialClassroom: savedClassroom),
      ),
      (Route<dynamic> route) => false, // すべてのルートを削除
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ZoomIn(
              duration: const Duration(milliseconds: 500),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: Colors.orange,
                  size: 100,
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              child: Text(
                '退勤しました',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Text(
                'お疲れ様でした！',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '登録交通費: ${widget.fare}円',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            FadeIn(
              delay: const Duration(milliseconds: 1000),
              child: Text(
                'ホーム画面に戻ります...',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
