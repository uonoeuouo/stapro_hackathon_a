import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:openapi/api.dart';
import '../../../../theme/app_theme.dart';
import '../../data/providers.dart';

enum ClockOutStep { selection, input, confirmation }

class ClockOutScreen extends ConsumerStatefulWidget {
  const ClockOutScreen({super.key});

  @override
  ConsumerState<ClockOutScreen> createState() => _ClockOutScreenState();
}

class _ClockOutScreenState extends ConsumerState<ClockOutScreen> {
  ClockOutStep _currentStep = ClockOutStep.selection;
  dynamic _selectedTemplate;
  final _costController = TextEditingController();
  final _lessonCountController = TextEditingController(text: '0');
  Timer? _timer;
  int _countdown = 10;

  @override
  void initState() {
    super.initState();
    // Timer is not started initially
  }

  @override
  void dispose() {
    _timer?.cancel();
    _costController.dispose();
    _lessonCountController.dispose();
    super.dispose();
  }

  void _startAutoConfirmTimer() {
    _timer?.cancel();
    setState(() => _countdown = 10);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) setState(() => _countdown--);
      } else {
        _timer?.cancel();
        _handleClockOut();
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
  }

  void _resetState() {
    _cancelTimer();
    setState(() {
      _currentStep = ClockOutStep.selection;
      _selectedTemplate = null;
      _costController.clear();
    });
  }

  Future<void> _handleClockOut() async {
    _cancelTimer();
    final attendance = ref.read(currentAttendanceProvider);
    if (attendance == null) return;

    try {
      final api = ref.read(attendanceApiProvider);
      // Construct commute info
      final commuteInfo = {
        'template_id': _selectedTemplate?['id'],
        'cost': int.tryParse(_costController.text) ?? 0,
        'name': _selectedTemplate?['name'] ?? 'Custom',
      };

      final dto = ClockOutDto(
        attendanceId: attendance['id'],
        commuteInfo: commuteInfo,
        totalLesson: int.tryParse(_lessonCountController.text) ?? 0,
        clientTimestamp: DateTime.now().toIso8601String(),
      );
      await api.attendanceControllerClockOut(dto);

      if (mounted) {
        context.go(
          '/success',
          extra: {'type': 'clock_out', 'commuteInfo': commuteInfo},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employee = ref.watch(currentEmployeeProvider);
    final attendance = ref.watch(currentAttendanceProvider);

    final isClockedOut =
        attendance != null && attendance['clock_out_time'] != null;

    if (isClockedOut) {
      _cancelTimer(); // Cancel timer if already clocked out
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isClockedOut ? '本日の業務' : '退勤打刻'),
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
            icon: const Icon(Icons.settings),
            onPressed: () {
              _cancelTimer();
              context.push('/settings');
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: isClockedOut
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        size: 60,
                        color: AppTheme.secondaryColor,
                      ),
                    ).animate().scale(
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    ),
                    const SizedBox(height: 24),
                    Text(
                          'お疲れ様でした',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 8),
                    Text(
                          '${employee?['name']}さん',
                          style: Theme.of(context).textTheme.displayMedium,
                        )
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 20),
                    const Text(
                      '本日の業務は終了しています。',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                      ),
                      child: const Text('ホームに戻る'),
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () async {
                        if (attendance == null) return;
                        try {
                          final api = ref.read(attendanceApiProvider);
                          await api.attendanceControllerCancel(
                            attendance['id'],
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('退勤を取り消しました'),
                                backgroundColor: AppTheme.secondaryColor,
                              ),
                            );

                            // Re-fetch status
                            final cardId = ref.read(currentCardIdProvider);
                            if (cardId != null) {
                              final dto = CheckStatusDto(
                                cardId: cardId,
                                terminalId: 'iPad-01',
                                clientTimestamp: DateTime.now()
                                    .toIso8601String(),
                              );
                              final response = await api
                                  .attendanceControllerCheckStatusWithHttpInfo(
                                    dto,
                                  );
                              final data =
                                  jsonDecode(response.body)
                                      as Map<String, dynamic>;
                              ref.read(currentEmployeeProvider.notifier).state =
                                  data['employee'];
                              ref
                                      .read(currentAttendanceProvider.notifier)
                                      .state =
                                  data['attendance'];
                              ref
                                      .read(commuteTemplatesProvider.notifier)
                                      .state =
                                  data['commute_templates'] as List<dynamic>;
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('エラー: $e'),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                      ),
                      child: const Text('退勤を取り消す'),
                    ).animate().fadeIn(delay: 600.ms),
                  ],
                ),
              )
            : Row(
                children: [
                  // Left Column: Information
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(40),
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
                          if (employee != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'お疲れ様でした',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '${employee['name']}さん',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTimeRow(
                                  context,
                                  '現在時刻',
                                  DateTime.now(),
                                  isLarge: true,
                                ),
                                if (attendance != null &&
                                    attendance['clock_in_time'] != null) ...[
                                  const Divider(height: 32),
                                  _buildTimeRow(
                                    context,
                                    '出勤時刻',
                                    DateTime.parse(attendance['clock_in_time']),
                                  ),
                                ],
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: 32),
                          Center(
                            child: TextButton(
                              onPressed: () async {
                                if (attendance == null) return;
                                try {
                                  final api = ref.read(attendanceApiProvider);
                                  await api.attendanceControllerCancel(
                                    attendance['id'],
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('出勤を取り消しました'),
                                        backgroundColor:
                                            AppTheme.secondaryColor,
                                      ),
                                    );
                                    context.go('/');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('エラー: $e'),
                                        backgroundColor: AppTheme.errorColor,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.errorColor,
                              ),
                              child: const Text('出勤を取り消す'),
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                          const SizedBox(height: 24),
                          if (_currentStep == ClockOutStep.confirmation &&
                              _countdown > 0)
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
                                    'あと$_countdown秒で自動的に退勤します',
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
                  // Right Column: 3-Step Flow
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: _buildRightColumn(context),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRightColumn(BuildContext context) {
    switch (_currentStep) {
      case ClockOutStep.selection:
        return _buildSelectionStep(context);
      case ClockOutStep.input:
        return _buildInputStep(context);
      case ClockOutStep.confirmation:
        return _buildConfirmationStep(context);
    }
  }

  Widget _buildSelectionStep(BuildContext context) {
    final templates = ref.watch(commuteTemplatesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              ...templates.map(
                (t) => _buildSelectionCard(
                  context,
                  title: t['name'],
                  subtitle: '¥${t['cost']}',
                  icon: Icons.train,
                  onTap: () {
                    setState(() {
                      _selectedTemplate = t;
                      _costController.text = t['cost'].toString();
                      _currentStep = ClockOutStep.confirmation;
                    });
                    _startAutoConfirmTimer();
                  },
                ),
              ),
              _buildSelectionCard(
                context,
                title: '手入力',
                subtitle: '金額を指定',
                icon: Icons.keyboard,
                onTap: () {
                  setState(() {
                    _selectedTemplate = null;
                    _costController.clear();
                    _currentStep = ClockOutStep.input;
                  });
                },
              ),
              _buildSelectionCard(
                context,
                title: 'なし',
                subtitle: '¥0',
                icon: Icons.money_off,
                onTap: () {
                  setState(() {
                    _selectedTemplate = null;
                    _costController.text = '0';
                    _currentStep = ClockOutStep.confirmation;
                  });
                  _startAutoConfirmTimer();
                },
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildSelectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: AppTheme.primaryColor),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _resetState,
            ),
            const SizedBox(width: 8),
            Text(
              '金額を入力',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Spacer(),
        TextField(
          controller: _costController,
          autofocus: true,
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.currency_yen, size: 40),
            border: InputBorder.none,
            hintText: '0',
          ),
          onSubmitted: (_) {
            setState(() {
              _currentStep = ClockOutStep.confirmation;
            });
            _startAutoConfirmTimer();
          },
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = ClockOutStep.confirmation;
              });
              _startAutoConfirmTimer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text(
              '次へ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildConfirmationStep(BuildContext context) {
    final cost = _costController.text;
    final templateName = _selectedTemplate?['name'] ?? '手入力/なし';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          child: Column(
            children: [
              // Lesson Count Input
              TextField(
                controller: _lessonCountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                decoration: const InputDecoration(
                  labelText: 'コマ数',
                  labelStyle: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                templateName,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '¥$cost',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: -0.2, end: 0),
        const Spacer(),
        Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.linear,
              tween: Tween<double>(
                begin: _countdown / 10,
                end: _countdown / 10,
              ),
              builder: (context, value, _) => SizedBox(
                width: 300,
                height: 300,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.secondaryColor,
                  ),
                ),
              ),
            ),
            SizedBox(
                  width: 260,
                  height: 260,
                  child: ElevatedButton(
                    onPressed: _handleClockOut,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: AppTheme.secondaryColor,
                      elevation: 12,
                      shadowColor: AppTheme.secondaryColor.withOpacity(0.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.exit_to_app,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '退勤する',
                          style: Theme.of(context).textTheme.headlineMedium
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
                  onPlay: (controller) => controller.repeat(reverse: true),
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
        const Spacer(),
        TextButton(
          onPressed: _resetState,
          style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back),
              SizedBox(width: 8),
              Text('内容を変更する'),
            ],
          ),
        ).animate().fadeIn(),
      ],
    );
  }

  Widget _buildTimeRow(
    BuildContext context,
    String label,
    DateTime time, {
    bool isLarge = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 18 : 16,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat('HH:mm').format(time),
              style: TextStyle(
                fontSize: isLarge ? 32 : 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                height: 1.0,
              ),
            ),
            if (isLarge)
              Text(
                DateFormat('yyyy/MM/dd (E)', 'ja').format(time),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
