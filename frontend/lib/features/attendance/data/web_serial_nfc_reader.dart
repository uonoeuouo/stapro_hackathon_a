import 'dart:async';
import 'dart:typed_data';
import 'nfc_reader_interface.dart';
import 'web_serial_interop.dart' if (dart.library.io) 'web_serial_stub.dart';

/// Web Serial API implementation for PaSoRi NFC reader
/// Supports FeliCa cards (common in Japan)
class WebSerialNfcReader implements NfcReaderInterface {
  final StreamController<String> _cardController =
      StreamController<String>.broadcast();
  SerialPort? _port;
  bool _isConnected = false;
  bool _isListening = false;
  Timer? _pollingTimer;

  @override
  Stream<String> get cardStream => _cardController.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> initialize() async {
    try {
      // Request user to select serial device
      // Note: Removed vendor/product ID filter to show all available devices
      // This allows flexibility for different PaSoRi models and other NFC readers
      _port = await serial.requestPort();

      // Open serial port with PaSoRi settings
      await _port!.open(
        SerialOptions(
          baudRate: 115200,
          dataBits: 8,
          stopBits: 1,
          parity: 'none',
        ),
      );

      _isConnected = true;

      // Initialize PaSoRi
      await _sendCommand(_buildInitCommand());
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      throw NfcReaderException('Failed to initialize PaSoRi: $e', e);
    }
  }

  @override
  Future<void> startListening() async {
    if (!_isConnected) {
      throw NfcReaderException('Reader not initialized');
    }

    _isListening = true;

    // Poll for cards every 500ms
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 500), (
      _,
    ) async {
      if (_isListening) {
        await _pollForCard();
      }
    });
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  Future<void> dispose() async {
    await stopListening();

    if (_port != null) {
      try {
        await _port!.close();
      } catch (e) {
        // Ignore close errors
      }
      _port = null;
    }

    _isConnected = false;
    await _cardController.close();
  }

  /// Send command to PaSoRi
  Future<void> _sendCommand(Uint8List command) async {
    if (_port == null) return;

    try {
      final writer = _port!.writable.getWriter();
      await writer.write(command);
      writer.releaseLock();
    } catch (e) {
      throw NfcReaderException('Failed to send command', e);
    }
  }

  /// Read response from PaSoRi
  Future<Uint8List?> _readResponse() async {
    if (_port == null) return null;

    try {
      final reader = _port!.readable.getReader();
      final result = await reader.read();
      reader.releaseLock();

      if (result.done || result.value == null) {
        return null;
      }

      return result.value;
    } catch (e) {
      // Timeout or read error
      return null;
    }
  }

  /// Poll for FeliCa card
  Future<void> _pollForCard() async {
    try {
      // Send InListPassiveTarget command for FeliCa
      final command = _buildPollingCommand();
      await _sendCommand(command);

      // Wait for response
      await Future.delayed(const Duration(milliseconds: 100));
      final response = await _readResponse();

      if (response != null && response.length > 10) {
        // Extract IDm (8 bytes) from response
        final idm = _extractIdm(response);
        if (idm != null && !_cardController.isClosed) {
          _cardController.add(idm);
        }
      }
    } catch (e) {
      // Ignore polling errors
    }
  }

  /// Build initialization command
  Uint8List _buildInitCommand() {
    // Simplified: In reality, PaSoRi uses PN532 commands
    // This is a placeholder - actual implementation needs proper PN532 protocol
    return Uint8List.fromList([
      0x00, 0x00, 0xFF, // Preamble and start code
      0x02, 0xFE, // Length
      0xD4, 0x14, // SAMConfiguration command
      0x01, // Normal mode
      0x17, // Checksum
      0x00, // Postamble
    ]);
  }

  /// Build polling command for FeliCa
  Uint8List _buildPollingCommand() {
    // InListPassiveTarget command for FeliCa (212kbps)
    return Uint8List.fromList([
      0x00, 0x00, 0xFF, // Preamble and start code
      0x04, 0xFC, // Length
      0xD4, 0x4A, // InListPassiveTarget
      0x01, // Max 1 card
      0x01, // FeliCa 212kbps
      0x00, // System code (any)
      0xE0, // Checksum
      0x00, // Postamble
    ]);
  }

  /// Extract IDm from response
  String? _extractIdm(Uint8List response) {
    // Look for response pattern and extract 8-byte IDm
    // This is simplified - actual parsing depends on PN532 response format
    if (response.length < 18) return null;

    // IDm typically starts at offset 10 in the response
    final idmBytes = response.sublist(10, 18);

    // Convert to hex string
    return idmBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }
}
