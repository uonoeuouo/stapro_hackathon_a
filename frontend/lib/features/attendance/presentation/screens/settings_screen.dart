import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';
import '../../../../theme/app_theme.dart';
import '../../data/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
    _fetchSchools();
  }

  Future<void> _fetchSchools() async {
    try {
      final api = ref.read(schoolsApiProvider);
      final response = await api.schoolsControllerGetSchoolsWithHttpInfo();

      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, response.body);
      }

      final data = jsonDecode(response.body);
      // Schools are returned in the response, we'll store them locally
      setState(() {
        // Store schools in a local variable if needed
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('教室の取得に失敗しました: $e')));
      }
    }
  }

  Future<void> _fetchTemplates() async {
    final employee = ref.read(currentEmployeeProvider);
    if (employee == null) return;

    setState(() => _isLoading = true);
    try {
      final api = ref.read(commuteTemplatesApiProvider);
      final response = await api.commuteTemplateControllerFindAllWithHttpInfo(
        employee['id'],
      );

      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, response.body);
      }

      final List<dynamic> templates = jsonDecode(response.body);
      ref.read(commuteTemplatesProvider.notifier).state = templates;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    final employee = ref.read(currentEmployeeProvider);
    if (employee == null) return;

    setState(() => _isLoading = true);
    try {
      final api = ref.read(commuteTemplatesApiProvider);
      final dto = CreateCommuteTemplateDto(
        employeeId: employee['id'],
        name: _nameController.text,
        cost: int.parse(_costController.text),
      );

      final response = await api.commuteTemplateControllerCreateWithHttpInfo(
        dto,
      );
      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, response.body);
      }

      _nameController.clear();
      _costController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('テンプレートを追加しました')));
        Navigator.pop(context); // Close dialog
        _fetchTemplates(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTemplate(int id) async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(commuteTemplatesApiProvider);
      final response = await api.commuteTemplateControllerRemoveWithHttpInfo(
        id,
      );
      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, response.body);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('テンプレートを削除しました')));
        _fetchTemplates();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTemplate(int id) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final api = ref.read(commuteTemplatesApiProvider);
      final dto = UpdateCommuteTemplateDto(
        name: _nameController.text,
        cost: int.parse(_costController.text),
      );

      final response = await api.commuteTemplateControllerUpdateWithHttpInfo(
        id,
        dto,
      );
      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, response.body);
      }

      _nameController.clear();
      _costController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('テンプレートを更新しました')));
        Navigator.pop(context); // Close dialog
        _fetchTemplates(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditDialog(dynamic template) {
    final id = template is Map ? template['id'] : (template as dynamic).id;
    final name = template is Map
        ? template['name']
        : (template as dynamic).name;
    final cost = template is Map
        ? template['cost']
        : (template as dynamic).cost;

    _nameController.text = name;
    _costController.text = cost.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テンプレートの編集'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '名称 (例: 電車)'),
                validator: (v) => v == null || v.isEmpty ? '必須です' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: '金額 (円)'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? '必須です' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => _updateTemplate(id),
            child: const Text('更新'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    _nameController.clear();
    _costController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新しいテンプレート'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '名称 (例: 電車)'),
                validator: (v) => v == null || v.isEmpty ? '必須です' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: '金額 (円)'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? '必須です' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(onPressed: _addTemplate, child: const Text('追加')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(commuteTemplatesProvider);
    final employee = ref.watch(currentEmployeeProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('交通費設定'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (employee != null)
            IconButton(
              icon: const Icon(Icons.credit_card),
              tooltip: 'カード管理',
              onPressed: () {
                context.go(
                  '/card-management',
                  extra: {
                    'employeeId': employee['id'],
                    'employeeName': employee['name'],
                  },
                );
              },
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : employee == null
            ? const Center(child: Text('従業員データがありません'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 80),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final t = templates[index];
                  final name = t is Map ? t['name'] : (t as dynamic).name;
                  final cost = t is Map ? t['cost'] : (t as dynamic).cost;
                  final id = t is Map ? t['id'] : (t as dynamic).id;

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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.train,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        '¥$cost',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            color: AppTheme.primaryColor,
                            onPressed: () => _showEditDialog(t),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: AppTheme.errorColor,
                            onPressed: () => _deleteTemplate(id),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: (100 * index).ms).slideX();
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('テンプレート追加'),
      ).animate().scale(delay: 500.ms),
    );
  }
}
