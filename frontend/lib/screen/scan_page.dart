// lib/main.dart または lib/screens/home_screen.dart に実装

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
// 出勤画面をインポート
import 'attendance_page.dart';
import '../data/employee.dart'; // Employee, EmployeeDataクラス定義用

//退勤画面をインポート
import 'departure_page.dart';
// fare_registration_page.dartは不要になったため削除
import 'card_registrate_page.dart';

// API Service
import '../services/api_service.dart';

// Card Reader Service
import '../services/card_reader_service.dart';

// 出勤時刻を記録(退勤時に使用)
DateTime? clockInTime;

// ホーム画面(カードリーダーイベントを処理する場所)
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  // カードリーダー関連
  CardReaderType _selectedReaderType = CardReaderType.keyboard;
  late NfcCardReader _nfcReader;
  late KeyboardCardReader _keyboardReader;
  late ManualCardReader _manualReader;
  StreamSubscription<String>? _cardIdSubscription;
  bool _nfcAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeCardReaders();
  }

  @override
  void dispose() {
    _cardIdSubscription?.cancel();
    _nfcReader.dispose();
    _keyboardReader.dispose();
    _manualReader.dispose();
    super.dispose();
  }

  // カードリーダーを初期化
  Future<void> _initializeCardReaders() async {
    _nfcReader = NfcCardReader();
    _keyboardReader = KeyboardCardReader();
    _manualReader = ManualCardReader();

    // NFCが利用可能かチェック
    _nfcAvailable = await _nfcReader.isAvailable();
    
    if (_nfcAvailable) {
      setState(() {
        _selectedReaderType = CardReaderType.nfc;
      });
    }

    // 選択されたリーダーを開始
    await _startSelectedReader();
  }

  // 選択されたカードリーダーを開始
  Future<void> _startSelectedReader() async {
    // 既存のサブスクリプションをキャンセル
    await _cardIdSubscription?.cancel();

    // すべてのリーダーを停止
    await _nfcReader.stop();
    await _keyboardReader.stop();
    await _manualReader.stop();

    // 選択されたリーダーを開始してストリームを購読
    switch (_selectedReaderType) {
      case CardReaderType.nfc:
        await _nfcReader.start();
        _cardIdSubscription = _nfcReader.cardIdStream.listen(_onCardScanned);
        break;
      case CardReaderType.keyboard:
        await _keyboardReader.start();
        _cardIdSubscription = _keyboardReader.cardIdStream.listen(_onCardScanned);
        break;
      case CardReaderType.manual:
        await _manualReader.start();
        _cardIdSubscription = _manualReader.cardIdStream.listen(_onCardScanned);
        break;
    }
  }

  // カードがスキャンされた時の処理
  void _onCardScanned(String scannedCardId) async {
    if (_isLoading) return; // 既に処理中の場合は無視

    print('カードがスキャンされました: $scannedCardId');

    // ローディング状態を表示
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // API呼び出し
      final response = await _apiService.scanCard(scannedCardId);

      setState(() {
        _isLoading = false;
      });

      // ステータスに応じて画面遷移
      if (response.status == 'ready_to_in') {
        // 出勤処理へ遷移
        clockInTime = DateTime.now();
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AttendanceScreen(
              employee: Employee(
                id: 'EMP_API', // APIから取得できないため仮のID
                name: response.userName,
                department: '部署未設定', // APIから取得できないため仮の部署
              ),
            ),
          ),
        );
      } else if (response.status == 'ready_to_out') {
        // 退勤処理へ遷移
        // プリセット交通費をList<int>に変換
        final presetFares = response.transportPresets?.map((preset) {
          return preset.amount;
        }).toList() ?? <int>[];

        final employeeData = EmployeeData(
          name: response.userName,
          clockInTime: clockInTime ?? DateTime.now(),
          presetFares: presetFares,
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DepartureScreen(
              employeeData: employeeData,
            ),
          ),
        );
      }
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (e.response?.statusCode == 404) {
        // カード未登録の場合、カード登録画面へ遷移
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CardRegistratePage(
              cardId: scannedCardId,
            ),
          ),
        );
      } else {
        // その他のエラー
        setState(() {
          _errorMessage = 'エラーが発生しました: ${e.message}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '予期しないエラーが発生しました: $e';
      });
    }
  }

  // リーダータイプを変更
  void _changeReaderType(CardReaderType? newType) {
    if (newType == null || newType == _selectedReaderType) return;
    
    setState(() {
      _selectedReaderType = newType;
    });
    
    _startSelectedReader();
  }

  // 手動入力ダイアログを表示
  void _showManualInput() {
    _manualReader.showInputDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: (event) {
        if (_selectedReaderType == CardReaderType.keyboard) {
          _keyboardReader.handleKeyEvent(event);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('カードリーダーシステム'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // カードリーダータイプ選択
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      '読み取り方法',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<CardReaderType>(
                      value: _selectedReaderType,
                      items: [
                        if (_nfcAvailable)
                          const DropdownMenuItem(
                            value: CardReaderType.nfc,
                            child: Row(
                              children: [
                                Icon(Icons.nfc),
                                SizedBox(width: 8),
                                Text('NFC/Felica'),
                              ],
                            ),
                          ),
                        const DropdownMenuItem(
                          value: CardReaderType.keyboard,
                          child: Row(
                            children: [
                              Icon(Icons.keyboard),
                              SizedBox(width: 8),
                              Text('USBキーボード入力'),
                            ],
                          ),
                        ),
                        const DropdownMenuItem(
                          value: CardReaderType.manual,
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('手動入力'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: _changeReaderType,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              if (_isLoading)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      'カード情報を確認中...',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                )
              else ...[
                // 読み取り方法に応じた説明文
                Icon(
                  _selectedReaderType == CardReaderType.nfc
                      ? Icons.nfc
                      : _selectedReaderType == CardReaderType.keyboard
                          ? Icons.keyboard
                          : Icons.edit,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),
                Text(
                  _getInstructionText(),
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // 手動入力の場合のみボタンを表示
                if (_selectedReaderType == CardReaderType.manual)
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _showManualInput,
                    icon: const Icon(Icons.edit),
                    label: const Text(
                      'カードIDを入力',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                    ),
                  ),
                
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getInstructionText() {
    switch (_selectedReaderType) {
      case CardReaderType.nfc:
        return 'カードをかざしてください';
      case CardReaderType.keyboard:
        return 'カードをスキャンしてください\n(USBカードリーダー)';
      case CardReaderType.manual:
        return '下のボタンをタップして\nカードIDを入力してください';
    }
  }
}

