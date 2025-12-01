import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'classroom_selection_page.dart';

class ScanPage extends StatelessWidget {
  final String classroomName;

  const ScanPage({super.key, required this.classroomName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スキャン画面'),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '選択された教室:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              classroomName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 32),
            const Text('ここにスキャン機能が実装されます'),
          ],
        ),
      ),
    );
  }
}
