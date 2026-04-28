import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'shared/app_router.dart';

class WorkoutCoachApp extends StatelessWidget {
  const WorkoutCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 운동 코치',
      theme: AppTheme.theme,
      home: const AppRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}
