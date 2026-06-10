import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/exercise_visual.dart';
import '../routine/routine_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 기록'),
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (records) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                _MonthlySummary(allRecords: records),
                const SizedBox(height: 24),
                if (records.isEmpty)
                  _buildEmpty(context)
                else ...[
                  Text(
                    '전체 기록',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...records.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RecordCard(record: r),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(child: Text('📋', style: TextStyle(fontSize: 36))),
          ),
          const SizedBox(height: 16),
          Text('아직 기록이 없어요', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '오늘 운동을 완료하고 기록을 남겨보세요!',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ─── 월간 통계 ─────────────────────────────────────────────────────────────────
class _MonthlySummary extends StatefulWidget {
  final List<dynamic> allRecords;
  const _MonthlySummary({required this.allRecords});

  @override
  State<_MonthlySummary> createState() => _MonthlySummaryState();
}

class _MonthlySummaryState extends State<_MonthlySummary> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  List<dynamic> get _monthRecords => widget.allRecords.where((r) {
        final d = r.date as DateTime;
        return d.year == _month.year && d.month == _month.month;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final now = DateTime.now();
    final records = _monthRecords;

    // 달력 계산
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startOffset = firstDay.weekday - 1; // 월=0, 일=6

    final recordMap = <int, dynamic>{
      for (final r in records) (r.date as DateTime).day: r,
    };

    // 통계
    final totalWorkouts = records.length;
    final avgRate = records.isEmpty
        ? 0.0
        : records.fold<double>(0, (s, r) => s + (r.completionRate as double)) /
            records.length;
    final totalDone = records.fold<int>(
        0, (s, r) => s + (r.completedCount as int));

    // 부위별 빈도
    final partFreq = <String, int>{};
    for (final r in records) {
      for (final p in (r.focus as String).split('+')) {
        final t = p.trim();
        if (t.isNotEmpty) partFreq[t] = (partFreq[t] ?? 0) + 1;
      }
    }
    final sortedParts = partFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxFreq = sortedParts.isEmpty ? 1 : sortedParts.first.value;

    final isCurrentMonth =
        _month.year == now.year && _month.month == now.month;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 월 선택 헤더 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 8, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.calendar_month_rounded,
                      color: primary, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_month.year}년 ${_month.month}월',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => setState(() =>
                      _month = DateTime(_month.year, _month.month - 1)),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: isCurrentMonth
                      ? null
                      : () => setState(() =>
                          _month = DateTime(_month.year, _month.month + 1)),
                ),
              ],
            ),
          ),

          // ── 요일 라벨 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['월', '화', '수', '목', '금', '토', '일']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: d == '일'
                                  ? Colors.red.shade300
                                  : d == '토'
                                      ? Colors.blue.shade300
                                      : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 6),

          // ── 달력 그리드 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.1,
              ),
              itemCount: startOffset + daysInMonth,
              itemBuilder: (context, i) {
                if (i < startOffset) return const SizedBox();
                final day = i - startOffset + 1;
                final record = recordMap[day];
                final isToday = isCurrentMonth && now.day == day;
                final thisDay = DateTime(_month.year, _month.month, day);
                final isPast =
                    !thisDay.isAfter(DateTime(now.year, now.month, now.day));

                Color? partColor;
                if (record != null) {
                  final muscle =
                      ExerciseVisual.fromFocus(record.focus as String);
                  partColor = ExerciseVisual.getColor(muscle);
                }

                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: partColor != null
                        ? partColor.withValues(alpha: 0.13)
                        : isToday
                            ? primary.withValues(alpha: 0.08)
                            : null,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday
                        ? Border.all(color: primary, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: (isToday || record != null)
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: partColor ??
                              (isToday
                                  ? primary
                                  : isPast
                                      ? const Color(0xFF374151)
                                      : Colors.grey.shade400),
                        ),
                      ),
                      if (record != null)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: partColor,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── 통계 카드 ──
          const Divider(height: 1, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 숫자 통계 3개
                Row(
                  children: [
                    _StatBox(
                      icon: Icons.fitness_center_rounded,
                      label: '운동 횟수',
                      value: '$totalWorkouts회',
                      color: primary,
                    ),
                    const SizedBox(width: 10),
                    _StatBox(
                      icon: Icons.check_circle_outline_rounded,
                      label: '평균 완료율',
                      value: '${(avgRate * 100).toInt()}%',
                      color: const Color(0xFF27AE60),
                    ),
                    const SizedBox(width: 10),
                    _StatBox(
                      icon: Icons.local_fire_department_rounded,
                      label: '완료 종목',
                      value: '$totalDone개',
                      color: const Color(0xFFE67E22),
                    ),
                  ],
                ),

                // 부위별 바 차트
                if (sortedParts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    '부위별 운동 횟수',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...sortedParts.take(5).map((entry) {
                    final muscle = ExerciseVisual.fromFocus(entry.key);
                    final color = ExerciseVisual.getColor(muscle);
                    final emoji = ExerciseVisual.getEmoji(muscle);
                    final ratio = entry.value / maxFreq;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Text(emoji,
                              style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 32,
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: ratio,
                                  child: Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${entry.value}회',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                // 기록 없을 때
                if (records.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        '이 달에 운동 기록이 없어요',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade400,
                            ),
                      ),
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

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 기록 카드 ─────────────────────────────────────────────────────────────────
class _RecordCard extends StatelessWidget {
  final dynamic record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final pct = (record.completionRate * 100).toInt();
    final muscle = ExerciseVisual.fromFocus(record.focus as String);
    final color = ExerciseVisual.getColor(muscle);
    final imageUrl = ExerciseVisual.getImageUrl(muscle);
    final emoji = ExerciseVisual.getEmoji(muscle);

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
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: color.withValues(alpha: 0.3)),
                ),
                Container(color: color.withValues(alpha: 0.4)),
                Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
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
                  DateFormat('M월 d일 (E)', 'ko_KR').format(record.date as DateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${record.dayName}  ·  ${record.focus}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '${record.completedCount}/${record.totalExercises} 완료',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: record.completionRate as double,
                          minHeight: 4,
                          backgroundColor: color.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _CompletionBadge(pct: pct, color: color),
          ),
        ],
      ),
    );
  }
}

class _CompletionBadge extends StatelessWidget {
  final int pct;
  final Color color;
  const _CompletionBadge({required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: pct / 100,
            strokeWidth: 4,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '$pct%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
