import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openapi/api.dart';

// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(basePath: 'http://localhost:3000');
});

// Attendance API Provider
final attendanceApiProvider = Provider<AttendanceApi>((ref) {
  return AttendanceApi(ref.watch(apiClientProvider));
});

final commuteTemplatesApiProvider = Provider<CommuteTemplatesApi>((ref) {
  return CommuteTemplatesApi(ref.watch(apiClientProvider));
});

// State for current scanned card
final currentCardIdProvider = StateProvider<String?>((ref) => null);

// State for current employee info (fetched after scan)
// Note: The generated client might return Map<String, dynamic> or specific DTOs.
// I need to check the return type of checkStatus.
final currentEmployeeProvider = StateProvider<dynamic>((ref) => null);
final currentAttendanceProvider = StateProvider<dynamic>((ref) => null);
final commuteTemplatesProvider = StateProvider<List<dynamic>>((ref) => []);

// State for UI status (loading, error, success)
final statusMessageProvider = StateProvider<String?>((ref) => null);
