import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'nfc_reader_interface.dart';

/// Stub implementation of PcscNfcReader for web platforms
/// This class should never be instantiated on web platforms
class PcscNfcReader implements NfcReaderInterface {
  PcscNfcReader(Ref ref) {
    throw UnsupportedError('PcscNfcReader is not available on web platforms.');
  }

  @override
  Stream<String> get cardStream =>
      throw UnsupportedError('PcscNfcReader is not available on web platforms');

  @override
  bool get isConnected =>
      throw UnsupportedError('PcscNfcReader is not available on web platforms');

  @override
  Future<void> initialize() async {
    throw UnsupportedError('PcscNfcReader is not available on web platforms');
  }

  @override
  Future<void> startListening() async {
    throw UnsupportedError('PcscNfcReader is not available on web platforms');
  }

  @override
  Future<void> stopListening() async {
    throw UnsupportedError('PcscNfcReader is not available on web platforms');
  }

  @override
  Future<void> dispose() async {
    throw UnsupportedError('PcscNfcReader is not available on web platforms');
  }
}
