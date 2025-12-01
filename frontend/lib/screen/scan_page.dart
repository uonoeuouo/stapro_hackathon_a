// lib/main.dart または lib/screens/home_screen.dart に実装

import 'package:flutter/material.dart';
// 出勤画面をインポート
import 'attendance_page.dart';
import '../data/employee.dart'; // Mockデータをインポート

//退勤画面をインポート
import 'departure_page.dart';
import 'fare_registration_page.dart';

// 出勤状態を管理する変数（グローバル変数、または状態管理ツールを使用するのが望ましい）
int attendanceStatus = 0; // 0: 未出勤, 1: 出勤済み

// ホーム画面（カードリーダーイベントを処理する場所）
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  // attendanceStatusを更新する関数
  void _updateStatus(int newStatus) {
    setState(() {
      attendanceStatus = newStatus;
    });
    print('出勤状態が更新されました: $attendanceStatus');
  }

  // カードリーダーイベントをシミュレーションする関数
  void _onCardScanned() {
    print('カードがスキャンされました。現在の状態: $attendanceStatus');

    if (attendanceStatus == 0) {
      // 状態が 0 (未出勤) の場合、出勤画面へ遷移
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AttendanceScreen(
            updateAttendanceStatus: _updateStatus, // 状態更新関数を渡す
            employee: mockEmployee, // Mockデータを渡す
          ),
        ),
      );
      // 注意: attendanceStatus = 1 の設定は AttendanceScreen の initState 内で行われます。
    } else if (attendanceStatus == 1) {
      // 退勤処理へ遷移
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DepartureScreen(
            // 必要なデータ（出勤時刻、名前など）を渡す
            employeeData: mockEmployeeData,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カードリーダーシステム'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              attendanceStatus == 0 ? '未出勤です。カードをかざしてください。' : '出勤済みです。',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 40),
            // カードリーダーのイベント発生ボタン（シミュレーション）
            ElevatedButton.icon(
              onPressed: _onCardScanned,
              icon: const Icon(Icons.credit_card),
              label: const Text(
                'カードリーダーイベント発生 (タップ)',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
