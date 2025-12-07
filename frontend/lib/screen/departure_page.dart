import 'package:flutter/material.dart';
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
  late int _selectedTransportCost;
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
  }

  Future<void> _confirmAndClockOut() async {
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
        MaterialPageRoute(builder: (ctx) => ConfirmationScreen(fare: _selectedTransportCost)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('退勤エラー'),
          content: Text('退勤に失敗しました: ${e.message}'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
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
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
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
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.exit_to_app, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              Text('${widget.userName}さん', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('退勤時間: ${timeFormat.format(widget.clockOutTime)}', style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 24),

              // Transport presets (radio buttons)
              Align(alignment: Alignment.centerLeft, child: const Text('交通費プリセット', style: TextStyle(color: Colors.grey))),
              const SizedBox(height: 8),
              Column(
                children: _buildTransportPresetRadios(),
              ),

              const SizedBox(height: 16),

              // Class count selector (checkboxes 1〜5). Default: auto-check first N boxes.
              Align(alignment: Alignment.centerLeft, child: const Text('出勤コマ数', style: TextStyle(color: Colors.grey))),
              const SizedBox(height: 8),
              Column(
                children: List<Widget>.generate(5, (index) {
                  final label = '${index + 1} コマ';
                  return CheckboxListTile(
                    title: Text(label),
                    value: _classChecks[index],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _classChecks[index] = v;
                        _selectedClassCount = _classChecks.where((e) => e).length;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _confirmAndClockOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
                child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('退勤する', style: TextStyle(fontSize: 20, color: Colors.white)),
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
          cost = (p['cost'] is int) ? p['cost'] as int : int.tryParse('${p['cost']}') ?? 0;
        }
        if (p is Map && p.containsKey('name')) {
          label = '${p['name']} — ${cost} 円';
        } else {
          label = '${cost} 円';
        }
      } catch (_) {
        label = '${cost} 円';
      }

      rows.add(RadioListTile<int>(
        title: Text(label),
        value: cost,
        groupValue: _selectedTransportCost,
        onChanged: (v) {
          if (v == null) return;
          setState(() => _selectedTransportCost = v);
        },
      ));
    }

    // Also include an explicit custom/default option
    if (!presets.any((p) => (p is Map && ((p['cost'] == widget.defaultCost) || (int.tryParse('${p['cost']}') == widget.defaultCost))))) {
      rows.add(RadioListTile<int>(
        title: Text('${widget.defaultCost} 円 (デフォルト)'),
        value: widget.defaultCost,
        groupValue: _selectedTransportCost,
        onChanged: (v) {
          if (v == null) return;
          setState(() => _selectedTransportCost = v);
        },
      ));
    }

    return rows;
  }
}
