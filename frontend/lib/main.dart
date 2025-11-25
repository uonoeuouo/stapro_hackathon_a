import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'features/attendance/data/providers.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting('ja');

  // Initialize SharedPreferences before running app
  final prefs = await SharedPreferences.getInstance();
  final schoolId = prefs.getInt('selected_school_id');
  final schoolName = prefs.getString('selected_school_name');

  final initialRoute = schoolId == null ? '/classroom-selection' : '/';

  runApp(
    ProviderScope(
      overrides: [
        initialRouteProvider.overrideWithValue(initialRoute),
        if (schoolId != null)
          selectedSchoolIdProvider.overrideWith((ref) => schoolId),
        if (schoolName != null)
          selectedSchoolNameProvider.overrideWith((ref) => schoolName),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'iPad勤怠管理',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
