import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pcsc/flutter_pcsc.dart';
import 'providers.dart';
import 'nfc_reader_interface.dart';

class PcscNfcReader implements NfcReaderInterface {
  final Ref _ref;
  final StreamController<String> _cardController =
      StreamController<String>.broadcast();

  int? _context;
  String? _readerName;
  CardStruct? _card;
  bool _isConnected = false;
  bool _isListening = false;
  Timer? _pollingTimer;

  PcscNfcReader(this._ref);

  void _log(String message) {
    print('[PCSC] $message');
    final logs = _ref.read(debugLogProvider);
    _ref.read(debugLogProvider.notifier).state = [
      ...logs,
      '${DateTime.now().toString().split(' ').last} $message',
    ];
  }

  @override
  Stream<String> get cardStream => _cardController.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> initialize() async {
    try {
      _log('Initializing PCSC...');
      // Establish PCSC context
      _context = await Pcsc.establishContext(PcscSCope.user);
      _log('Context established: $_context');

      // List available readers
      final readers = await Pcsc.listReaders(_context!);
      _log('Readers found: $readers');

      if (readers.isEmpty) {
        throw NfcReaderException('No smart card readers found');
      }

      // Use the first available reader (usually PaSoRi)
      _readerName = readers.first;
      _isConnected = true;
      _log('Selected reader: $_readerName');
    } catch (e) {
      _log('Error initializing: $e');
      throw NfcReaderException('Failed to initialize PCSC: $e', e);
    }
  }

  @override
  Future<void> startListening() async {
    if (!_isConnected || _context == null || _readerName == null) {
      throw NfcReaderException('Reader not initialized');
    }

    _isListening = true;
    _log('Started listening');

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
    _log('Stopped listening');

    if (_card != null) {
      try {
        await Pcsc.cardDisconnect(_card!.hCard, PcscDisposition.leaveCard);
        _card = null;
      } catch (e) {
        // Ignore disconnect errors
      }
    }
  }

  @override
  Future<void> dispose() async {
    await stopListening();

    if (_context != null) {
      try {
        await Pcsc.releaseContext(_context!);
      } catch (e) {
        // Ignore context release errors
      }
      _context = null;
    }

    _isConnected = false;
    await _cardController.close();
  }

  Future<void> _pollForCard() async {
    try {
      // Try to connect to the card
      // FeliCa on PaSoRi is usually mapped to T=1.
      // Type-A (Mifare) is often T=0.
      // By forcing T=1, we might avoid connecting to the Type-A Random UID target
      // and let the reader find the FeliCa target.
      final card = await Pcsc.cardConnect(
        _context!,
        _readerName!,
        PcscShare.shared,
        PcscProtocol.any,
      );

      _card = card;
      _log('Card connected: ${card.activeProtocol}');

      // Use ATR (Answer To Reset) as the card identifier
      // ATR is stable and unique per card, same as what opensc-tool --atr returns
      // Try to get ATR using SCardStatus
      final statusCmd = [0xFF, 0xC0, 0x00, 0x00, 0x00];
      final statusResponse = await Pcsc.transmit(card, statusCmd);
      _log('SCardStatus response: $statusResponse');

      String? cardId;

      // If status command doesn't work, try to get card state
      // The CardStruct might have ATR info, but flutter_pcsc doesn't expose it directly
      // Let's try a different approach: use Get Data to read ATR
      final getAtrCmd = [
        0xFF,
        0xCA,
        0x01,
        0x00,
        0x00,
      ]; // Get Historical Bytes (part of ATR)
      final atrResponse = await Pcsc.transmit(card, getAtrCmd);
      _log('Get ATR response: $atrResponse');

      if (atrResponse.length >= 2) {
        final sw1 = atrResponse[atrResponse.length - 2];
        final sw2 = atrResponse[atrResponse.length - 1];

        if (sw1 == 0x90 && sw2 == 0x00 && atrResponse.length > 2) {
          // Successfully got ATR/Historical bytes
          final atr = atrResponse.sublist(0, atrResponse.length - 2);
          cardId = atr
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join()
              .toUpperCase();
          _log('ATR read: $cardId');
        }
      }

      // If ATR reading failed, fallback to UID
      if (cardId == null) {
        _log('ATR read failed, trying UID...');
        final getUidCmd = [0xFF, 0xCA, 0x00, 0x00, 0x00];
        final uidResponse = await Pcsc.transmit(card, getUidCmd);
        _log('Get UID response: $uidResponse');

        if (uidResponse.length >= 2) {
          final sw1 = uidResponse[uidResponse.length - 2];
          final sw2 = uidResponse[uidResponse.length - 1];

          if (sw1 == 0x90 && sw2 == 0x00) {
            final uid = uidResponse.sublist(0, uidResponse.length - 2);
            final uidStr = uid
                .map((b) => b.toRadixString(16).padLeft(2, '0'))
                .join()
                .toUpperCase();

            // Check for Random UID (starts with 08)
            bool isRandomUid = uid.isNotEmpty && uid[0] == 0x08;

            if (isRandomUid) {
              _log('Random UID detected ($uidStr). Trying HCE...');
              // Try to select our custom AID
              final mobileId = await _tryReadMobileId(card);
              if (mobileId != null) {
                cardId = mobileId;
                _log('Mobile ID read: $cardId');
              } else {
                _log('HCE selection failed. Retrying...');
                await Pcsc.cardDisconnect(
                  card.hCard,
                  PcscDisposition.resetCard,
                );
                _card = null;
                return;
              }
            } else {
              cardId = uidStr;
              _log('UID read: $cardId');
            }
          }
        }
      }

      // If we got a valid card ID, emit it
      if (cardId != null && !_cardController.isClosed) {
        _cardController.add(cardId);
      }

      await Pcsc.cardDisconnect(card.hCard, PcscDisposition.leaveCard);

      _card = null;
    } catch (e) {
      // Card not present or connection failed
      // This is expected when no card is on the reader
      // Don't log every failure to avoid spam, unless debugging
    }
  }

  Future<String?> _tryReadMobileId(CardStruct card) async {
    try {
      // SELECT AID: F0010203040506
      final selectAidCmd = [
        0x00,
        0xA4,
        0x04,
        0x00,
        0x07,
        0xF0,
        0x01,
        0x02,
        0x03,
        0x04,
        0x05,
        0x06,
      ];
      final selectResponse = await Pcsc.transmit(card, selectAidCmd);
      _log('SELECT AID response: $selectResponse');

      if (selectResponse.length >= 2 &&
          selectResponse[selectResponse.length - 2] == 0x90 &&
          selectResponse[selectResponse.length - 1] == 0x00) {
        // READ ID: B0 00 00 00
        final readIdCmd = [0xB0, 0x00, 0x00, 0x00];
        final readResponse = await Pcsc.transmit(card, readIdCmd);
        _log('READ ID response: $readResponse');

        if (readResponse.length >= 2 &&
            readResponse[readResponse.length - 2] == 0x90 &&
            readResponse[readResponse.length - 1] == 0x00) {
          final idBytes = readResponse.sublist(0, readResponse.length - 2);
          // Convert bytes to Hex String
          return idBytes
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join()
              .toUpperCase();
        }
      }
    } catch (e) {
      _log('Error reading mobile ID: $e');
    }
    return null;
  }
}
