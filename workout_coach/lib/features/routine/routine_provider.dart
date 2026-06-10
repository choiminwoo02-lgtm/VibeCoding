import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/claude_client.dart';
import '../../core/db/app_database.dart';
import '../../core/models/routine.dart';
import '../../core/models/user_goal.dart';
import '../../core/models/workout_record.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());
final claudeClientProvider = Provider<ClaudeClient>((ref) => ClaudeClient());

// Active routine
final routineProvider =
    AsyncNotifierProvider<RoutineNotifier, Routine?>(RoutineNotifier.new);

class RoutineNotifier extends AsyncNotifier<Routine?> {
  @override
  Future<Routine?> build() async {
    return ref.read(databaseProvider).getActiveRoutine();
  }

  Future<void> saveManualRoutine(Routine routine) async {
    state = const AsyncValue.loading();
    try {
      final saved = await ref.read(databaseProvider).saveRoutine(routine);
      ref.invalidate(recordsProvider);
      state = AsyncValue.data(saved);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> generateRoutine(UserGoal goal) async {
    state = const AsyncValue.loading();
    try {
      final routine =
          await ref.read(claudeClientProvider).generateRoutine(goal);
      final saved = await ref.read(databaseProvider).saveRoutine(routine);
      ref.invalidate(recordsProvider);
      state = AsyncValue.data(saved);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> swapExercise(int dayIndex, int exerciseIndex, ExerciseItem newEx) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWithSwap(dayIndex, exerciseIndex, newEx);
    state = AsyncValue.data(updated);
    try {
      await ref.read(databaseProvider).updateRoutine(updated);
    } catch (_) {
      state = AsyncValue.data(current);
    }
  }

  Future<void> resetRoutine() async {
    await ref.read(databaseProvider).clearAll();
    ref.invalidate(recordsProvider);
    state = const AsyncValue.data(null);
  }
}

// Workout records
final recordsProvider =
    AsyncNotifierProvider<RecordsNotifier, List<WorkoutRecord>>(
        RecordsNotifier.new);

class RecordsNotifier extends AsyncNotifier<List<WorkoutRecord>> {
  @override
  Future<List<WorkoutRecord>> build() async {
    return ref.read(databaseProvider).getAllRecords();
  }

  Future<void> saveRecord(WorkoutRecord record) async {
    final db = ref.read(databaseProvider);
    await db.insertRecord(record);
    state = await AsyncValue.guard(() => db.getAllRecords());
  }
}

// Today's record (derived)
final todayRecordProvider = Provider<WorkoutRecord?>((ref) {
  final records = ref.watch(recordsProvider).valueOrNull ?? [];
  final today = DateTime.now();
  return records
      .where((r) =>
          r.date.year == today.year &&
          r.date.month == today.month &&
          r.date.day == today.day)
      .firstOrNull;
});

// This week's records
final thisWeekRecordsProvider =
    FutureProvider<List<WorkoutRecord>>((ref) async {
  ref.watch(recordsProvider);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  return ref.read(databaseProvider).getRecordsForWeek(weekStart);
});
