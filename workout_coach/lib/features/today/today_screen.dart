import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/routine.dart';
import '../../core/models/workout_record.dart';
import '../../shared/goal_constants.dart';
import '../routine/routine_provider.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineAsync = ref.watch(routineProvider);

    return routineAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('오류: $e'))),
      data: (routine) {
        if (routine == null) {
          return const Scaffold(
            body: Center(child: Text('루틴 없음')),
          );
        }
        final today = DateTime.now();
        final todayDay = routine.weeklyPlan
            .where((d) => dayNameToWeekday[d.day] == today.weekday)
            .firstOrNull;

        if (todayDay == null) {
          return _RestDayScreen(routine: routine);
        }
        return _WorkoutScreen(routine: routine, todayDay: todayDay);
      },
    );
  }
}

class _RestDayScreen extends StatelessWidget {
  final Routine routine;
  const _RestDayScreen({required this.routine});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final workoutDays = routine.weeklyPlan.map((d) => d.day).join(', ');

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('M월 d일', 'ko_KR').format(today)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😴', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              Text(
                '오늘은 휴식일이에요!',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '충분한 휴식도 운동만큼 중요합니다.\n몸이 회복되는 시간을 가져보세요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '운동일: $workoutDays',
                  style: TextStyle(
                    color:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutScreen extends ConsumerStatefulWidget {
  final Routine routine;
  final RoutineDay todayDay;

  const _WorkoutScreen({required this.routine, required this.todayDay});

  @override
  ConsumerState<_WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<_WorkoutScreen> {
  List<bool>? _completedList;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final record = await ref
        .read(databaseProvider)
        .getRecordForDate(DateTime.now());
    if (mounted) {
      setState(() {
        _completedList = record != null
            ? List.from(record.completedList)
            : List.filled(widget.todayDay.exercises.length, false);
      });
    }
  }

  int get _completedCount =>
      _completedList?.where((c) => c).length ?? 0;
  int get _totalCount => widget.todayDay.exercises.length;

  Future<void> _saveRecord() async {
    if (_completedList == null) return;
    setState(() => _isSaving = true);

    final record = WorkoutRecord(
      routineId: widget.routine.id!,
      date: DateTime.now(),
      dayName: widget.todayDay.day,
      focus: widget.todayDay.focus,
      exercises: widget.todayDay.exercises,
      completedList: _completedList!,
      createdAt: DateTime.now(),
    );

    await ref.read(recordsProvider.notifier).saveRecord(record);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '저장 완료! $_completedCount/$_totalCount 운동 완료 💪',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('M월 d일', 'ko_KR').format(today)),
        bottom: _completedList == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(6),
                child: LinearProgressIndicator(
                  value: _totalCount == 0
                      ? 0
                      : _completedCount / _totalCount,
                  minHeight: 6,
                ),
              ),
      ),
      body: _completedList == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DayHeader(
                  day: widget.todayDay.day,
                  focus: widget.todayDay.focus,
                  completed: _completedCount,
                  total: _totalCount,
                ),
                const SizedBox(height: 16),
                ...List.generate(widget.todayDay.exercises.length, (i) {
                  final ex = widget.todayDay.exercises[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ExerciseTile(
                      exercise: ex,
                      isCompleted: _completedList![i],
                      onToggle: (v) => setState(
                          () => _completedList![i] = v),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveRecord,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: const Text('운동 기록 저장'),
                    style: FilledButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String day;
  final String focus;
  final int completed;
  final int total;

  const _DayHeader({
    required this.day,
    required this.focus,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$day 운동',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                    ),
              ),
              Text(
                focus,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '$completed / $total',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color:
                      Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final ExerciseItem exercise;
  final bool isCompleted;
  final ValueChanged<bool> onToggle;

  const _ExerciseTile({
    required this.exercise,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          width: isCompleted ? 2 : 1,
        ),
        color: isCompleted
            ? Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.06)
            : Colors.white,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onToggle(!isCompleted),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade200,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompleted ? Colors.grey : null,
                      ),
                    ),
                    if (exercise.description.isNotEmpty)
                      Text(
                        exercise.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${exercise.sets}×${exercise.reps}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? Colors.white
                        : Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
