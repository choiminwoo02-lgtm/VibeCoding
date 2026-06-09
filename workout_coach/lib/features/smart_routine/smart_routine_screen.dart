import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/exercise_db.dart';
import '../../core/models/routine.dart';
import '../routine/routine_provider.dart';

class SmartRoutineScreen extends ConsumerStatefulWidget {
  final List<String> selectedDays;

  const SmartRoutineScreen({super.key, required this.selectedDays});

  @override
  ConsumerState<SmartRoutineScreen> createState() =>
      _SmartRoutineScreenState();
}

class _SmartRoutineScreenState extends ConsumerState<SmartRoutineScreen> {
  final Set<String> _selectedPartIds = {};
  int _exercisesPerDay = 4;
  bool _isSaving = false;

  void _togglePart(String id) {
    setState(() {
      if (_selectedPartIds.contains(id)) {
        _selectedPartIds.remove(id);
      } else {
        _selectedPartIds.add(id);
      }
    });
  }

  Future<void> _generate() async {
    if (_selectedPartIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('운동 부위를 1개 이상 선택해주세요')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final random = Random();
    final partIds = _selectedPartIds.toList()..shuffle(random);
    final daysCount = widget.selectedDays.length;
    final partsCount = partIds.length;

    final weeklyPlan = List.generate(daysCount, (i) {
      final List<String> dayPartIds;

      if (partsCount <= daysCount) {
        // 부위 수 ≤ 일수: 하루에 부위 하나씩 (남으면 순환)
        dayPartIds = [partIds[i % partsCount]];
      } else {
        // 부위 수 > 일수: 여러 부위를 하루에 배분
        final perDay = (partsCount / daysCount).ceil();
        final start = i * perDay;
        dayPartIds = partIds.sublist(
          start.clamp(0, partsCount),
          (start + perDay).clamp(0, partsCount),
        );
      }

      final exercises = <ExerciseItem>[];
      final exPerPart = (_exercisesPerDay / dayPartIds.length).ceil();

      for (final partId in dayPartIds) {
        final part = bodyParts.firstWhere((b) => b.id == partId);
        final shuffled = [...part.exercises]..shuffle(random);
        final count = exPerPart.clamp(1, part.exercises.length);
        exercises.addAll(shuffled.take(count).map((t) => ExerciseItem(
          name: t.name,
          sets: t.defaultSets,
          reps: t.defaultReps,
          description: t.description,
        )));
      }

      final focusNames = dayPartIds
          .map((id) => bodyParts.firstWhere((b) => b.id == id).name)
          .join('+');

      return RoutineDay(
        day: widget.selectedDays[i],
        focus: focusNames,
        exercises: exercises,
      );
    });

    final routine = Routine(
      name: '추천 루틴',
      daysPerWeek: widget.selectedDays.length,
      weeklyPlan: weeklyPlan,
      createdAt: DateTime.now(),
    );

    await ref.read(routineProvider.notifier).saveManualRoutine(routine);

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Text('루틴 추천',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  Text('운동 부위 선택',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('원하는 부위를 모두 선택하세요 (복수 선택 가능)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: bodyParts.map((part) {
                      final isSelected =
                          _selectedPartIds.contains(part.id);
                      return GestureDetector(
                        onTap: () => _togglePart(part.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? primary
                                  : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                            color: isSelected
                                ? primary.withValues(alpha: 0.08)
                                : Colors.white,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(part.emoji,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Text(part.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? primary : null,
                                  )),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.check_circle,
                                    size: 16, color: primary),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 36),
                  Text('하루 종목 수',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('하루에 몇 가지 운동을 할까요?',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                  const SizedBox(height: 16),
                  Row(
                    children: [3, 4, 5, 6].map((n) {
                      final isSelected = _exercisesPerDay == n;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _exercisesPerDay = n),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? primary
                                  : Colors.grey.shade100,
                            ),
                            child: Center(
                              child: Text(
                                '$n개',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 36),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: primary.withValues(alpha: 0.06),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '선택한 부위를 ${widget.selectedDays.join(', ')}에 골고루 배분해 루틴을 만들어 드립니다.',
                            style: TextStyle(color: primary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _generate,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.shuffle),
              label: Text(_isSaving ? '생성 중...' : '루틴 생성하기'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ),
      ),
    );
  }
}
