import 'dart:async';

/// Abstract interface for NFC card readers
/// Allows different implementations (Web Serial, Bluetooth, Mock, etc.)
abstract class NfcReaderInterface {
  /// Stream of card IDs detected by the reader
  Stream<String> get cardStream;

  /// Current connection status
  bool get isConnected;

  /// Initialize the reader (may prompt user for permissions)
  Future<void> initialize();

  /// Start listening for cards
  Future<void> startListening();

  /// Stop listening for cards
  Future<void> stopListening();

  /// Dispose resources
  Future<void> dispose();
}

/// Exception thrown when NFC reader operations fail
class NfcReaderException implements Exception {
  final String message;
  final dynamic originalError;

  NfcReaderException(this.message, [this.originalError]);

  @override
  String toString() =>
      'NfcReaderException: $message${originalError != null ? ' ($originalError)' : ''}';
}
