import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/app_theme.dart';
import '../widgets/nfc_reader_widget.dart';
import '../widgets/mock_nfc_reader.dart';
import '../../data/providers.dart';

import 'dart:async';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Timer _timer;
  late String _currentTime;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolName = ref.watch(selectedSchoolNameProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('勤怠管理システム'),
            Text(
              _currentTime,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: schoolName != null
            ? IconButton(
                icon: const Icon(Icons.school),
                tooltip: schoolName,
                onPressed: () => context.go('/classroom-selection'),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts, color: Colors.white),
            tooltip: 'カード管理',
            onPressed: () => context.push('/employee-selection'),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    const NfcReaderWidget()
                        .animate()
                        .fadeIn(delay: 600.ms)
                        .slideY(begin: 0.2, end: 0),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
