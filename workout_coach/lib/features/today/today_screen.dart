import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/exercise_visual.dart';
import '../../core/models/routine.dart';
import '../../core/models/workout_record.dart';
import '../../shared/goal_constants.dart';
import '../routine/routine_provider.dart';

class _SetData {
  int reps;
  bool done;
  _SetData({required this.reps, this.done = false});
}

int _parseRepsToInt(String reps) {
  final match = RegExp(r'\d+').firstMatch(reps);
  return int.tryParse(match?.group(0) ?? '') ?? 10;
}

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

// ─── 인사 섹션 ─────────────────────────────────────────────────────────────────
class _GreetingHeader extends StatelessWidget {
  final String focus;
  const _GreetingHeader({required this.focus});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 6
        ? '이른 아침 운동 🌅'
        : hour < 12
            ? '좋은 아침이에요 ☀️'
            : hour < 18
                ? '오후 운동 파이팅 💪'
                : '저녁 운동 화이팅 🌙';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '오늘의 $focus 운동',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
        ),
      ],
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
  List<List<_SetData>>? _setsPerExercise;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final record = await ref.read(databaseProvider).getRecordForDate(DateTime.now());
    if (!mounted) return;
    setState(() {
      _setsPerExercise = widget.todayDay.exercises.asMap().entries.map((e) {
        final defaultReps = _parseRepsToInt(e.value.reps);
        final sets = List.generate(e.value.sets, (_) => _SetData(reps: defaultReps));
        if (record != null &&
            e.key < record.completedList.length &&
            record.completedList[e.key]) {
          for (final s in sets) s.done = true;
        }
        return sets;
      }).toList();
    });
  }

  bool _isExerciseDone(int i) {
    if (_setsPerExercise == null || i >= _setsPerExercise!.length) return false;
    final sets = _setsPerExercise![i];
    return sets.isNotEmpty && sets.every((s) => s.done);
  }

  int get _completedCount {
    if (_setsPerExercise == null) return 0;
    return List.generate(_setsPerExercise!.length, (i) => _isExerciseDone(i))
        .where((v) => v)
        .length;
  }

  int get _totalCount => widget.todayDay.exercises.length;

  Future<void> _saveRecord() async {
    if (_setsPerExercise == null) return;
    setState(() => _isSaving = true);

    final exercises = widget.todayDay.exercises.asMap().entries.map((e) {
      final sets = _setsPerExercise![e.key];
      if (sets.isEmpty) return e.value;
      final avgReps =
          (sets.map((s) => s.reps).reduce((a, b) => a + b) / sets.length)
              .round();
      return ExerciseItem(
        name: e.value.name,
        sets: sets.length,
        reps: '${avgReps}회',
        description: e.value.description,
      );
    }).toList();

    final record = WorkoutRecord(
      routineId: widget.routine.id!,
      date: DateTime.now(),
      dayName: widget.todayDay.day,
      focus: widget.todayDay.focus,
      exercises: exercises,
      completedList: List.generate(_totalCount, (i) => _isExerciseDone(i)),
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
      appBar: AppBar(
        title: Text(
          DateFormat('M월 d일 (E)', 'ko_KR').format(today),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF6B7280),
          ),
        ),
        actions: [
          if (_setsPerExercise != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_completedCount / $_totalCount',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _setsPerExercise == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    _GreetingHeader(focus: widget.todayDay.focus),
                    const SizedBox(height: 20),
                    _DayHeroCard(
                      day: widget.todayDay.day,
                      focus: widget.todayDay.focus,
                      completed: _completedCount,
                      total: _totalCount,
                    ),
                    const SizedBox(height: 24),
                    ...List.generate(widget.todayDay.exercises.length, (i) {
                      return _ExerciseTile(
                        exercise: widget.todayDay.exercises[i],
                        focus: widget.todayDay.focus,
                        sets: _setsPerExercise![i],
                        onSetsChanged: (newSets) =>
                            setState(() => _setsPerExercise![i] = newSets),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
      floatingActionButton: _setsPerExercise == null
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
class _ExerciseTile extends StatefulWidget {
  final ExerciseItem exercise;
  final String? focus;
  final List<_SetData> sets;
  final void Function(List<_SetData>) onSetsChanged;

  const _ExerciseTile({
    required this.exercise,
    this.focus,
    required this.sets,
    required this.onSetsChanged,
  });

  @override
  State<_ExerciseTile> createState() => _ExerciseTileState();
}

class _ExerciseTileState extends State<_ExerciseTile> {
  bool _expanded = false;

  bool get _isDone =>
      widget.sets.isNotEmpty && widget.sets.every((s) => s.done);
  int get _doneCount => widget.sets.where((s) => s.done).length;

  void _addSet() {
    final defaultReps = widget.sets.isNotEmpty ? widget.sets.last.reps : 10;
    widget.onSetsChanged([...widget.sets, _SetData(reps: defaultReps)]);
  }

  void _removeSet() {
    if (widget.sets.length <= 1) return;
    widget.onSetsChanged(widget.sets.sublist(0, widget.sets.length - 1));
  }

  void _updateReps(int idx, int delta) {
    final updated = List<_SetData>.from(widget.sets);
    updated[idx] =
        _SetData(reps: (updated[idx].reps + delta).clamp(1, 99), done: updated[idx].done);
    widget.onSetsChanged(updated);
  }

  void _toggleSetDone(int idx) {
    final updated = List<_SetData>.from(widget.sets);
    updated[idx] = _SetData(reps: updated[idx].reps, done: !updated[idx].done);
    widget.onSetsChanged(updated);
  }

  void _toggleAllDone() {
    final allDone = _isDone;
    widget.onSetsChanged(
      widget.sets.map((s) => _SetData(reps: s.reps, done: !allDone)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muscle = ExerciseVisual.detect(widget.exercise.name, widget.focus);
    final color = ExerciseVisual.getColor(muscle);
    final imageUrl = ExerciseVisual.getExerciseImageUrl(widget.exercise.name);
    final emoji = ExerciseVisual.getEmoji(muscle);
    final label = ExerciseVisual.getLabel(muscle);
    final firstReps = widget.sets.isNotEmpty ? widget.sets.first.reps : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _isDone
              ? color.withValues(alpha: 0.05)
              : Theme.of(context).colorScheme.surface,
          border: _isDone ? Border.all(color: color.withValues(alpha: 0.5), width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: _isDone
                  ? color.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // ── 헤더 (탭 → 펼치기/접기) ─────────────────────────────────
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: SizedBox(
                  height: 110,
                  child: Row(
                    children: [
                      // 왼쪽 이미지
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
                            if (_isDone)
                              Container(color: Colors.black.withValues(alpha: 0.5)),
                            Center(
                              child: _isDone
                                  ? const Icon(Icons.check_circle_rounded,
                                      color: Colors.white, size: 36)
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(emoji,
                                            style: const TextStyle(fontSize: 26)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
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
                      // 오른쪽 정보
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.exercise.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        decoration: _isDone
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: _isDone ? Colors.grey.shade400 : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: _isDone
                                            ? [
                                                Colors.grey.shade200,
                                                Colors.grey.shade300
                                              ]
                                            : [color, color.withValues(alpha: 0.85)],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${widget.sets.length}세트×${firstReps}회',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _isDone
                                            ? Colors.grey.shade500
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.exercise.description.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  widget.exercise.description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: _isDone
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                        height: 1.4,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    '$_doneCount/${widget.sets.length} 세트 완료',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _isDone ? color : Colors.grey.shade500,
                                      fontWeight:
                                          _isDone ? FontWeight.bold : null,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    _expanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: Colors.grey.shade400,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── 세트 상세 패널 ──────────────────────────────────────────
              if (_expanded) ...[
                Divider(height: 1, color: Colors.grey.shade200),
                // 세트 수 컨트롤
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: Row(
                    children: [
                      Text('세트 수',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                              fontSize: 14)),
                      const Spacer(),
                      _StepButton(
                        icon: Icons.remove,
                        onTap: widget.sets.length > 1 ? _removeSet : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text('${widget.sets.length}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      _StepButton(icon: Icons.add, onTap: _addSet),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade100),
                // 세트별 행
                ...widget.sets.asMap().entries.map((e) => _SetRow(
                      setNumber: e.key + 1,
                      reps: e.value.reps,
                      done: e.value.done,
                      color: color,
                      onToggle: () => _toggleSetDone(e.key),
                      onDecrement: () => _updateReps(e.key, -1),
                      onIncrement: () => _updateReps(e.key, 1),
                    )),
                // 전체 완료 버튼
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: _isDone
                        ? OutlinedButton.icon(
                            onPressed: _toggleAllDone,
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('완료 취소'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: _toggleAllDone,
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('전체 완료'),
                            style: FilledButton.styleFrom(
                              backgroundColor: color,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 세트 행 ───────────────────────────────────────────────────────────────────
class _SetRow extends StatelessWidget {
  final int setNumber;
  final int reps;
  final bool done;
  final Color color;
  final VoidCallback onToggle;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _SetRow({
    required this.setNumber,
    required this.reps,
    required this.done,
    required this.color,
    required this.onToggle,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: done ? color.withValues(alpha: 0.04) : null,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // 세트 번호
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done ? color : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$setNumber',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: done ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '세트 $setNumber',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: done ? Colors.grey.shade400 : Colors.grey.shade700,
              decoration: done ? TextDecoration.lineThrough : null,
            ),
          ),
          const Spacer(),
          // 횟수 조절
          _StepButton(icon: Icons.remove, onTap: done ? null : onDecrement),
          SizedBox(
            width: 52,
            child: Center(
              child: Text(
                '${reps}회',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: done ? Colors.grey.shade400 : null,
                ),
              ),
            ),
          ),
          _StepButton(icon: Icons.add, onTap: done ? null : onIncrement),
          const SizedBox(width: 12),
          // 완료 체크박스
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: done ? color : Colors.transparent,
                border: Border.all(
                    color: done ? color : Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: done
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 스텝 버튼 ──────────────────────────────────────────────────────────────────
class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
        ),
      ),
    );
  }
}
