import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openapi/api.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'nfc_reader_interface.dart';
import 'mock_nfc_reader_impl.dart';
// Conditional import: use web_serial on web, stub on other platforms
import 'web_serial_nfc_reader.dart' if (dart.library.io) 'web_serial_stub.dart';
import 'pcsc_nfc_reader_stub.dart' if (dart.library.io) 'pcsc_nfc_reader.dart';

// SharedPreferences Provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

// Initialize classroom from SharedPreferences
final initializeClassroomProvider = FutureProvider<void>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final schoolId = prefs.getInt('selected_school_id');
  final schoolName = prefs.getString('selected_school_name');

  if (schoolId != null) {
    ref.read(selectedSchoolIdProvider.notifier).state = schoolId;
  }
  if (schoolName != null) {
    ref.read(selectedSchoolNameProvider.notifier).state = schoolName;
  }
});

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

final cardsApiProvider = Provider<CardsApi>((ref) {
  return CardsApi(ref.watch(apiClientProvider));
});

final employeesApiProvider = Provider<EmployeesApi>((ref) {
  return EmployeesApi(ref.watch(apiClientProvider));
});

final schoolsApiProvider = Provider<SchoolsApi>((ref) {
  return SchoolsApi(ref.watch(apiClientProvider));
});

// NFC Reader Provider - chooses implementation based on platform
final nfcReaderProvider = Provider<NfcReaderInterface>((ref) {
  // Use Web Serial API on web
  if (kIsWeb) {
    try {
      return WebSerialNfcReader();
    } catch (e) {
      // Fallback to mock if Web Serial is not available
      return MockNfcReaderImpl();
    }
  } else {
    // Use PCSC reader on desktop platforms (macOS, Windows, Linux)
    // Fallback to mock if PCSC fails (handled inside PcscNfcReader or here?)
    // Let's try PcscNfcReader. If it fails to initialize, the UI will show error/retry.
    return PcscNfcReader(ref);
  }
});

// State for current scanned card
final currentCardIdProvider = StateProvider<String?>((ref) => null);

// State for current employee info (fetched after scan)
// Note: The generated client might return Map<String, dynamic> or specific DTOs.
// I need to check the return type of checkStatus.
final currentEmployeeProvider = StateProvider<dynamic>((ref) => null);
final currentAttendanceProvider = StateProvider<dynamic>((ref) => null);
final commuteTemplatesProvider = StateProvider<List<dynamic>>((ref) => []);

// State for selected classroom
final selectedSchoolIdProvider = StateProvider<int?>((ref) => null);
final selectedSchoolNameProvider = StateProvider<String?>((ref) => null);

// State for UI status (loading, error, success)
// State for UI status (loading, error, success)
final statusMessageProvider = StateProvider<String?>((ref) => null);

// Debug log provider
final debugLogProvider = StateProvider<List<String>>((ref) => []);
