import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:openapi/api.dart';
import '../../../../theme/app_theme.dart';
import '../../data/providers.dart';

class ClockInScreen extends ConsumerStatefulWidget {
  const ClockInScreen({super.key});

  @override
  ConsumerState<ClockInScreen> createState() => _ClockInScreenState();
}

class _ClockInScreenState extends ConsumerState<ClockInScreen> {
  bool _isLoading = false;
  Timer? _timer;
  int _countdown = 15;

  @override
  void initState() {
    super.initState();
    _startAutoConfirmTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoConfirmTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) setState(() => _countdown--);
      } else {
        _timer?.cancel();
        _handleClockIn();
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    if (mounted) setState(() => _countdown = 0);
  }

  Future<void> _handleClockIn() async {
    _cancelTimer();
    if (_isLoading) return;

    final employee = ref.read(currentEmployeeProvider);
    if (employee == null) return;

    // Get selected school ID, default to 1 if not set
    final schoolId = ref.read(selectedSchoolIdProvider) ?? 1;

    setState(() => _isLoading = true);

    try {
      final api = ref.read(attendanceApiProvider);
      final dto = ClockInDto(
        employeeId: employee['id'],
        terminalId: 'iPad-01',
        schoolId: schoolId,
        clientTimestamp: DateTime.now().toIso8601String(),
      );

      await api.attendanceControllerClockIn(dto);

      // Update provider with new attendance

      if (mounted) {
        context.go(
          '/success',
          extra: {'type': 'clock_in', 'commuteInfo': null},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employee = ref.watch(currentEmployeeProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('出勤打刻'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            _cancelTimer();
            context.go('/');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.credit_card),
            tooltip: 'カード管理',
            onPressed: () {
              _cancelTimer();
              context.push(
                '/card-management',
                extra: {
                  'employeeId': employee['id'],
                  'employeeName': employee['name'],
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.train),
            tooltip: '交通費設定',
            onPressed: () {
              _cancelTimer();
              context.push('/settings');
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Row(
          children: [
            // Left Column: Information
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(40),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: AppTheme.surfaceColor,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: AppTheme.primaryColor.withOpacity(0.5),
                          ),
                        ),
                      ).animate().scale(
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      ),
                      const SizedBox(height: 32),
                      Text(
                            'おはようございます',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                          )
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideX(begin: -0.2, end: 0),
                      const SizedBox(height: 16),
                      Text(
                            '${employee?['name']}さん',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          )
                          .animate()
                          .fadeIn(delay: 400.ms)
                          .slideX(begin: -0.2, end: 0),
                      const SizedBox(height: 40),
                      if (_countdown > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'あと$_countdown秒で自動的に出勤します',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(),
                    ],
                  ),
                ),
              ),
            ),
            // Right Column: Clock In Button
            Expanded(
              flex: 1,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.linear,
                      tween: Tween<double>(
                        begin: _countdown / 15,
                        end: _countdown / 15,
                      ),
                      builder: (context, value, _) => SizedBox(
                        width: 320,
                        height: 320,
                        child: CircularProgressIndicator(
                          value: value,
                          strokeWidth: 8,
                          backgroundColor: AppTheme.primaryColor.withOpacity(
                            0.1,
                          ),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                          width: 280,
                          height: 280,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleClockIn,
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              backgroundColor: AppTheme.primaryColor,
                              elevation: 12,
                              shadowColor: AppTheme.primaryColor.withOpacity(
                                0.5,
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.touch_app, size: 64),
                                      const SizedBox(height: 16),
                                      Text(
                                        '出勤する',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                          ),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.03, 1.03),
                          duration: 1500.ms,
                        )
                        .shimmer(
                          duration: 2000.ms,
                          color: Colors.white.withOpacity(0.2),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
