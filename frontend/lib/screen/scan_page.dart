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
          try {
            final clockInResp = await widget.scanService.clockIn(cardId);
            DateTime clockInAt;
            try {
              clockInAt = DateTime.parse(clockInResp['clock_in_at']);
            } catch (_) {
              clockInAt = DateTime.now();
            }

            if (!mounted) return;
            setState(() {
              _isClockedIn = true;
              _clockInTime = clockInAt;
              _currentUserName = userName;
              _message = '出勤しました: $userName\n出勤時間: ${_formatTime(_clockInTime!)}';
            });
          } on ApiException catch (e) {
            if (!mounted) return;
            setState(() {
              _message = '出勤APIエラー: ${e.message}';
            });
          } catch (e) {
            if (!mounted) return;
            setState(() {
              _message = '出勤処理でエラーが発生しました: $e';
            });
          }
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
    return Scaffold(


      appBar: AppBar(
        title: const Text('Attendance Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '教室を変更',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('selected_classroom');

              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const ClassroomSelectionPage(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _isClockedIn ? Colors.green.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _isClockedIn ? Colors.green : Colors.grey),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_isClockedIn ? Icons.work : Icons.home, color: _isClockedIn ? Colors.green : Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _isClockedIn ? '勤務中 ($_currentUserName)' : '待機中',
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: _isClockedIn ? Colors.green.shade800 : Colors.grey.shade800
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(_nfcStatus, style: TextStyle(color: _nfcAvailable ? Colors.blue : Colors.red)),
              const SizedBox(height: 48),
              
              Text(
                _message,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Input for Card ID (Simulating NFC)
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Scan Card (or type ID)',
                  border: OutlineInputBorder(),
                  hintText: 'Waiting for card...',
                  suffixIcon: Icon(Icons.nfc),
                ),
                onSubmitted: _handleScan,
              ),
              
              const SizedBox(height: 16),
              
              // Mock NFC Button
              ElevatedButton.icon(
                onPressed: () => _handleScan("mock_card_123"),
                icon: const Icon(Icons.nfc),
                label: const Text("【Mock】NFCタッチをシミュレート"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade50,
                  foregroundColor: Colors.deepPurple,
                ),
              ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}