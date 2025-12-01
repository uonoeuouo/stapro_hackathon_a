import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 日時フォーマットのために必要
// main.dart や 適切な画面をインポート
import 'confirm_page.dart';
import 'fare_registration_page.dart';

// 事前に定義したEmployeeDataクラスをインポート
import 'package:frontend/data/employee.dart';

class DepartureScreen extends StatefulWidget {
  final EmployeeData employeeData;

  const DepartureScreen({super.key, required this.employeeData});

  @override
  State<DepartureScreen> createState() => _DepartureScreenState();
}

class _DepartureScreenState extends State<DepartureScreen> {
  // 交通費精算用の状態管理
  int? _selectedFareIndex; // 選択肢 (0:なし, 1:手入力, 2:プリセット1, 3:プリセット2)
  int? _selectedKoma; // 選択されたコマ数
  int _manualFare = 0; // 手入力された交通費
  TextEditingController _fareController = TextEditingController();

  // フォームのキー
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fareController.addListener(() {
      // テキストフィールドの値が変更されたら、_manualFareを更新
      setState(() {
        _manualFare = int.tryParse(_fareController.text) ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _fareController.dispose();
    super.dispose();
  }

  // 最終的に登録する交通費の金額を取得
  int get _finalFare {
    if (_selectedFareIndex == 0) return 0; // なし
    if (_selectedFareIndex == 1) return _manualFare; // 手入力
    if (_selectedFareIndex != null && _selectedFareIndex! >= 2) {
      // プリセット
      return widget.employeeData.presetFares[_selectedFareIndex! - 2];
    }
    return 0;
  }

  void _navigateToConfirmation() {
    // 交通費が手入力の場合、フォームの検証を行う
    if (_selectedFareIndex == 1 && !_formKey.currentState!.validate()) {
      return;
    }

    // 退勤データを登録する処理（DB保存、API送信など）
    print('退勤時刻: ${DateTime.now()}');
    print('登録交通費: $_finalFare円');
    print('登録コマ数: $_selectedKomaコマ');

    // 確認画面へ遷移 (ここではダミーの確認画面を使用)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmationScreen(fare: _finalFare),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final clockIn = widget.employeeData.clockInTime;

    // 日付と時刻のフォーマット
    final dateFormat = DateFormat('yyyy/MM/dd');
    final timeFormat = DateFormat('HH:mm:ss');

    // 交通費の選択肢を生成
    final List<String> fareOptions = [
      'なし',
      '手入力',
      ...widget.employeeData.presetFares.map((fare) => '${fare}円'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('退勤処理'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              // 交通費登録画面へ遷移
              Navigator.push(
                context,
                MaterialPageRoute(
                  // FareRegistrationScreen は const コンストラクタを持つと仮定
                  builder: (context) => FareRegistrationScreen(
                    employeeData: widget.employeeData,
                  ),
                ),
              );
            },
            child: const Text(
              '交通費登録',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
          const SizedBox(width: 10), // 右端に少しスペースを空ける
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch, // 縦いっぱいに広げる
        children: <Widget>[
          // ==============================
          // 🔷 左側: 基本情報表示エリア (Expandedで均等に分割)
          // ==============================
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(30.0),
              color: Colors.blueGrey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'お疲れ様でした',
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow('社員名:', widget.employeeData.name),
                  _buildInfoRow('日付:', dateFormat.format(now)),
                  _buildInfoRow('出勤時刻:', timeFormat.format(clockIn)),
                  _buildInfoRow('退勤時刻:', timeFormat.format(now)),
                  const SizedBox(height: 30),
                  // 総労働時間などを計算して表示しても良い
                ],
              ),
            ),
          ),

          // ==============================
          // 🔶 右側: 交通費精算エリア (Expandedで均等に分割)
          // ==============================
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(30.0),
              color: Colors.white,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      '交通費精算',
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // 選択肢 (Radioボタン)
                    ...List.generate(fareOptions.length, (index) {
                      return RadioListTile<int>(
                        title: Text(fareOptions[index]),
                        value: index,
                        groupValue: _selectedFareIndex,
                        onChanged: (int? value) {
                          setState(() {
                            _selectedFareIndex = value;
                          });
                        },
                      );
                    }),

                    // 手入力フィールド (選択されている場合のみ表示)
                    if (_selectedFareIndex == 1)
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 15.0, right: 15.0, top: 10),
                        child: TextFormField(
                          controller: _fareController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '交通費 (円)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_selectedFareIndex == 1 &&
                                (value == null ||
                                    value.isEmpty ||
                                    int.tryParse(value) == null)) {
                              return '交通費を入力してください。';
                            }
                            return null;
                          },
                        ),
                      ),

                    const SizedBox(height: 30),

                    // コマ数選択 (交通費が選択されたら表示)
                    if (_selectedFareIndex != null) ...[
                      const Text(
                        '本日のコマ数',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10.0,
                        children: List.generate(5, (index) {
                          final koma = index + 1;
                          return ChoiceChip(
                            label: Text('$komaコマ'),
                            selected: _selectedKoma == koma,
                            onSelected: (bool selected) {
                              setState(() {
                                _selectedKoma = selected ? koma : null;
                              });
                            },
                          );
                        }),
                      ),
                    ],

                    const Spacer(), // 下部にボタンを配置するためにスペースを埋める

                    // 交通費登録ボタン
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed:
                            (_selectedFareIndex != null && _selectedKoma != null)
                                ? _navigateToConfirmation
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          textStyle: const TextStyle(fontSize: 20),
                        ),
                        child: Text(
                          _selectedFareIndex == null
                              ? '交通費を選択してください'
                              : _selectedKoma == null
                                  ? 'コマ数を選択してください'
                                  : '退勤登録と確認へ',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 情報表示用のヘルパーウィジェット
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
