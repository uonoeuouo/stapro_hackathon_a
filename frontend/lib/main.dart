import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      title: 'Stapro Hackathon A',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3), // Blue
          primary: const Color(0xFF2196F3),
          secondary: const Color(0xFF64B5F6), // Changed from 0xFF03A9F4
          surface: Colors.white,
          background: const Color(0xFFF5F9FF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F9FF),
        textTheme: GoogleFonts.notoSansJpTextTheme(), // Added this line
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF1565C0), // Dark Blue
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Color(0xFF1565C0)),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        // Note: GoogleFonts will be applied in individual widgets or via a text theme builder if needed,
        // but for now we'll stick to the default font with improved weights/sizes,
        // or apply it here if we import it.
        // Since I can't import it in this block without adding the import at the top,
        // I will add the import in a separate step or just rely on the theme structure first.
        // Actually, I should add the import.
      ),
      home: initialClassroom != null
          ? ScanPage(scanService: scanService)
          : const ClassroomSelectionPage(),
    );
  }
}
