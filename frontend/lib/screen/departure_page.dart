import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeparturePage extends StatefulWidget {
  final String userName;
  final String cardId;
  final DateTime clockInTime;
  final DateTime clockOutTime;
  final VoidCallback onConfirm;

  const DeparturePage({
    super.key,
    required this.userName,
    required this.cardId,
    required this.clockInTime,
    required this.clockOutTime,
    required this.onConfirm,
  });

  @override
  State<DeparturePage> createState() => _DeparturePageState();
}

class _DeparturePageState extends State<DeparturePage> {
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final timeFormat = DateFormat('HH:mm');

    // More complex logic (fares etc) can be re-added here if needed.
    // For now, implementing basic confirmation as implied by the constructor.

    return Scaffold(
      appBar: AppBar(
        title: const Text('退勤確認'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               const Icon(Icons.exit_to_app, size: 80, color: Colors.orange),
               const SizedBox(height: 24),
               Text('${widget.userName}さん', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
               const SizedBox(height: 8),
               Text('退勤時間: ${timeFormat.format(widget.clockOutTime)}', style: const TextStyle(fontSize: 20)),
               const SizedBox(height: 32),
               
               // info table
               Table(
                 columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
                 children: [
                   TableRow(children: [
                     const Text('日付', style: TextStyle(color: Colors.grey)),
                     Text(dateFormat.format(widget.clockOutTime), style: const TextStyle(fontSize: 18)),
                   ]),
                   TableRow(children: [
                     const Text('出勤', style: TextStyle(color: Colors.grey)),
                     Text(timeFormat.format(widget.clockInTime), style: const TextStyle(fontSize: 18)),
                   ]),
                   TableRow(children: [
                     const Text('退勤', style: TextStyle(color: Colors.grey)),
                     Text(timeFormat.format(widget.clockOutTime), style: const TextStyle(fontSize: 18)),
                   ]),
                 ],
               ),
               
               const SizedBox(height: 48),
               
               ElevatedButton(
                 onPressed: widget.onConfirm,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.orange,
                   padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                 ),
                 child: const Text('退勤する', style: TextStyle(fontSize: 20, color: Colors.white)),
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
}
