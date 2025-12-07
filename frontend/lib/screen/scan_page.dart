import 'package:animate_do/animate_do.dart';
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
            pollingOptions: {
              NfcPollingOption.iso14443,
              NfcPollingOption.iso15693,
            },
            onDiscovered: (NfcTag tag) async {
              String? id;
              // ignore: invalid_use_of_protected_member
              final Map<String, dynamic> data = Map<String, dynamic>.from(
                tag.data as Map,
              );

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
                id = idBytes
                    .map((b) => b.toRadixString(16).padLeft(2, '0'))
                    .join()
                    .toUpperCase();
              } else {
                id = "UNKNOWN_ID";
              }

              _handleScan(id);
            },
          );
        }
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // --- Desktop (dart_pcsc) ---
        try {
          _pcscContext = pcsc.Context(pcsc.Scope.user);
          await _pcscContext!.establish();
          if (!mounted) return;
          setState(() {
            _nfcAvailable = true;
            _nfcStatus = 'NFC Ready (PCSC)';
          });
          _pollPcscDesktop();
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

  Future<void> _pollPcscDesktop() async {
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
              pcsc.Protocol.any,
            );

            // Send APDU to get UID (Standard Get Data)
            // Class: 0xFF, INS: 0xCA, P1: 0x00, P2: 0x00, Le: 0x00
            Uint8List response = await card.transmit(
              Uint8List.fromList([0xFF, 0xCA, 0x00, 0x00, 0x00]),
            );

            // Check SW1 SW2 (Last 2 bytes)
            if (response.length >= 2) {
              int sw1 = response[response.length - 2];
              int sw2 = response[response.length - 1];

              if (sw1 == 0x90 && sw2 == 0x00) {
                // UID is response without SW
                List<int> uidBytes = response.sublist(0, response.length - 2);
                String id = uidBytes
                    .map((b) => b.toRadixString(16).padLeft(2, '0'))
                    .join()
                    .toUpperCase();

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
      final status = data['status']; // "ready_to_in" or "ready_to_out"

      if (!mounted) return;

      if (status == 'ready_to_in') {
        // --- Go to Clock In ---
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AttendancePage(
              userName: userName,
              onConfirm: () async {
                try {
                  final clockInResp = await widget.scanService.clockIn(cardId);
                  try {
                    return DateTime.parse(clockInResp['clock_in_at']);
                  } catch (_) {
                    return DateTime.now();
                  }
                } on ApiException catch (e) {
                  if (mounted)
                    setState(() {
                      _message = '出勤APIエラー: ${e.message}';
                    });
                  return null;
                } catch (e) {
                  if (mounted)
                    setState(() {
                      _message = '出勤処理でエラーが発生しました: $e';
                    });
                  return null;
                }
              },
            ),
          ),
        );

        // Returned from AttendancePage (after success and 3s wait)
        if (mounted) {
          setState(() {
            _message = 'カードをスキャンしてください\n(またはIDを入力)';
          });
        }
      } else if (status == 'ready_to_out') {
        // --- Go to Clock Out ---
        DateTime clockInTime;
        try {
          clockInTime = DateTime.parse(data['clock_in_at']);
        } catch (_) {
          clockInTime = DateTime.now(); // Fallback
        }

        final now = DateTime.now();
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeparturePage(
              userName: userName,
              cardId: cardId,
              clockInTime: clockInTime,
              clockOutTime: now,
              defaultCost: (data['default_cost'] is int)
                  ? data['default_cost'] as int
                  : (data['default_cost'] != null
                        ? int.tryParse('${data['default_cost']}') ?? 0
                        : 0),
              estimatedClassCount: (data['estimated_class_count'] is int)
                  ? data['estimated_class_count'] as int
                  : (data['estimated_class_count'] != null
                        ? int.tryParse('${data['estimated_class_count']}') ?? 0
                        : 0),
              transportPresets: data['transport_presets'] ?? [],
              scanService: widget.scanService,
              onConfirm: () {
                Navigator.pop(context, true);
              },
            ),
          ),
        );

        // Returned from DeparturePage (after success and 3s wait)
        if (mounted) {
          setState(() {
            _message = 'カードをスキャンしてください\n(またはIDを入力)';
          });
        }
      } else {
        setState(() {
          _message = '不明なステータス: $status';
        });
      }
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CardRegistratePage(cardId: cardId),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Attendance Scanner'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F9FF), Color(0xFFE3F2FD)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // NFC Status & Icon
                  Pulse(
                    infinite: true,
                    duration: const Duration(seconds: 2),
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.nfc_rounded,
                        size: 80,
                        color: _nfcAvailable
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _nfcStatus,
                    style: TextStyle(
                      color: _nfcAvailable
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Message
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      _message,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Input
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 600),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Waiting for card...',
                        prefixIcon: const Icon(Icons.credit_card),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      onSubmitted: _handleScan,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Mock Button
                  TextButton.icon(
                    onPressed: () => _handleScan("mock_card_123"),
                    icon: const Icon(Icons.bug_report_rounded),
                    label: const Text("Mock Scan"),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
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
        ),
      ),
    );
  }
}
