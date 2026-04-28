import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/routine/routine_provider.dart';
import 'main_shell.dart';

class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineAsync = ref.watch(routineProvider);

    return routineAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('초기화 오류: $e')),
      ),
      data: (routine) =>
          routine == null ? const OnboardingScreen() : const MainShell(),
    );
  }
}
