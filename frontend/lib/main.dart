import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screen/classroom_selection_page.dart';
import 'screen/scan_page.dart';
import 'services/scan_service.dart';

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
    // インスタンスを作成
    final scanService = RealScanService();

    return MaterialApp(
      title: 'Stapro Hackathon',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light, // Switch to Light Mode
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent, 
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3), // Bright Blue
          primary: const Color(0xFF2196F3),
          secondary: const Color(0xFF00BCD4), // Cyan
          tertiary: const Color(0xFFE91E63), // Pink accent
          surface: const Color(0xFFF5F9FF), // Very light blue tint
          onSurface: const Color(0xFF0D47A1), // Dark Blue text
        ),
        fontFamily: 'Roboto', 
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 1.2,
            color: Color(0xFF1565C0), // Darker Blue for title
          ),
          iconTheme: IconThemeData(color: Color(0xFF1565C0)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: const Color(0xFF2196F3).withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: initialClassroom != null
          ? ScanPage(scanService: scanService)
          : const ClassroomSelectionPage(),
    );
  }
}

