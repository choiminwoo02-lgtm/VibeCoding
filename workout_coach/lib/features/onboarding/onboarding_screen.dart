import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_goal.dart';
import '../../shared/goal_constants.dart';
import '../routine/routine_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  String? _selectedGoalId;
  int _daysPerWeek = 3;
  bool _hasEquipment = false;
  bool _isGenerating = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_selectedGoalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('목표를 선택해주세요')),
      );
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _generate() async {
    final goal = UserGoal(
      goalType: _selectedGoalId!,
      daysPerWeek: _daysPerWeek,
      hasEquipment: _hasEquipment,
    );

    setState(() => _isGenerating = true);
    await ref.read(routineProvider.notifier).generateRoutine(goal);

    if (mounted) {
      final error = ref.read(routineProvider).error;
      if (error != null) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _PageIndicator(currentPage: _page),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      _GoalPage(
                        selectedId: _selectedGoalId,
                        onSelect: (id) =>
                            setState(() => _selectedGoalId = id),
                        onNext: _nextPage,
                      ),
                      _DetailsPage(
                        daysPerWeek: _daysPerWeek,
                        hasEquipment: _hasEquipment,
                        onDaysChanged: (d) =>
                            setState(() => _daysPerWeek = d),
                        onEquipmentChanged: (v) =>
                            setState(() => _hasEquipment = v),
                        onGenerate: _generate,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isGenerating)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    'AI가 맞춤 루틴을 생성하고 있어요...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '잠시만 기다려주세요',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int currentPage;
  const _PageIndicator({required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(2, (i) {
          final active = i == currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 6),
            width: active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
            ),
          );
        }),
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;

  const _GoalPage({
    required this.selectedId,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('어떤 목표로\n운동하시나요?',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('목표에 맞는 AI 루틴을 생성해드립니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
          const SizedBox(height: 28),
          ...goalTypes.map((g) {
            final isSelected = selectedId == g.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GoalCard(
                goalType: g,
                isSelected: isSelected,
                onTap: () => onSelect(g.id),
              ),
            );
          }),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('다음'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalType goalType;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goalType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? goalType.color : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? goalType.color.withValues(alpha: 0.08)
            : Colors.white,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(goalType.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goalType.label,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? goalType.color : null)),
                  Text(goalType.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                ],
              ),
              const Spacer(),
              if (isSelected)
                Icon(Icons.check_circle, color: goalType.color),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsPage extends StatelessWidget {
  final int daysPerWeek;
  final bool hasEquipment;
  final ValueChanged<int> onDaysChanged;
  final ValueChanged<bool> onEquipmentChanged;
  final VoidCallback onGenerate;

  const _DetailsPage({
    required this.daysPerWeek,
    required this.hasEquipment,
    required this.onDaysChanged,
    required this.onEquipmentChanged,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('운동 계획을\n알려주세요',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('조건에 맞게 루틴을 최적화합니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
          const SizedBox(height: 32),
          Text('주당 운동 횟수',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final days = i + 2;
              final isSelected = daysPerWeek == days;
              return GestureDetector(
                onTap: () => onDaysChanged(days),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade100,
                  ),
                  child: Center(
                    child: Text(
                      '$days회',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          Text('운동 장비',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _EquipmentOption(
                emoji: '🏋️',
                label: '장비 있음',
                sublabel: '덤벨, 바벨, 기구',
                isSelected: hasEquipment,
                onTap: () => onEquipmentChanged(true),
              ),
              const SizedBox(width: 12),
              _EquipmentOption(
                emoji: '🤸',
                label: '맨몸 운동',
                sublabel: '장비 없음',
                isSelected: !hasEquipment,
                onTap: () => onEquipmentChanged(false),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('AI 루틴 생성'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentOption extends StatelessWidget {
  final String emoji;
  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _EquipmentOption({
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primary : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? primary.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? primary : null)),
              Text(sublabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
