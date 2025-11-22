// Stub for non-web platforms
// This file is imported when dart:io is available (non-web)

import 'dart:async';
import 'nfc_reader_interface.dart';

class Serial {
  Future<dynamic> requestPort([dynamic options]) async {
    throw UnsupportedError('Web Serial API is only available on web platforms');
  }

  Future<List<dynamic>> getPorts() async {
    throw UnsupportedError('Web Serial API is only available on web platforms');
  }
}

class SerialPortRequestOptions {
  SerialPortRequestOptions({dynamic filters});
}

class SerialPortFilter {
  SerialPortFilter({int? usbVendorId, int? usbProductId});
}

class SerialPort {
  Future<void> open(dynamic options) async {
    throw UnsupportedError('Web Serial API is only available on web platforms');
  }

  Future<void> close() async {
    throw UnsupportedError('Web Serial API is only available on web platforms');
  }

  dynamic get readable => throw UnsupportedError(
    'Web Serial API is only available on web platforms',
  );
  dynamic get writable => throw UnsupportedError(
    'Web Serial API is only available on web platforms',
  );
}

class SerialOptions {
  SerialOptions({
    required int baudRate,
    int? dataBits,
    int? stopBits,
    String? parity,
  });
}

Serial get serial => Serial();

/// Stub implementation of WebSerialNfcReader for non-web platforms
/// This class should never be instantiated on non-web platforms
class WebSerialNfcReader implements NfcReaderInterface {
  WebSerialNfcReader() {
    throw UnsupportedError(
      'WebSerialNfcReader is only available on web platforms. '
      'Use MockNfcReaderImpl or platform-specific implementation instead.',
    );
  }

  @override
  Stream<String> get cardStream => throw UnsupportedError(
    'WebSerialNfcReader is only available on web platforms',
  );

  @override
  bool get isConnected => throw UnsupportedError(
    'WebSerialNfcReader is only available on web platforms',
  );

  @override
  Future<void> initialize() async {
    throw UnsupportedError(
      'WebSerialNfcReader is only available on web platforms',
    );
  }

  @override
  Future<void> startListening() async {
    throw UnsupportedError(
      'WebSerialNfcReader is only available on web platforms',
    );
  }

  @override
  Future<void> stopListening() async {
    throw UnsupportedError(
      'WebSerialNfcReader is only available on web platforms',
    );
  }

  @override
  Future<void> dispose() async {
    throw UnsupportedError(
      'WebSerialNfcReader is only available on web platforms',
    );
  }
}
