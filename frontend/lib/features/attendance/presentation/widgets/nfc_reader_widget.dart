import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/app_theme.dart';
import '../../data/providers.dart';
import '../../data/mock_nfc_reader_impl.dart';
import '../../data/nfc_reader_interface.dart';
import 'package:openapi/api.dart';
import 'package:go_router/go_router.dart';

/// Widget for NFC reader status and card detection
class NfcReaderWidget extends ConsumerStatefulWidget {
  const NfcReaderWidget({super.key});

  @override
  ConsumerState<NfcReaderWidget> createState() => _NfcReaderWidgetState();
}

class _NfcReaderWidgetState extends ConsumerState<NfcReaderWidget> {
  bool _isInitialized = false;
  bool _isConnecting = false;
  String? _errorMessage;
  NfcReaderInterface? _reader;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _debugInputController = TextEditingController();
  String? _lastInput;
  bool _showDebugInfo = false;
  OverlayEntry? _debugOverlayEntry;
  OverlayEntry? _debugButtonOverlayEntry;

  @override
  void initState() {
    super.initState();

    // Auto-initialize on native platforms (mobile/desktop)
    // Web Serial API requires user gesture, so we don't auto-init on web
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeReader();
      });
    }

    // Request focus for keyboard listener (still useful for debug input)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    // Add debug button overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugButtonOverlayEntry = _createDebugButtonOverlay();
      Overlay.of(context).insert(_debugButtonOverlayEntry!);
    });
  }

  OverlayEntry _createDebugButtonOverlay() {
    return OverlayEntry(
      builder: (context) => Positioned(
        bottom: 20,
        right: 20,
        child: FloatingActionButton(
          mini: true,
          onPressed: _toggleDebugOverlay,
          backgroundColor: _showDebugInfo ? AppTheme.primaryColor : Colors.grey,
          child: Icon(
            _showDebugInfo ? Icons.bug_report : Icons.bug_report_outlined,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _toggleDebugOverlay() {
    if (_showDebugInfo) {
      // Hide overlay
      _debugOverlayEntry?.remove();
      _debugOverlayEntry = null;
      setState(() {
        _showDebugInfo = false;
      });
    } else {
      // Show overlay
      setState(() {
        _showDebugInfo = true;
      });
      _debugOverlayEntry = _createDebugOverlay();
      Overlay.of(context).insert(_debugOverlayEntry!);
    }

    // Rebuild button to update color
    _debugButtonOverlayEntry?.markNeedsBuild();
  }

  OverlayEntry _createDebugOverlay() {
    return OverlayEntry(
      builder: (context) => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(20),
            width: 700,
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3C3C3C), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.terminal, color: Colors.white70, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Debug Console',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 18,
                        ),
                        onPressed: _toggleDebugOverlay,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 16,
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Consumer(
                        builder: (context, ref, _) {
                          final logs = ref.watch(debugLogProvider);
                          return ListView.builder(
                            reverse: false,
                            itemCount: logs.length,
                            itemBuilder: (context, index) {
                              final log = logs[logs.length - 1 - index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 1,
                                ),
                                child: Text(
                                  log,
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Debug input field
                Consumer(
                  builder: (context, ref, _) {
                    final nfcReader = ref.watch(nfcReaderProvider);
                    if (nfcReader is! MockNfcReaderImpl)
                      return const SizedBox.shrink();

                    return Container(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: TextField(
                        controller: _debugInputController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          decoration: TextDecoration.none,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Simulate Card ID',
                          labelStyle: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            decoration: TextDecoration.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF2D2D2D),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: Color(0xFF3C3C3C),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: Color(0xFF3C3C3C),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white60,
                              size: 16,
                            ),
                            onPressed: () {
                              final value = _debugInputController.text;
                              if (value.isNotEmpty) {
                                nfcReader.simulateCardTap(value);
                                _debugInputController.clear();
                              }
                            },
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            nfcReader.simulateCardTap(value);
                            _debugInputController.clear();
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _initializeReader() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      _reader = ref.read(nfcReaderProvider);
      await _reader!.initialize();
      await _reader!.startListening();

      // Listen to card stream
      _reader!.cardStream.listen((cardId) {
        _handleCardDetected(cardId);
      });

      setState(() {
        _isInitialized = true;
        _isConnecting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isConnecting = false;
      });
    }
  }

  Future<void> _handleCardDetected(String cardId) async {
    // Prevent multiple calls if already processing
    if (ref.read(statusMessageProvider) != null) return;

    _log('Card detected: $cardId');
    ref.read(statusMessageProvider.notifier).state = '読み取り中...';

    try {
      final api = ref.read(attendanceApiProvider);
      final dto = CheckStatusDto(
        cardId: cardId,
        terminalId: 'iPad-01',
        clientTimestamp: DateTime.now().toIso8601String(),
      );

      _log('Calling API: checkStatus');
      // Use WithHttpInfo to get the full response object
      final response = await api.attendanceControllerCheckStatusWithHttpInfo(
        dto,
      );
      _log('API Response: ${response.statusCode}');

      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, response.body);
      }

      // Parse response body manually
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Store employee and attendance info
      ref.read(currentCardIdProvider.notifier).state = cardId;
      ref.read(currentEmployeeProvider.notifier).state = data['employee'];
      ref.read(currentAttendanceProvider.notifier).state = data['attendance'];
      ref.read(commuteTemplatesProvider.notifier).state =
          (data['commute_templates'] as List<dynamic>?) ?? [];

      _log('Navigating...');
      // Navigate based on attendance status
      if (mounted) {
        // Clear status before navigating to avoid showing it when coming back?
        // Actually better to keep it until unmounted or replaced.
        ref.read(statusMessageProvider.notifier).state = null;

        if (data['attendance'] == null) {
          context.go('/clock-in');
        } else {
          context.go('/clock-out');
        }
      }
    } catch (e) {
      _log('API Error: $e');
      ref.read(statusMessageProvider.notifier).state = 'エラー: $e';
      // Clear error after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          ref.read(statusMessageProvider.notifier).state = null;
        }
      });
    }
  }

  void _log(String message) {
    final logs = ref.read(debugLogProvider);
    ref.read(debugLogProvider.notifier).state = [
      ...logs,
      '${DateTime.now().toString().split(' ').last} [UI] $message',
    ];
  }

  @override
  void dispose() {
    _reader?.dispose();
    _focusNode.dispose();
    _debugOverlayEntry?.remove();
    _debugButtonOverlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nfcReader = ref.watch(nfcReaderProvider);
    final statusMessage = ref.watch(statusMessageProvider);

    // Determine current state for rendering
    Widget currentWidget;
    bool isWaitingForCard = false;

    if (_isConnecting) {
      currentWidget = _buildConnectingState();
    } else if (_errorMessage != null) {
      currentWidget = _buildErrorState();
    } else if (!_isInitialized) {
      currentWidget = _buildInitButton();
    } else if (statusMessage != null) {
      currentWidget = _buildProcessingState(statusMessage);
    } else {
      currentWidget = _buildWaitingState();
      isWaitingForCard = true;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Invisible but focused TextField to capture input
            Opacity(
              opacity: 0.0,
              child: TextField(
                focusNode: _focusNode,
                autofocus: true,
                showCursor: false,
                decoration: const InputDecoration(border: InputBorder.none),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    if (nfcReader is MockNfcReaderImpl) {
                      nfcReader.simulateCardTap(value);
                    }
                    setState(() {
                      _lastInput = 'Read: $value';
                    });
                  }
                },
                onChanged: (value) {
                  setState(() {
                    _lastInput = 'Input: $value';
                  });
                },
              ),
            ),
            currentWidget,
          ],
        );
      },
    );
  }

  Widget _buildProcessingState(String message) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 24),
          Text(
            message,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: Colors.white),
        const SizedBox(height: 24),
        Text(
          'リーダーに接続中...',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
        const SizedBox(height: 24),
        Text(
          'リーダーの接続に失敗しました',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? '',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _initializeReader,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('再試行', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  Widget _buildInitButton() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.nfc, size: 64, color: AppTheme.primaryColor),
          const SizedBox(height: 24),
          Text(
            'カードリーダーを接続',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _initializeReader,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('リーダーを接続', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.contactless, size: 120, color: AppTheme.primaryColor)
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                duration: const Duration(milliseconds: 1500),
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                duration: const Duration(milliseconds: 1500),
                begin: const Offset(1.1, 1.1),
                end: const Offset(0.9, 0.9),
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 32),
          Text(
            'カードをタッチしてください',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'リーダーにカードをかざしてください',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
