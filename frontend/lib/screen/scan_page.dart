import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:dart_pcsc/dart_pcsc.dart' as pcsc;
import '../services/scan_service.dart';
import 'attendance_page.dart';
import 'departure_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'classroom_selection_page.dart';
import 'card_registrate_page.dart';
import '../widgets/glass_container.dart';
import '../widgets/gradient_scaffold.dart';

class ScanPage extends StatefulWidget {
  final ScanService scanService;

  const ScanPage({super.key, required this.scanService});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _message = 'カードをスキャンしてください\n(またはIDを入力)';
  bool _isLoading = false;
  
  // Attendance State
  bool _isClockedIn = false;
  DateTime? _clockInTime;
  String? _currentUserName;
  
  // NFC State
  bool _nfcAvailable = false;
  String _nfcStatus = 'Checking NFC...';
  
  // PCSC Context
  pcsc.Context? _pcscContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _initNfc();
  }
  
  @override
  void dispose() {
    if (Platform.isIOS || Platform.isAndroid) {
      NfcManager.instance.stopSession();
    } else if (Platform.isWindows) {
      _pcscContext?.release();
    }
    super.dispose();
  }

  Future<void> _initNfc() async {
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        // --- Mobile (nfc_manager) ---
        bool isAvailable = await NfcManager.instance.isAvailable();
        if (!mounted) return;
        setState(() {
          _nfcAvailable = isAvailable;
          _nfcStatus = isAvailable ? 'NFC Ready (Mobile)' : 'NFC Not Available';
        });

        if (isAvailable) {
          NfcManager.instance.startSession(
            pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
            onDiscovered: (NfcTag tag) async {
              String? id;
              // ignore: invalid_use_of_protected_member
              final Map<String, dynamic> data = Map<String, dynamic>.from(tag.data as Map);
              
              List<int>? idBytes;
              if (data.containsKey('isodep')) {
                idBytes = data['isodep']['identifier']?.cast<int>();
              } else if (data.containsKey('nfca')) {
                idBytes = data['nfca']['identifier']?.cast<int>();
              } else if (data.containsKey('nfcb')) {
                idBytes = data['nfcb']['identifier']?.cast<int>();
              } else if (data.containsKey('nfcf')) {
                idBytes = data['nfcf']['identifier']?.cast<int>();
              } else if (data.containsKey('nfcv')) {
                idBytes = data['nfcv']['identifier']?.cast<int>();
              } else if (data.containsKey('mifare')) { 
                 idBytes = data['mifare']['identifier']?.cast<int>();
              }

              if (idBytes != null) {
                id = idBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
              } else {
                 id = "UNKNOWN_ID";
              }
              
              _handleScan(id);
            }
          );
        }
      } else if (Platform.isWindows) {
        // --- Windows (dart_pcsc) ---
        try {
          _pcscContext = pcsc.Context(pcsc.Scope.user);
          await _pcscContext!.establish();
          if (!mounted) return;
          setState(() {
            _nfcAvailable = true;
            _nfcStatus = 'NFC Ready (PCSC)';
          });
          _pollPcscWindows();
        } catch (e) {
          setState(() {
            _nfcAvailable = false;
            _nfcStatus = 'PCSC Error: $e';
          });
        }
      }
    } catch (e) {
      setState(() {
        _nfcStatus = 'Error: $e';
      });
    }
  }

  Future<void> _pollPcscWindows() async {
    while (mounted && _pcscContext != null) {
      try {
        List<String> readers = await _pcscContext!.listReaders();
        
        if (readers.isNotEmpty) {
          // Try the first reader
          String reader = readers.first;
          
          try {
            // Share Shared, Protocol Any
            pcsc.Card card = await _pcscContext!.connect(
              reader, 
              pcsc.ShareMode.shared, 
              pcsc.Protocol.any
            );
            
            // Send APDU to get UID (Standard Get Data)
            // Class: 0xFF, INS: 0xCA, P1: 0x00, P2: 0x00, Le: 0x00
            Uint8List response = await card.transmit(
              Uint8List.fromList([0xFF, 0xCA, 0x00, 0x00, 0x00])
            );
            
            // Check SW1 SW2 (Last 2 bytes)
            if (response.length >= 2) {
              int sw1 = response[response.length - 2];
              int sw2 = response[response.length - 1];
              
              if (sw1 == 0x90 && sw2 == 0x00) {
                // UID is response without SW
                List<int> uidBytes = response.sublist(0, response.length - 2);
                String id = uidBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
                
                if (id.isNotEmpty) {
                  _handleScan(id);
                  // Wait a bit longer after success to avoid multi-scan
                  await Future.delayed(const Duration(seconds: 2));
                }
              }
            }
            
            // Disposition Leave
            await card.disconnect(pcsc.Disposition.resetCard);
            
          } catch (e) {
            // Card might not be present or connection failed
          }
        }
        
        // Poll interval
        await Future.delayed(const Duration(milliseconds: 500));
        
      } catch (e) {
        // Context error or list readers failed
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  Future<void> _handleScan(String cardId) async {
    if (cardId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _message = '読み込み中... (ID: $cardId)';
    });

    try {
      // 1. Validate Card with Backend
      final data = await widget.scanService.scanCard(cardId);
      final userName = data['user_name'] ?? 'Unknown User';
      
      if (!mounted) return;

      if (!_isClockedIn) {
        // --- Go to Clock In ---
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AttendancePage(
              userName: userName,
              onConfirm: () {
                Navigator.pop(context, true);
              },
            ),
          ),
        );

        if (result == true) {
          setState(() {
            _isClockedIn = true;
            _clockInTime = DateTime.now();
            _currentUserName = userName;
            _message = '出勤しました: $userName\n出勤時間: ${_formatTime(_clockInTime!)}';
          });
        } else {
           setState(() {
            _message = 'キャンセルされました';
          });
        }

      } else {
        // --- Go to Clock Out ---
        if (_currentUserName != null && _currentUserName != userName) {
           setState(() {
            _message = 'エラー: 別のユーザーが出勤中です\n($_currentUserName)';
          });
          return;
        }

        final now = DateTime.now();
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeparturePage(
              userName: userName,
              cardId: cardId,
              clockInTime: _clockInTime!,
              clockOutTime: now,
              onConfirm: () {
                Navigator.pop(context, true);
              },
            ),
          ),
        );

        if (result == true) {
          setState(() {
            _isClockedIn = false;
            _clockInTime = null;
            _currentUserName = null;
            _message = '退勤しました: $userName\nお疲れ様でした';
          });
        } else {
           setState(() {
            _message = 'キャンセルされました';
          });
        }
      }

    } on ApiException catch (e) {
      if (e.statusCode == 404) {
         if (!mounted) return;
         Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CardRegistratePage(
              cardId: cardId,
            ),
          ),
        );
      } else {
         setState(() {
          _message = 'API Error: ${e.message} (Status: ${e.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'エラー: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _controller.clear();
          _focusNode.requestFocus();
        });
      }
    }
  }
  
  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('ATTENDANCE SCANNER'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status Indicator using Glass Container
                GlassContainer(
                  color: _isClockedIn ? Colors.greenAccent.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                  borderRadius: 30,
                  padding: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isClockedIn ? Icons.check_circle : Icons.timer,
                        color: _isClockedIn ? Colors.greenAccent : Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isClockedIn ? 'WORKING: $_currentUserName' : 'STANDBY',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: _isClockedIn ? Colors.greenAccent : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _nfcStatus,
                  style: TextStyle(
                    color: _nfcAvailable ? Colors.cyanAccent : Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),

                // Hero Message
                Text(
                  _message,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text stands out better on vivid background
                    shadows: [
                      Shadow(blurRadius: 10, color: Colors.blueAccent.withOpacity(0.5), offset: const Offset(0, 4)),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),

                // Removed NFC Visual as per request
                // Instead, just a simple hint or spacing
                const Icon(Icons.arrow_downward, color: Colors.white54, size: 32),
                
                const SizedBox(height: 60),
                
                const SizedBox(height: 48),

                // Functionality Area (Glass)
                GlassContainer(
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: const TextStyle(color: Colors.black87), // Black text for white glass
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Scan Card / Enter ID',
                          labelStyle: TextStyle(color: Colors.black54),
                          border: InputBorder.none,
                          hintText: 'Waiting for scan...',
                          hintStyle: TextStyle(color: Colors.black26),
                          prefixIcon: Icon(Icons.credit_card, color: Colors.black45),
                        ),
                        onSubmitted: _handleScan,
                      ),
                      const Divider(color: Colors.white24),
                      TextButton.icon(
                        onPressed: () => _handleScan("mock_card_123"),
                        icon: const Icon(Icons.touch_app, color: Colors.white),
                        label: const Text("SIMULATE TOUCH (DEBUG)", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 24.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}