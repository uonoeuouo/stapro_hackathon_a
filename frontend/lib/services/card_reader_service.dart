import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';

/// カード読み取り方法の種類
enum CardReaderType {
  nfc,      // NFC/Felicaカード
  keyboard, // USBキーボード入力
  manual,   // 手動入力
}

/// カードリーダーサービスの抽象クラス
abstract class CardReaderService {
  /// カードIDのストリーム
  Stream<String> get cardIdStream;

  /// カードリーダーを開始
  Future<void> start();

  /// カードリーダーを停止
  Future<void> stop();

  /// 利用可能かどうか
  Future<bool> isAvailable();
}

/// NFC/Felicaカードリーダー
class NfcCardReader implements CardReaderService {
  final _cardIdController = StreamController<String>.broadcast();
  bool _isReading = false;

  @override
  Stream<String> get cardIdStream => _cardIdController.stream;

  @override
  Future<bool> isAvailable() async {
    // NFCはモバイルプラットフォームでのみ利用可能
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }
    try {
      // ignore: deprecated_member_use
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      // ignore: avoid_print
      print('NFC not supported on this platform: $e');
      return false;
    }
  }

  @override
  Future<void> start() async {
    if (_isReading) return;

    final available = await isAvailable();
    if (!available) {
      // ignore: avoid_print
      print('NFC is not available on this device');
      return;
    }

    _isReading = true;
    _startNfcSession();
  }

  void _startNfcSession() {
    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      },
      onDiscovered: (NfcTag tag) async {
        try {
          // カードのIDを取得 - tag.hashCodeを16進数文字列として使用
          // 実際の運用では、tag.dataから適切なIDを抽出する必要があります
          final cardId = 'nfc_${tag.hashCode.toRadixString(16)}';
          
          // ignore: avoid_print
          print('NFC Card detected: $cardId');
          _cardIdController.add(cardId);
          
          // セッションを停止して再開
          await NfcManager.instance.stopSession();
          if (_isReading) {
            // 少し待ってから次のセッションを開始
            await Future.delayed(const Duration(milliseconds: 500));
            _startNfcSession();
          }
        } catch (e) {
          // ignore: avoid_print
          print('Error reading NFC card: $e');
          await NfcManager.instance.stopSession();
          if (_isReading) {
            await Future.delayed(const Duration(milliseconds: 500));
            _startNfcSession();
          }
        }
      },
    );
  }

  @override
  Future<void> stop() async {
    _isReading = false;
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await NfcManager.instance.stopSession();
      } catch (e) {
        // ignore: avoid_print
        print('Error stopping NFC session: $e');
      }
    }
  }

  void dispose() {
    stop();
    _cardIdController.close();
  }
}

/// USBキーボード入力リーダー
class KeyboardCardReader implements CardReaderService {
  final _cardIdController = StreamController<String>.broadcast();
  final _buffer = StringBuffer();
  bool _isListening = false;

  @override
  Stream<String> get cardIdStream => _cardIdController.stream;

  @override
  Future<bool> isAvailable() async {
    // キーボード入力は常に利用可能
    return true;
  }

  @override
  Future<void> start() async {
    _isListening = true;
    // ignore: avoid_print
    print('Keyboard card reader started');
  }

  @override
  Future<void> stop() async {
    _isListening = false;
    _buffer.clear();
  }

  /// キーイベントを処理
  void handleKeyEvent(KeyEvent event) {
    if (!_isListening) return;
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    // Enterキーが押された場合、バッファの内容を送信
    if (key == LogicalKeyboardKey.enter) {
      final cardId = _buffer.toString().trim();
      if (cardId.isNotEmpty) {
        // ignore: avoid_print
        print('Keyboard card detected: $cardId');
        _cardIdController.add(cardId);
        _buffer.clear();
      }
    }
    // 数字、アルファベット、アンダースコア、ハイフンを受け付ける
    else if (event.character != null) {
      final char = event.character!;
      if (RegExp(r'[a-zA-Z0-9_\-]').hasMatch(char)) {
        _buffer.write(char);
      }
    }
    // バックスペースの処理
    else if (key == LogicalKeyboardKey.backspace) {
      if (_buffer.isNotEmpty) {
        final currentText = _buffer.toString();
        _buffer.clear();
        _buffer.write(currentText.substring(0, currentText.length - 1));
      }
    }
  }

  void dispose() {
    stop();
    _cardIdController.close();
  }
}

/// 手動入力リーダー
class ManualCardReader implements CardReaderService {
  final _cardIdController = StreamController<String>.broadcast();

  @override
  Stream<String> get cardIdStream => _cardIdController.stream;

  @override
  Future<bool> isAvailable() async {
    return true;
  }

  @override
  Future<void> start() async {
    // 手動入力は常にアクティブ
  }

  @override
  Future<void> stop() async {
    // 何もしない
  }

  /// 手動でカードIDを入力
  Future<void> showInputDialog(BuildContext context) async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カードID入力'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'カードID',
            hintText: 'test_card_001',
          ),
          onSubmitted: (value) {
            Navigator.of(context).pop(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(controller.text);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      // ignore: avoid_print
      print('Manual card input: $result');
      _cardIdController.add(result);
    }
  }

  void dispose() {
    _cardIdController.close();
  }
}
