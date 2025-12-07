import 'package:flutter/material.dart';

class CardRegistratePage extends StatefulWidget {
  final String cardId; // スキャンされたカードID

  const CardRegistratePage({
    super.key,
    required this.cardId,
  });

  @override
  State<CardRegistratePage> createState() => _CardRegistratePageState();
}

class _CardRegistratePageState extends State<CardRegistratePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _mailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _registerCard() {
    if (_formKey.currentState!.validate()) {
      // カード登録処理(バックエンドAPIへ送信)
      print('カードID: ${widget.cardId}');
      print('メールアドレス: ${_mailController.text}');
      print('パスワード: ${_passwordController.text}');

      // TODO: バックエンドAPIへPOSTリクエストを送信
      // 登録成功後、適切な画面へ遷移
      
      // 登録完了のダイアログを表示
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('登録完了'),
          content: const Text('カードの登録が完了しました。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
                Navigator.of(context).pop(); // カード登録画面を閉じる
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カード登録'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(40.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // アイコン
                Icon(
                  Icons.credit_card_off,
                  size: 80,
                  color: Colors.orange[700],
                ),
                const SizedBox(height: 30),

                // メッセージ1
                const Text(
                  'カードが未登録です',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 10),

                // メッセージ2
                const Text(
                  'カードを登録してください',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 40),

                // カードID表示
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card, color: Colors.blueGrey),
                      const SizedBox(width: 10),
                      Text(
                        'カードID: ${widget.cardId}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // メールアドレス入力
                TextFormField(
                  controller: _mailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'メールアドレス',
                    hintText: 'example@example.com',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'メールアドレスを入力してください';
                    }
                    // 簡易的なメールアドレスのバリデーション
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return '有効なメールアドレスを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // パスワード入力
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    hintText: 'パスワードを入力',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワードを入力してください';
                    }
                    //if (value.length < 6) {
                        //return 'パスワードは6文字以上で入力してください';
                    //}
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // 登録ボタン
                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _registerCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                    child: const Text(
                      'カードを登録',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
