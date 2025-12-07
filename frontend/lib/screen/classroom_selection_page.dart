import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'scan_page.dart';
import '../services/scan_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/gradient_scaffold.dart';

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
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('SELECT CLASSROOM'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Padding(
               padding: EdgeInsets.only(bottom: 24),
               child: Text("Choose your location to start", style: TextStyle(color: Colors.black54, fontSize: 16)),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: classrooms.length,
                itemBuilder: (context, index) {
                  final classroom = classrooms[index];
                  return GestureDetector(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('selected_classroom', classroom);
          
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => ScanPage(scanService: RealScanService()),
                          ),
                        );
                      }
                    },
                    child: GlassContainer(
                      padding: 16,
                      borderRadius: 24,
                      color: Colors.white.withOpacity(0.6), // Less transparent for tiles
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue, size: 40),
                          const SizedBox(height: 16),
                          Text(
                            classroom,
                            style: const TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0) // Dark Blue
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
