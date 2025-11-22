import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';
import '../../data/providers.dart';
import '../../../../theme/app_theme.dart';

class EmployeeSelectionScreen extends ConsumerStatefulWidget {
  const EmployeeSelectionScreen({super.key});

  @override
  ConsumerState<EmployeeSelectionScreen> createState() =>
      _EmployeeSelectionScreenState();
}

class _EmployeeSelectionScreenState
    extends ConsumerState<EmployeeSelectionScreen> {
  List<dynamic>? _employees;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(employeesApiProvider);
      // Use WithHttpInfo to handle potential void return or manual decoding if needed
      // Assuming findAll returns List<Employee> or similar
      final response = await api.employeeControllerFindAllWithHttpInfo();

      if (response.statusCode == 200) {
        final List<dynamic> employees =
            json.decode(response.body) as List<dynamic>;
        setState(() {
          _employees = employees;
          _isLoading = false;
        });
      } else {
        throw ApiException(response.statusCode, response.body);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load employees: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '従業員選択',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
              )
            : _employees == null || _employees!.isEmpty
            ? Center(
                child: Text(
                  '従業員が見つかりません',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 80),
                itemCount: _employees!.length,
                itemBuilder: (context, index) {
                  final employee = _employees![index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (employee['name'] as String)[0],
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        employee['name'],
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'ID: ${employee['id']}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: AppTheme.textSecondary,
                        size: 16,
                      ),
                      onTap: () {
                        context.push(
                          '/card-management',
                          extra: {
                            'employeeId': employee['id'],
                            'employeeName': employee['name'],
                          },
                        );
                      },
                    ),
                  ).animate().fadeIn(delay: (100 * index).ms).slideX();
                },
              ),
      ),
    );
  }
}
