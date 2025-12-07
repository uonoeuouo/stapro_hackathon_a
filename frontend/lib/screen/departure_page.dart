import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/glass_container.dart';
import '../widgets/gradient_scaffold.dart';

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

    return GradientScaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: GlassContainer(
              padding: 32,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Icon(Icons.nightlight_round, size: 80, color: Colors.indigo),
                   const SizedBox(height: 24),
                   Text(
                     'Good Job, ${widget.userName}!', 
                     style: const TextStyle(
                       fontSize: 24, 
                       fontWeight: FontWeight.bold,
                       color: Color(0xFF1565C0) // Dark Blue
                      ),
                      textAlign: TextAlign.center,
                    ),
                   const SizedBox(height: 8),
                   Text(
                     'Leaving at ${timeFormat.format(widget.clockOutTime)}', 
                     style: const TextStyle(fontSize: 16, color: Colors.black54)
                    ),
                   const SizedBox(height: 32),
                   
                   // info table inside a lighter glass pane
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: Colors.blue.withOpacity(0.05), // Light blue tint
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Table(
                       columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
                       children: [
                         TableRow(children: [
                           const Padding(
                             padding: EdgeInsets.symmetric(vertical: 4),
                             child: Text('DATE', style: TextStyle(color: Colors.grey, fontSize: 12)),
                           ),
                           Padding(
                             padding: const EdgeInsets.symmetric(vertical: 4),
                             child: Text(dateFormat.format(widget.clockOutTime), style: const TextStyle(color: Colors.black87, fontSize: 16), textAlign: TextAlign.right),
                           ),
                         ]),
                         TableRow(children: [
                           const Padding(
                             padding: EdgeInsets.symmetric(vertical: 4),
                             child: Text('START', style: TextStyle(color: Colors.grey, fontSize: 12)),
                           ),
                           Padding(
                             padding: const EdgeInsets.symmetric(vertical: 4),
                             child: Text(timeFormat.format(widget.clockInTime), style: const TextStyle(color: Colors.black87, fontSize: 16), textAlign: TextAlign.right),
                           ),
                         ]),
                         TableRow(children: [
                           const Padding(
                             padding: EdgeInsets.symmetric(vertical: 4),
                             child: Text('END', style: TextStyle(color: Colors.grey, fontSize: 12)),
                           ),
                           Padding(
                             padding: const EdgeInsets.symmetric(vertical: 4),
                             child: Text(timeFormat.format(widget.clockOutTime), style: const TextStyle(color: Colors.black87, fontSize: 16), textAlign: TextAlign.right),
                           ),
                         ]),
                       ],
                     ),
                   ),
                   
                   const SizedBox(height: 48),
                   
                   SizedBox(
                    width: double.infinity,
                     child: ElevatedButton(
                       onPressed: widget.onConfirm,
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.redAccent,
                       ),
                       child: const Text('CLOCK OUT', style: TextStyle(fontSize: 18, color: Colors.white)),
                     ),
                   ),
                   const SizedBox(height: 16),
                   TextButton(
                     onPressed: () => Navigator.pop(context, false),
                     child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
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
