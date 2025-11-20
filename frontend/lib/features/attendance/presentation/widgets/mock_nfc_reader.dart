import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/app_theme.dart';
import '../../data/providers.dart';
import 'package:openapi/api.dart';
import 'package:go_router/go_router.dart';

class MockNfcReader extends ConsumerStatefulWidget {
  const MockNfcReader({super.key});

  @override
  ConsumerState<MockNfcReader> createState() => _MockNfcReaderState();
}

class _MockNfcReaderState extends ConsumerState<MockNfcReader> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleScan() async {
    final cardId = _controller.text;
    if (cardId.isEmpty) return;

    setState(() => _isLoading = true);
    ref.read(statusMessageProvider.notifier).state = '読み取り中...';

    try {
      final api = ref.read(attendanceApiProvider);
      final dto = CheckStatusDto(
        cardId: cardId,
        terminalId: 'iPad-01',
        clientTimestamp: DateTime.now().toIso8601String(),
      );

      // Use WithHttpInfo to get the full response object
      final response = await api.attendanceControllerCheckStatusWithHttpInfo(
        dto,
      );

      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, response.body);
      }

      ref.read(statusMessageProvider.notifier).state = '読み取り完了: $cardId';

      // Parse response body manually
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final employee = data['employee'];
      final attendance = data['attendance'];
      final templates = data['commute_templates'] as List<dynamic>;

      ref.read(currentEmployeeProvider.notifier).state = employee;
      ref.read(currentAttendanceProvider.notifier).state = attendance;
      ref.read(commuteTemplatesProvider.notifier).state = templates;
      ref.read(currentCardIdProvider.notifier).state = cardId;

      if (mounted) {
        if (attendance == null) {
          context.go('/clock-in');
        } else {
          context.go('/clock-out');
        }
      }
    } catch (e) {
      ref.read(statusMessageProvider.notifier).state = 'エラー: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(statusMessageProvider);

    return Container(
      width: 600,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'カードリーダー（シミュレーション）',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'カードID',
              prefixIcon: const Icon(Icons.credit_card),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'カードをかざす',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          if (status != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: status.contains('エラー')
                    ? AppTheme.errorColor.withOpacity(0.1)
                    : AppTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    status.contains('エラー')
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    color: status.contains('エラー')
                        ? AppTheme.errorColor
                        : AppTheme.secondaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status,
                      style: TextStyle(
                        color: status.contains('エラー')
                            ? AppTheme.errorColor
                            : AppTheme.secondaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn().slideX(begin: -0.1, end: 0),
            ),
          ],
        ],
      ),
    );
  }
}
