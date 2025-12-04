import 'package:flutter/material.dart';
import '../data/employee.dart';
import 'registrate_success_page.dart'; 

class FareRegistrationScreen extends StatefulWidget {
  final EmployeeData employeeData;

  const FareRegistrationScreen({super.key, required this.employeeData});

  @override
  State<FareRegistrationScreen> createState() => _FareRegistrationScreenState();
}

class _FareRegistrationScreenState extends State<FareRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fareController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  // 登録処理
  void _registerFare() {
    if (_formKey.currentState!.validate()) {
      // フォームの検証が成功した場合
      final String name = _nameController.text;
      final int fare = int.parse(_fareController.text);

      // ここで本来はDBなどに登録処理を行う
      // Mockデータに追加
      widget.employeeData.presetFares.add(fare);

      // 登録完了画面へ遷移
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationSuccessScreen(
            registeredName: name,
            registeredFare: fare,
            employeeData: widget.employeeData,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('交通費プリセット登録'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // 登録名入力フィールド
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '登録名 (例: 自宅〜会社)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '登録名を入力してください。';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 交通費（数字）入力フィールド
                TextFormField(
                  controller: _fareController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '交通費 (円)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '金額を入力してください。';
                    }
                    if (int.tryParse(value) == null) {
                      return '有効な数字を入力してください。';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // 登録ボタン
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _registerFare,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text('登録する',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
