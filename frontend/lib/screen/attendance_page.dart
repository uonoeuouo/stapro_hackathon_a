import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class AttendancePage extends StatefulWidget {
  final String userName;
  final Future<DateTime?> Function() onConfirm;

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
  final int _timeoutSeconds = 5; // Auto-confirm timeout
  bool _isSuccess = false;
  DateTime? _clockInTime;

  @override
  void initState() {
    super.initState();
    _startAutoConfirmTimer();
  }

  void _startAutoConfirmTimer() {
    // Wait 5 seconds then auto-confirm
    _timer = Timer(Duration(seconds: _timeoutSeconds), () {
      _performClockIn();
    });
  }

  Future<void> _performClockIn() async {
    _timer?.cancel();
    final dt = await widget.onConfirm();

    if (dt != null && mounted) {
      setState(() {
        _isSuccess = true;
        _clockInTime = dt;
      });

      // Wait 3 seconds then go back to home
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pop(context, dt);
        }
      });
    } else if (mounted) {
      // Failed or cancelled
      Navigator.pop(context, null);
    }
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

    if (_isSuccess) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ZoomIn(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 120,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeInUp(
                child: Text(
                  '出勤しました',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  '${widget.userName}さん',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 40),
              FadeIn(
                delay: const Duration(milliseconds: 1000),
                child: const Text(
                  'ホーム画面に戻ります...',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ZoomIn(
              duration: const Duration(milliseconds: 500),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.login_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 100,
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Text(
                'おはようございます、\n${widget.userName}さん！',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: Text(
                '出勤しますか？',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: Column(
                children: [
                  Text(
                    dateStr,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  Text(
                    timeStr,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            FadeIn(
              delay: const Duration(milliseconds: 1000),
              child: Column(
                children: [
                  Text(
                    '$_timeoutSeconds秒後に自動的に出勤します...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _performClockIn,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('今すぐ出勤', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
