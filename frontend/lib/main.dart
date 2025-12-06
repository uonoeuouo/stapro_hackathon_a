import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screen/classroom_selection_page.dart';
import 'screen/scan_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedClassroom = prefs.getString('selected_classroom');

  runApp(MyApp(initialClassroom: savedClassroom));
}

class MyApp extends StatelessWidget {
  final String? initialClassroom;

  const MyApp({super.key, this.initialClassroom});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stapro Hackathon A',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: initialClassroom != null
          ? const ScanPage()
          : const ClassroomSelectionPage(),
    );
  }
}

