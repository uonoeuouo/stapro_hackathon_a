import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/attendance/presentation/screens/home_screen.dart';

import 'features/attendance/presentation/screens/clock_in_screen.dart';
import 'features/attendance/presentation/screens/clock_out_screen.dart';
import 'features/attendance/presentation/screens/settings_screen.dart';
import 'features/attendance/presentation/screens/attendance_success_screen.dart';
import 'features/attendance/presentation/screens/card_management_screen.dart';
import 'features/attendance/presentation/screens/employee_selection_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/employee-selection',
        builder: (context, state) => const EmployeeSelectionScreen(),
      ),
      GoRoute(
        path: '/clock-in',
        builder: (context, state) => const ClockInScreen(),
      ),
      GoRoute(
        path: '/clock-out',
        builder: (context, state) => const ClockOutScreen(),
      ),
      GoRoute(
        path: '/success',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AttendanceSuccessScreen(
            type: extra['type'],
            commuteInfo: extra['commuteInfo'],
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/card-management',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CardManagementScreen(
            employeeId: extra['employeeId'] as int,
            employeeName: extra['employeeName'] as String,
          );
        },
      ),
    ],
  );
});
