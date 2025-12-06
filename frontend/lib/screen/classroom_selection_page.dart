import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'scan_page.dart';

class ClassroomSelectionPage extends StatelessWidget {
  const ClassroomSelectionPage({super.key});

  final List<String> classrooms = const [
    '出汐校',
    '本社校',
    '西条校',
    '西風新都校',
    '五日市校',
    '駅前校',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('教室を選択してください'),
      ),
      body: ListView.builder(
        itemCount: classrooms.length,
        itemBuilder: (context, index) {
          final classroom = classrooms[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                classroom,
                style: const TextStyle(fontSize: 18),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('selected_classroom', classroom);

                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const ScanPage(),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
