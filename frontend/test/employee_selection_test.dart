import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:openapi/api.dart';
import 'package:frontend/features/attendance/data/providers.dart';
import 'package:frontend/features/attendance/presentation/screens/employee_selection_screen.dart';

// Mock Classes
class MockEmployeesApi implements EmployeesApi {
  @override
  ApiClient get apiClient => ApiClient();

  @override
  Future<Response> employeeControllerFindAllWithHttpInfo() async {
    final employees = [
      {'id': 1, 'name': 'Test User 1'},
      {'id': 2, 'name': 'Test User 2'},
    ];
    return Response(json.encode(employees), 200);
  }

  @override
  Future<void> employeeControllerFindAll() async {
    return Future.value();
  }
}

void main() {
  testWidgets('EmployeeSelectionScreen loads and displays employees', (
    WidgetTester tester,
  ) async {
    final mockApi = MockEmployeesApi();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [employeesApiProvider.overrideWithValue(mockApi)],
        child: const MaterialApp(home: EmployeeSelectionScreen()),
      ),
    );

    // Initial load
    await tester.pump(); // Start future
    await tester.pump(); // Finish future

    // Verify employees are displayed
    expect(find.text('Test User 1'), findsOneWidget);
    expect(find.text('ID: 1'), findsOneWidget);
    expect(find.text('Test User 2'), findsOneWidget);
    expect(find.text('ID: 2'), findsOneWidget);
  });
}
