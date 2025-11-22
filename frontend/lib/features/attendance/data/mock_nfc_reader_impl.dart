import 'dart:async';
import 'nfc_reader_interface.dart';

/// Mock NFC reader implementation for testing and development
class MockNfcReaderImpl implements NfcReaderInterface {
  final StreamController<String> _cardController =
      StreamController<String>.broadcast();
  bool _isConnected = false;
  bool _isListening = false;

  @override
  Stream<String> get cardStream => _cardController.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> initialize() async {
    // Simulate initialization delay
    await Future.delayed(const Duration(milliseconds: 500));
    _isConnected = true;
  }

  @override
  Future<void> startListening() async {
    if (!_isConnected) {
      throw NfcReaderException('Reader not initialized');
    }
    _isListening = true;
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
  }

  @override
  Future<void> dispose() async {
    _isListening = false;
    _isConnected = false;
    await _cardController.close();
  }

  /// Simulate card tap (for testing)
  void simulateCardTap(String cardId) {
    if (_isListening && !_cardController.isClosed) {
      _cardController.add(cardId);
    }
  }
}
