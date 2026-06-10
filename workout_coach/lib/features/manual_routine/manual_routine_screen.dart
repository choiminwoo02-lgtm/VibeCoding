import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/exercise_db.dart';
import '../../core/models/exercise_visual.dart';
import '../../core/models/routine.dart';
import '../routine/routine_provider.dart';

class ManualRoutineScreen extends ConsumerStatefulWidget {
  const ManualRoutineScreen({super.key});

  @override
  ConsumerState<ManualRoutineScreen> createState() =>
      _ManualRoutineScreenState();
}

class _ManualRoutineScreenState extends ConsumerState<ManualRoutineScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController(text: '나만의 루틴');
  int _currentPage = 0;
  final List<String> _selectedDays = ['월요일', '수요일', '금요일'];

  // dayIndex → {bodyPartId → [선택된 운동 index 목록]}
  late List<Map<String, List<int>>> _selectedByDay;
  // dayIndex → 선택된 부위 id
  late List<String?> _focusByDay;

  @override
  void initState() {
    super.initState();
    _initDays();
  }

  void _initDays() {
    _selectedByDay = List.generate(_selectedDays.length, (_) => {});
    _focusByDay = List.generate(_selectedDays.length, (_) => null);
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        if (_selectedDays.length > 1) _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
      _initDays();
      if (_currentPage > _selectedDays.length) {
        _currentPage = 0;
        _pageController.jumpToPage(0);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  int get _totalPages => 1 + _selectedDays.length;

  void _goNext() {
    if (_currentPage == 0) {
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('루틴 이름을 입력해주세요')));
        return;
      }
    } else {
      final dayIdx = _currentPage - 1;
      final total = _selectedByDay[dayIdx].values.fold(0, (s, l) => s + l.length);
      if (total == 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('운동을 1개 이상 추가해주세요')));
        return;
      }
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _saveRoutine() async {
    final weeklyPlan = List.generate(_selectedDays.length, (i) {
      final selected = _selectedByDay[i];
      final focus = _focusByDay[i] != null
          ? bodyParts.firstWhere((b) => b.id == _focusByDay[i]!).name
          : '복합';
      final exercises = <ExerciseItem>[];
      for (final entry in selected.entries) {
        final part = bodyParts.firstWhere((b) => b.id == entry.key);
        for (final idx in entry.value) {
          final t = part.exercises[idx];
          exercises.add(ExerciseItem(
            name: t.name,
            sets: t.defaultSets,
            reps: t.defaultReps,
            description: t.description,
          ));
        }
      }
      return RoutineDay(day: _selectedDays[i], focus: focus, exercises: exercises);
    });

    final routine = Routine(
      name: _nameController.text.trim(),
      daysPerWeek: _selectedDays.length,
      weeklyPlan: weeklyPlan,
      createdAt: DateTime.now(),
    );

    await ref.read(routineProvider.notifier).saveManualRoutine(routine);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemCount: _totalPages,
        itemBuilder: (context, i) {
          if (i == 0) return _SetupPage(this);
          return _DayPage(parent: this, dayIndex: i - 1);
        },
      ),
    );
  }
}

// ── 1단계: 루틴 기본 설정 ──────────────────────────────────────────────────

class _SetupPage extends StatelessWidget {
  final _ManualRoutineScreenState parent;
  const _SetupPage(this.parent);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                _StepIndicator(current: 0, total: parent._totalPages),
              ],
            ),
            const SizedBox(height: 24),
            Text('루틴 이름',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: parent._nameController,
              decoration: InputDecoration(
                hintText: '예) 상체 집중 루틴',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Text('운동 요일 선택',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('${parent._selectedDays.length}일',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['월', '화', '수', '목', '금', '토', '일'].map((short) {
                final full = '${short}요일';
                final isSelected = parent._selectedDays.contains(full);
                final primary = Theme.of(context).colorScheme.primary;
                return GestureDetector(
                  onTap: () => parent._toggleDay(full),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? primary : Colors.grey.shade100,
                      border: Border.all(
                        color: isSelected ? primary : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        short,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: parent._goNext,
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('다음'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 2단계~: 요일별 운동 추가 ──────────────────────────────────────────────

class _DayPage extends StatefulWidget {
  final _ManualRoutineScreenState parent;
  final int dayIndex;
  const _DayPage({required this.parent, required this.dayIndex});

  @override
  State<_DayPage> createState() => _DayPageState();
}

class _DayPageState extends State<_DayPage> {
  String? _selectedPartId;
  bool _isSaving = false;

  bool get _isLastDay =>
      widget.dayIndex == widget.parent._selectedDays.length - 1;

  Map<String, List<int>> get _selected =>
      widget.parent._selectedByDay[widget.dayIndex];

  int get _totalSelected =>
      _selected.values.fold(0, (s, l) => s + l.length);

  void _toggleExercise(String partId, int exIdx) {
    setState(() {
      final list = _selected.putIfAbsent(partId, () => []);
      if (list.contains(exIdx)) {
        list.remove(exIdx);
        if (list.isEmpty) _selected.remove(partId);
      } else {
        list.add(exIdx);
        // 처음 선택한 부위를 focus로
        if (widget.parent._focusByDay[widget.dayIndex] == null) {
          widget.parent._focusByDay[widget.dayIndex] = partId;
        }
      }
    });
    widget.parent.setState(() {});
  }

  Future<void> _finishOrNext() async {
    final total = _totalSelected;
    if (total == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('운동을 1개 이상 추가해주세요')));
      return;
    }

    if (_isLastDay) {
      setState(() => _isSaving = true);
      await widget.parent._saveRoutine();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      widget.parent._goNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayName = widget.parent._selectedDays[widget.dayIndex];
    final part = _selectedPartId != null
        ? bodyParts.firstWhere((b) => b.id == _selectedPartId)
        : null;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (widget.dayIndex == 0) {
                      widget.parent._pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      widget.parent._pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
                const SizedBox(width: 4),
                _StepIndicator(
                    current: widget.dayIndex + 1,
                    total: widget.parent._totalPages),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Text(dayName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_totalSelected > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_totalSelected개 선택됨',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 부위 선택 chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: bodyParts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final bp = bodyParts[i];
                final isSelected = _selectedPartId == bp.id;
                final hasChosen = _selected.containsKey(bp.id) &&
                    _selected[bp.id]!.isNotEmpty;
                return FilterChip(
                  label: Text('${bp.emoji} ${bp.name}'),
                  selected: isSelected,
                  showCheckmark: false,
                  avatar: hasChosen
                      ? CircleAvatar(
                          radius: 8,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: Text(
                            '${_selected[bp.id]!.length}',
                            style: const TextStyle(
                                fontSize: 9, color: Colors.white),
                          ),
                        )
                      : null,
                  onSelected: (_) =>
                      setState(() => _selectedPartId = bp.id),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: part == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('💡',
                            style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('위에서 운동 부위를 선택하세요',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: part.exercises.length,
                    itemBuilder: (context, i) {
                      final ex = part.exercises[i];
                      final isChosen =
                          _selected[part.id]?.contains(i) ?? false;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ExerciseSelectTile(
                          exercise: ex,
                          isSelected: isChosen,
                          onTap: () =>
                              _toggleExercise(part.id, i),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _finishOrNext,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(_isLastDay
                        ? Icons.check_circle_outline
                        : Icons.arrow_forward),
                label:
                    Text(_isLastDay ? '루틴 저장' : '다음 ($dayName 완료)'),
                style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseSelectTile extends StatelessWidget {
  final ExerciseTemplate exercise;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExerciseSelectTile({
    required this.exercise,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? primary : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? primary.withValues(alpha: 0.06)
            : Theme.of(context).colorScheme.surface,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // 운동 이미지 썸네일
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: Image.network(
                    ExerciseVisual.getExerciseImageUrl(exercise.name),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: isSelected
                          ? primary.withValues(alpha: 0.2)
                          : Colors.grey.shade200,
                      child: Icon(Icons.fitness_center,
                          color: isSelected ? primary : Colors.grey.shade400,
                          size: 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 체크 아이콘
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? primary : Colors.grey.shade100,
                  border: Border.all(
                    color: isSelected ? primary : Colors.grey.shade300,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? primary : null)),
                    Text(exercise.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primary
                      : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${exercise.defaultSets}×${exercise.defaultReps}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onPrimaryContainer,
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

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i == current;
        final done = i < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 4),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: done || active
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}
