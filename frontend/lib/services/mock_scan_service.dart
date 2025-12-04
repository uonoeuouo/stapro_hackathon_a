import 'scan_service.dart';

/// Mock implementation for testing without backend
class MockScanService implements ScanService {
  @override
  Future<Map<String, dynamic>> scanCard(String cardId) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Return a dummy success response
    return {
      "status": "ready_to_in",
      "user_name": "Test User",
      "message": "こんにちは、Test Userさん (Mock)"
    };
  }
}
