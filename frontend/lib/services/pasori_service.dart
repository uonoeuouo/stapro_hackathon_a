import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class PasoriService {
  static const MethodChannel _channel = MethodChannel('pasori_channel');
  static const EventChannel _eventChannel = EventChannel('pasori_events');

  static Stream<Map<String, dynamic>>? _eventStream;

  /// Get stream of PaSoRi events (connect/disconnect/data)
  static Stream<Map<String, dynamic>> get eventStream {
    _eventStream ??= _eventChannel.receiveBroadcastStream().map(
      (event) => Map<String, dynamic>.from(event as Map),
    );
    return _eventStream!;
  }

  /// List all connected accessories
  static Future<List<Map<String, dynamic>>> listAccessories() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        'listAccessories',
      );
      return result
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } on PlatformException catch (e) {
      throw Exception('Failed to list accessories: ${e.message}');
    }
  }

  /// Connect to PaSoRi with specified protocol
  static Future<Map<String, dynamic>> connect({
    String protocol = 'com.sony.felica',
  }) async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'connect',
        {'protocol': protocol},
      );
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      throw Exception('Failed to connect: ${e.message}');
    }
  }

  /// Disconnect from PaSoRi
  static Future<Map<String, dynamic>> disconnect() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'disconnect',
      );
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      throw Exception('Failed to disconnect: ${e.message}');
    }
  }

  /// Send command to PaSoRi
  static Future<Map<String, dynamic>> sendCommand(Uint8List command) async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'sendCommand',
        {'command': command},
      );
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      throw Exception('Failed to send command: ${e.message}');
    }
  }

  /// Check if connected
  static Future<bool> isConnected() async {
    try {
      final bool result = await _channel.invokeMethod('isConnected');
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to check connection: ${e.message}');
    }
  }

  /// Poll for FeliCa card (RC-S300 specific)
  static Future<String?> pollCard({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final completer = Completer<String?>();
    StreamSubscription? subscription;
    Timer? timer;

    try {
      // Start listening for data
      subscription = eventStream.listen((event) {
        if (event['event'] == 'data') {
          final Uint8List data = (event['data'] as Uint8List);
          // Parse FeliCa response
          if (data.length >= 8) {
            // IDm is typically 8 bytes
            final idm = data.sublist(0, 8);
            final cardId = idm
                .map((b) => b.toRadixString(16).padLeft(2, '0'))
                .join()
                .toUpperCase();
            if (!completer.isCompleted) {
              completer.complete(cardId);
            }
          }
        }
      });

      // Set timeout
      timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      // Send polling command for FeliCa
      // Command: 0x00 (Polling), 0xFF 0xFF (System Code for any FeliCa), 0x01 (Request Code), 0x00 (Time Slot)
      await sendCommand(Uint8List.fromList([0x00, 0xFF, 0xFF, 0x01, 0x00]));

      return await completer.future;
    } finally {
      await subscription?.cancel();
      timer?.cancel();
    }
  }
}
