import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/exercise_visual.dart';
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
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('오류: $e'))),
      data: (routine) {
        if (routine == null) {
          return const Scaffold(body: Center(child: Text('루틴 없음')));
        }
        final today = DateTime.now();
        final todayDay = routine.weeklyPlan
            .where((d) => dayNameToWeekday[d.day] == today.weekday)
            .firstOrNull;

        return todayDay == null
            ? _RestDayScreen(routine: routine)
            : _WorkoutScreen(routine: routine, todayDay: todayDay);
      },
    );
  }
}

// ─── 휴식일 ───────────────────────────────────────────────────────────────────
class _RestDayScreen extends StatelessWidget {
  final Routine routine;
  const _RestDayScreen({required this.routine});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final workoutDays = routine.weeklyPlan.map((d) => d.day).join(' · ');
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF74B9FF), Color(0xFF0984E3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0984E3).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(child: Text('😴', style: TextStyle(fontSize: 52))),
              ),
              const SizedBox(height: 28),
              Text(
                DateFormat('M월 d일', 'ko_KR').format(today),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.grey.shade500,
                      letterSpacing: 1,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '오늘은 휴식일이에요!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                '충분한 휴식도 성장의 일부입니다.\n몸이 회복되는 시간을 즐기세요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                      height: 1.6,
                    ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fitness_center, size: 16, color: Color(0xFF0984E3)),
                    const SizedBox(width: 8),
                    Text(
                      '운동일: $workoutDays',
                      style: const TextStyle(
                        color: Color(0xFF0984E3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 운동일 ───────────────────────────────────────────────────────────────────
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
    final record = await ref.read(databaseProvider).getRecordForDate(DateTime.now());
    if (mounted) {
      setState(() {
        _completedList = record != null
            ? List.from(record.completedList)
            : List.filled(widget.todayDay.exercises.length, false);
      });
    }
  }

  int get _completedCount => _completedList?.where((c) => c).length ?? 0;
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
          content: Text('저장 완료! $_completedCount/$_totalCount 운동 완료 💪'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        title: Text(
          DateFormat('M월 d일 (E)', 'ko_KR').format(today),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_completedList != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$_completedCount/$_totalCount',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _completedList == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  children: [
                    _DayHeroCard(
                      day: widget.todayDay.day,
                      focus: widget.todayDay.focus,
                      completed: _completedCount,
                      total: _totalCount,
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(widget.todayDay.exercises.length, (i) {
                      return _ExerciseTile(
                        exercise: widget.todayDay.exercises[i],
                        focus: widget.todayDay.focus,
                        isCompleted: _completedList![i],
                        onToggle: (v) => setState(() => _completedList![i] = v),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
      floatingActionButton: _completedList == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveRecord,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text('운동 기록 저장', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ─── 히어로 카드 ───────────────────────────────────────────────────────────────
class _DayHeroCard extends StatelessWidget {
  final String day;
  final String focus;
  final int completed;
  final int total;

  const _DayHeroCard({
    required this.day,
    required this.focus,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final muscle = ExerciseVisual.fromFocus(focus);
    final color = ExerciseVisual.getColor(muscle);
    final imageUrl = ExerciseVisual.getImageUrl(muscle);
    final emoji = ExerciseVisual.getEmoji(muscle);
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: color),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.black.withValues(alpha: 0.2),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        focus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$day 운동',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$completed / $total 운동 완료',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _CircleProgress(progress: progress, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleProgress extends StatelessWidget {
  final double progress;
  final Color color;
  const _CircleProgress({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 5,
            backgroundColor: color.withValues(alpha: 0.25),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 운동 타일 ─────────────────────────────────────────────────────────────────
class _ExerciseTile extends StatelessWidget {
  final ExerciseItem exercise;
  final String? focus;
  final bool isCompleted;
  final ValueChanged<bool> onToggle;

  const _ExerciseTile({
    required this.exercise,
    this.focus,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final muscle = ExerciseVisual.detect(exercise.name, focus);
    final color = ExerciseVisual.getColor(muscle);
    final imageUrl = ExerciseVisual.getExerciseImageUrl(exercise.name);
    final emoji = ExerciseVisual.getEmoji(muscle);
    final label = ExerciseVisual.getLabel(muscle);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isCompleted ? color.withValues(alpha: 0.05) : Colors.white,
          border: isCompleted ? Border.all(color: color.withValues(alpha: 0.5), width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: isCompleted
                  ? color.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => onToggle(!isCompleted),
            child: SizedBox(
              height: 110,
              child: Row(
                children: [
                  // 왼쪽 이미지 영역
                  SizedBox(
                    width: 88,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, color.withValues(alpha: 0.7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                color.withValues(alpha: 0.45),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Container(color: Colors.black.withValues(alpha: 0.5)),
                        Center(
                          child: isCompleted
                              ? const Icon(Icons.check_circle_rounded, color: Colors.white, size: 36)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(emoji, style: const TextStyle(fontSize: 26)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        label,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  // 오른쪽 내용
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  exercise.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                                    color: isCompleted ? Colors.grey.shade400 : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isCompleted
                                        ? [Colors.grey.shade200, Colors.grey.shade300]
                                        : [color, color.withValues(alpha: 0.85)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${exercise.sets}×${exercise.reps}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted ? Colors.grey.shade500 : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (exercise.description.isNotEmpty) ...[
                            const SizedBox(height: 7),
                            Text(
                              exercise.description,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isCompleted
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                    height: 1.4,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
