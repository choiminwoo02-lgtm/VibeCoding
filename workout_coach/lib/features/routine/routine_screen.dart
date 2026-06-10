import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/exercise_db.dart';
import '../../core/models/exercise_visual.dart';
import '../../core/models/routine.dart';
import '../../shared/theme_provider.dart';
import 'routine_provider.dart';

class RoutineScreen extends ConsumerWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineAsync = ref.watch(routineProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 루틴'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: isDark ? '라이트 모드' : '다크 모드',
            onPressed: () => ref.read(themeModeProvider.notifier).state =
                isDark ? ThemeMode.light : ThemeMode.dark,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '루틴 초기화',
            onPressed: () => _confirmReset(context, ref),
          ),
        ],
      ),
      body: routineAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (routine) {
          if (routine == null) {
            return const Center(child: Text('루틴이 없습니다'));
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  _RoutineHeader(
                    name: routine.name,
                    daysPerWeek: routine.daysPerWeek,
                    createdAt: routine.createdAt,
                  ),
                  const SizedBox(height: 20),
                  ...routine.weeklyPlan.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DayCard(
                        routineDay: entry.value,
                        dayIndex: entry.key,
                        onSwapExercise: (exIdx, newEx) =>
                            ref.read(routineProvider.notifier)
                                .swapExercise(entry.key, exIdx, newEx),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('루틴 초기화'),
        content: const Text('루틴과 모든 기록이 삭제됩니다.\n새 루틴을 생성하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(routineProvider.notifier).resetRoutine();
            },
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }
}

// ─── 루틴 헤더 ─────────────────────────────────────────────────────────────────
class _RoutineHeader extends StatelessWidget {
  final String name;
  final int daysPerWeek;
  final DateTime createdAt;

  const _RoutineHeader({
    required this.name,
    required this.daysPerWeek,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A86FF), Color(0xFF5E60CE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3A86FF).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatChip(icon: Icons.calendar_today, label: '주 $daysPerWeek회'),
              const SizedBox(width: 10),
              _StatChip(icon: Icons.fitness_center, label: '${daysPerWeek}일 루틴'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── 요일 카드 ─────────────────────────────────────────────────────────────────
class _DayCard extends StatelessWidget {
  final RoutineDay routineDay;
  final int dayIndex;
  final void Function(int exIdx, ExerciseItem newEx) onSwapExercise;

  const _DayCard({
    required this.routineDay,
    required this.dayIndex,
    required this.onSwapExercise,
  });

  @override
  Widget build(BuildContext context) {
    final muscle = ExerciseVisual.fromFocus(routineDay.focus);
    final color = ExerciseVisual.getColor(muscle);
    final emoji = ExerciseVisual.getEmoji(muscle);
    final imageUrl = ExerciseVisual.getImageUrl(muscle);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: _DayCardHeader(
            day: routineDay.day,
            focus: routineDay.focus,
            exerciseCount: routineDay.exercises.length,
            color: color,
            emoji: emoji,
            imageUrl: imageUrl,
          ),
          children: [
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: routineDay.exercises.asMap().entries.map<Widget>((entry) {
                  return _ExerciseRow(
                    exercise: entry.value,
                    focus: routineDay.focus,
                    onSwap: () => _showSwapSheet(
                      context,
                      entry.value.name,
                      routineDay.focus,
                      (newEx) => onSwapExercise(entry.key, newEx),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showSwapSheet(
  BuildContext context,
  String currentName,
  String dayFocus,
  void Function(ExerciseItem) onSelect,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ExerciseSwapSheet(
      currentName: currentName,
      dayFocus: dayFocus,
      onSelect: onSelect,
    ),
  );
}

class _DayCardHeader extends StatelessWidget {
  final String day;
  final String focus;
  final int exerciseCount;
  final Color color;
  final String emoji;
  final String imageUrl;

  const _DayCardHeader({
    required this.day,
    required this.focus,
    required this.exerciseCount,
    required this.color,
    required this.emoji,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      child: Row(
        children: [
          // 왼쪽 이미지 영역
          SizedBox(
            width: 80,
            height: 80,
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
                        color.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        focus,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$exerciseCount가지 운동',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── 운동 행 (루틴 화면 내부) ──────────────────────────────────────────────────
class _ExerciseRow extends StatelessWidget {
  final ExerciseItem exercise;
  final String focus;
  final VoidCallback onSwap;
  const _ExerciseRow({required this.exercise, required this.focus, required this.onSwap});

  @override
  Widget build(BuildContext context) {
    final muscle = ExerciseVisual.detect(exercise.name, focus);
    final color = ExerciseVisual.getColor(muscle);
    final imageUrl = ExerciseVisual.getExerciseImageUrl(exercise.name);
    final emoji = ExerciseVisual.getEmoji(muscle);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withValues(alpha: 0.15),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: color.withValues(alpha: 0.2)),
                ),
                Container(color: color.withValues(alpha: 0.3)),
                Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (exercise.description.isNotEmpty)
                  Text(
                    exercise.description,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${exercise.sets}세트 × ${exercise.reps}',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onSwap,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.swap_horiz_rounded, size: 16, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 종목 교체 시트 ────────────────────────────────────────────────────────────
class _ExerciseSwapSheet extends StatefulWidget {
  final String currentName;
  final String dayFocus;
  final void Function(ExerciseItem) onSelect;

  const _ExerciseSwapSheet({
    required this.currentName,
    required this.dayFocus,
    required this.onSelect,
  });

  @override
  State<_ExerciseSwapSheet> createState() => _ExerciseSwapSheetState();
}

class _ExerciseSwapSheetState extends State<_ExerciseSwapSheet> {
  late String _selectedPartId;

  @override
  void initState() {
    super.initState();
    final match = bodyParts.where((b) => widget.dayFocus.contains(b.name)).firstOrNull;
    _selectedPartId = match?.id ?? bodyParts.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final selectedPart = bodyParts.firstWhere((b) => b.id == _selectedPartId);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.swap_horiz_rounded, color: primary),
                const SizedBox(width: 8),
                Text('종목 변경', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text(
              '${widget.currentName}을(를) 다른 종목으로 바꿉니다',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: bodyParts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final part = bodyParts[i];
                final isSelected = part.id == _selectedPartId;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPartId = part.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? primary : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? primary : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      '${part.emoji} ${part.name}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isSelected ? FontWeight.bold : null,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.42),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: selectedPart.exercises.length,
              itemBuilder: (_, i) {
                final ex = selectedPart.exercises[i];
                final isCurrent = ex.name == widget.currentName;
                final muscle = ExerciseVisual.detect(ex.name, selectedPart.name);
                final color = ExerciseVisual.getColor(muscle);
                final emoji = ExerciseVisual.getEmoji(muscle);
                final imageUrl = ExerciseVisual.getExerciseImageUrl(ex.name);
                return ListTile(
                  leading: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: color.withValues(alpha: 0.15),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: color.withValues(alpha: 0.2)),
                        ),
                        Container(color: color.withValues(alpha: isCurrent ? 0.6 : 0.3)),
                        Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
                      ],
                    ),
                  ),
                  title: Text(
                    ex.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isCurrent ? Colors.grey.shade400 : null,
                    ),
                  ),
                  subtitle: Text(
                    '${ex.defaultSets}세트 × ${ex.defaultReps}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  trailing: isCurrent
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('현재', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        )
                      : Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  onTap: isCurrent ? null : () {
                    widget.onSelect(ExerciseItem(
                      name: ex.name,
                      sets: ex.defaultSets,
                      reps: ex.defaultReps,
                      description: ex.description,
                    ));
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// ─── 루틴 미리보기 화면 (저장 전 편집) ────────────────────────────────────────
class RoutinePreviewScreen extends ConsumerStatefulWidget {
  final Routine initialRoutine;
  const RoutinePreviewScreen({super.key, required this.initialRoutine});

  @override
  ConsumerState<RoutinePreviewScreen> createState() => _RoutinePreviewScreenState();
}

class _RoutinePreviewScreenState extends ConsumerState<RoutinePreviewScreen> {
  late Routine _routine;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _routine = widget.initialRoutine;
  }

  void _swap(int dayIdx, int exIdx, ExerciseItem newEx) {
    setState(() => _routine = _routine.copyWithSwap(dayIdx, exIdx, newEx));
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await ref.read(routineProvider.notifier).saveManualRoutine(_routine);
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('루틴 미리보기'),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '각 종목의 ↔ 버튼을 눌러 바꿀 수 있어요',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              ..._routine.weeklyPlan.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DayCard(
                    routineDay: entry.value,
                    dayIndex: entry.key,
                    onSwapExercise: (exIdx, newEx) => _swap(entry.key, exIdx, newEx),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(_isSaving ? '저장 중...' : '이 루틴으로 시작하기'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ),
      ),
    );
  }
}
