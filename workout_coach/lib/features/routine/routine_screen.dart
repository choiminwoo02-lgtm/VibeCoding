import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routine_provider.dart';

class RoutineScreen extends ConsumerWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineAsync = ref.watch(routineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 루틴'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RoutineHeader(
                name: routine.name,
                daysPerWeek: routine.daysPerWeek,
                createdAt: routine.createdAt,
              ),
              const SizedBox(height: 16),
              ...routine.weeklyPlan.map(
                (day) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DayCard(routineDay: day),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                '주 $daysPerWeek회',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.auto_awesome, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              const Text(
                'AI 생성 루틴',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final dynamic routineDay;
  const _DayCard({required this.routineDay});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              routineDay.day.substring(0, 1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        title: Text(
          routineDay.day,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${routineDay.focus}  ·  ${routineDay.exercises.length}가지 운동',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        children: routineDay.exercises.map<Widget>((ex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ex.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${ex.sets}세트 × ${ex.reps}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (ex.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            ex.description,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
