import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/exercise_visual.dart';
import 'routine_provider.dart';

class RoutineScreen extends ConsumerWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineAsync = ref.watch(routineProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        title: const Text('내 루틴', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
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
                  ...routine.weeklyPlan.map(
                    (day) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DayCard(routineDay: day),
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
  final dynamic routineDay;
  const _DayCard({required this.routineDay});

  @override
  Widget build(BuildContext context) {
    final muscle = ExerciseVisual.fromFocus(routineDay.focus as String);
    final color = ExerciseVisual.getColor(muscle);
    final emoji = ExerciseVisual.getEmoji(muscle);
    final imageUrl = ExerciseVisual.getImageUrl(muscle);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
            day: routineDay.day as String,
            focus: routineDay.focus as String,
            exerciseCount: (routineDay.exercises as List).length,
            color: color,
            emoji: emoji,
            imageUrl: imageUrl,
          ),
          children: [
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: (routineDay.exercises as List).map<Widget>((ex) {
                  return _ExerciseRow(exercise: ex, focus: routineDay.focus as String);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
  final dynamic exercise;
  final String focus;
  const _ExerciseRow({required this.exercise, required this.focus});

  @override
  Widget build(BuildContext context) {
    final muscle = ExerciseVisual.detect(exercise.name as String, focus);
    final color = ExerciseVisual.getColor(muscle);
    final imageUrl = ExerciseVisual.getExerciseImageUrl(exercise.name as String);
    final emoji = ExerciseVisual.getEmoji(muscle);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // 작은 이미지 썸네일
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
                Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name as String,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if ((exercise.description as String).isNotEmpty)
                  Text(
                    exercise.description as String,
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
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
