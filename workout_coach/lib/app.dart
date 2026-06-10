import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'shared/app_router.dart';
import 'shared/theme_provider.dart';

class WorkoutCoachApp extends ConsumerWidget {
  const WorkoutCoachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'AI 운동 코치',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AppRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}
