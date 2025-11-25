import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'package:openapi/api.dart';
import '../../data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClassroomSelectionScreen extends ConsumerStatefulWidget {
  const ClassroomSelectionScreen({super.key});

  @override
  ConsumerState<ClassroomSelectionScreen> createState() =>
      _ClassroomSelectionScreenState();
}

class _ClassroomSelectionScreenState
    extends ConsumerState<ClassroomSelectionScreen> {
  List<dynamic> _schools = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSchools();
  }

  Future<void> _fetchSchools() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(schoolsApiProvider);
      final response = await api.schoolsControllerGetSchoolsWithHttpInfo();

      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, response.body);
      }

      final data = jsonDecode(response.body);
      setState(() {
        _schools = data is List ? data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '教室の取得に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectSchool(dynamic school) async {
    final schoolId = school['id'] as int;
    final schoolName = school['name'] as String;

    // Save to state
    ref.read(selectedSchoolIdProvider.notifier).state = schoolId;
    ref.read(selectedSchoolNameProvider.notifier).state = schoolName;

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_school_id', schoolId);
    await prefs.setString('selected_school_name', schoolName);

    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF2196F3), const Color(0xFF9C27B0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.school,
                      size: 80,
                      color: Colors.white,
                    ).animate().scale(delay: 200.ms),
                    const SizedBox(height: 24),
                    Text(
                      '教室を選択してください',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _fetchSchools, child: const Text('再試行')),
          ],
        ),
      );
    }

    if (_schools.isEmpty) {
      return const Center(child: Text('教室が見つかりませんでした'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _schools.length,
      itemBuilder: (context, index) {
        final school = _schools[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => _selectSchool(school),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school, color: Color(0xFF2196F3)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          school['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (school['kana'] != null)
                          Text(
                            school['kana'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        ).animate(delay: (100 * index).ms).fadeIn().slideX(begin: 0.2, end: 0);
      },
    );
  }
}
