import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../services/scan_service.dart';
import 'confirm_page.dart';

class DeparturePage extends StatefulWidget {
  final String userName;
  final String cardId;
  final DateTime clockInTime;
  final DateTime clockOutTime;
  final int defaultCost;
  final int estimatedClassCount;
  final List<dynamic> transportPresets;
  final ScanService scanService;
  final VoidCallback onConfirm;

  const DeparturePage({
    super.key,
    required this.userName,
    required this.cardId,
    required this.clockInTime,
    required this.clockOutTime,
    required this.defaultCost,
    required this.estimatedClassCount,
    required this.transportPresets,
    required this.scanService,
    required this.onConfirm,
  });

  @override
  State<DeparturePage> createState() => _DeparturePageState();
}

class _DeparturePageState extends State<DeparturePage> {
  Timer? _autoClockOutTimer;
  bool _hasSubmitted = false;
  late int _selectedTransportCost;
  int _remainingSeconds = 10;
  late int _selectedClassCount;
  late List<bool> _classChecks; // index 0 => 1コマ
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedTransportCost = widget.defaultCost;
    // initialize checkboxes for 1..5
    _classChecks = List<bool>.filled(5, false);
    final initCount = widget.estimatedClassCount.clamp(0, 5);
    for (var i = 0; i < initCount; i++) {
      _classChecks[i] = true;
    }
    _selectedClassCount = _classChecks.where((v) => v).length;
    // start auto clock-out timer (10 seconds)
    // countdown timer for UI + auto trigger
    _autoClockOutTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _remainingSeconds = (_remainingSeconds - 1).clamp(0, 10);
      });
      if (_remainingSeconds <= 0) {
        t.cancel();
        _handleAutoClockOut();
      }
    });
  }

  @override
  void dispose() {
    _autoClockOutTimer?.cancel();
    super.dispose();
  }

  Future<void> _confirmAndClockOut() async {
    // If auto-submit already triggered, do nothing
    if (_hasSubmitted) return;
    _autoClockOutTimer?.cancel();
    _autoClockOutTimer = null;
    _hasSubmitted = true;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.scanService.clockOut(
        widget.cardId,
        _selectedTransportCost,
        _selectedClassCount,
        isAutoSubmit: false,
      );

      if (!mounted) return;
      // After successful clock-out, go to confirmation screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) => ConfirmationScreen(fare: _selectedTransportCost),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('退勤エラー'),
          content: Text('退勤に失敗しました: ${e.message}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('通信エラー'),
          content: Text('退勤処理中にエラーが発生しました: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAutoClockOut() async {
    if (_hasSubmitted) return;
    _hasSubmitted = true;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.scanService.clockOut(
        widget.cardId,
        _selectedTransportCost,
        _selectedClassCount,
        isAutoSubmit: true,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) => ConfirmationScreen(fare: _selectedTransportCost),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      // show an error dialog but don't auto-retry here
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('自動退勤エラー'),
          content: Text('自動退勤に失敗しました: ${e.message}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('通信エラー'),
          content: Text('自動退勤処理中にエラーが発生しました: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('退勤確認'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.exit_to_app_rounded,
                  size: 80,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  '${widget.userName}さん',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '退勤時間: ${timeFormat.format(widget.clockOutTime)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 32),

                // Transport presets (radio buttons)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.train_rounded,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '交通費プリセット',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Column(children: _buildTransportPresetRadios()),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Class count selector (checkboxes 1〜5)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.class_rounded,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '出勤コマ数',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Column(
                          children: List<Widget>.generate(5, (index) {
                            final label = '${index + 1} コマ';
                            return CheckboxListTile(
                              title: Text(label),
                              value: _classChecks[index],
                              activeColor: Theme.of(context).primaryColor,
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() {
                                  _classChecks[index] = v;
                                  _selectedClassCount = _classChecks
                                      .where((e) => e)
                                      .length;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                // Auto clock-out notice
                Text(
                  '$_remainingSeconds 秒後に自動で退勤処理が行われます。',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _confirmAndClockOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            '退勤する',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('キャンセル'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTransportPresetRadios() {
    // transportPresets is expected to be a list of maps possibly like [{"name": "往復", "cost": 500}, ...]
    final presets = widget.transportPresets;
    if (presets.isEmpty) {
      // show single radio with default cost
      return [
        RadioListTile<int>(
          title: Text('${widget.defaultCost} 円 (デフォルト)'),
          value: widget.defaultCost,
          groupValue: _selectedTransportCost,
          activeColor: Theme.of(context).primaryColor,
          onChanged: (v) {
            if (v == null) return;
            setState(() => _selectedTransportCost = v);
          },
        ),
      ];
    }

    // Build radios from presets
    List<Widget> rows = [];
    for (final p in presets) {
      String label;
      int cost = 0;
      try {
        if (p is Map && p.containsKey('cost')) {
          cost = (p['cost'] is int)
              ? p['cost'] as int
              : int.tryParse('${p['cost']}') ?? 0;
        }
        if (p is Map && p.containsKey('name')) {
          label = '${p['name']} — ${cost} 円';
        } else {
          label = '${cost} 円';
        }
      } catch (_) {
        label = '${cost} 円';
      }

      rows.add(
        RadioListTile<int>(
          title: Text(label),
          value: cost,
          groupValue: _selectedTransportCost,
          activeColor: Theme.of(context).primaryColor,
          onChanged: (v) {
            if (v == null) return;
            setState(() => _selectedTransportCost = v);
          },
        ),
      );
    }

    // Also include an explicit custom/default option
    if (!presets.any(
      (p) =>
          (p is Map &&
          ((p['cost'] == widget.defaultCost) ||
              (int.tryParse('${p['cost']}') == widget.defaultCost))),
    )) {
      rows.add(
        RadioListTile<int>(
          title: Text('${widget.defaultCost} 円 (デフォルト)'),
          value: widget.defaultCost,
          groupValue: _selectedTransportCost,
          activeColor: Theme.of(context).primaryColor,
          onChanged: (v) {
            if (v == null) return;
            setState(() => _selectedTransportCost = v);
          },
        ),
      );
    }

    return rows;
  }
}
