import 'package:flutter/material.dart';
import '../widgets/glass_container.dart';
import '../widgets/gradient_scaffold.dart';

class AttendancePage extends StatelessWidget {
  final String userName;
  final VoidCallback onConfirm;

  const AttendancePage({
    super.key,
    required this.userName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: GlassContainer(
              padding: 32,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.wb_sunny_rounded,
                    color: Colors.orange, // Orange for sun
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Good Morning,\n$userName!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0), // Dark Blue
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Start your shift?',
                    style: TextStyle(
                      fontSize: 18, 
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                         backgroundColor: const Color(0xFF00BFA6), // Teal for start
                      ),
                      child: const Text('CLOCK IN', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                   const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false), // Cancel
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
