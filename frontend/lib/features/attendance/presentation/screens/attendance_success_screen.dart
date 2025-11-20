import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_theme.dart';
import '../../data/providers.dart';

class AttendanceSuccessScreen extends ConsumerStatefulWidget {
  final String type; // 'clock_in' or 'clock_out'
  final Map<String, dynamic>? commuteInfo;

  const AttendanceSuccessScreen({
    super.key,
    required this.type,
    this.commuteInfo,
  });

  @override
  ConsumerState<AttendanceSuccessScreen> createState() =>
      _AttendanceSuccessScreenState();
}

class _AttendanceSuccessScreenState
    extends ConsumerState<AttendanceSuccessScreen> {
  late Timer _timer;
  int _countdown = 5;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        _timer.cancel();
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employee = ref.watch(currentEmployeeProvider);
    final isClockIn = widget.type == 'clock_in';
    final now = DateTime.now();
    final timeString = DateFormat('HH:mm').format(now);
    final dateString = DateFormat('yyyy/MM/dd (E)', 'ja').format(now);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withOpacity(0.95),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                      isClockIn
                          ? Icons.wb_sunny_rounded
                          : Icons.nights_stay_rounded,
                      size: 80,
                      color: AppTheme.primaryColor,
                    )
                    .animate()
                    .scale(duration: 400.ms, curve: Curves.easeOutBack)
                    .then()
                    .shimmer(duration: 1200.ms, color: AppTheme.secondaryColor),
                const SizedBox(height: 24),
                Text(
                  isClockIn ? '出勤しました' : '退勤しました',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 40),
                _buildInfoRow('日付', dateString, delay: 300),
                _buildInfoRow('時刻', timeString, delay: 400),
                if (employee != null)
                  _buildInfoRow('氏名', employee['name'], delay: 500),
                if (!isClockIn && widget.commuteInfo != null)
                  _buildInfoRow(
                    '交通費',
                    '${widget.commuteInfo!['name']} (¥${widget.commuteInfo!['cost']})',
                    delay: 600,
                  ),
                const SizedBox(height: 40),
                Text(
                  '$_countdown秒後にホームに戻ります',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ).animate().fadeIn(delay: 700.ms),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceColor,
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                  child: const Text('ホームに戻る'),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {required int delay}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: -0.1, end: 0);
  }
}
