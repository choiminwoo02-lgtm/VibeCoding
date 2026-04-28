import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../routine/routine_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsProvider);
    final weekAsync = ref.watch(thisWeekRecordsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('운동 기록')),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (records) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              weekAsync.when(
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const SizedBox(),
                data: (weekRecords) =>
                    _WeekSummary(weekRecords: weekRecords),
              ),
              const SizedBox(height: 20),
              if (records.isEmpty)
                _buildEmpty(context)
              else ...[
                Text(
                  '전체 기록',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...records.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RecordCard(record: r),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Text('📋', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            '아직 기록이 없어요',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '오늘 운동을 완료하고 기록을 남겨보세요!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _WeekSummary extends StatelessWidget {
  final List<dynamic> weekRecords;
  const _WeekSummary({required this.weekRecords});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

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
            '이번 주 운동',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = weekStart.add(Duration(days: i));
              final hasRecord = weekRecords.any((r) =>
                  r.date.year == day.year &&
                  r.date.month == day.month &&
                  r.date.day == day.day);
              final isToday = day.year == now.year &&
                  day.month == now.month &&
                  day.day == now.day;
              final isPast = day.isBefore(now) ||
                  (day.year == now.year &&
                      day.month == now.month &&
                      day.day == now.day);

              return Column(
                children: [
                  Text(
                    ['월', '화', '수', '목', '금', '토', '일'][i],
                    style: TextStyle(
                      color: isToday ? Colors.white : Colors.white60,
                      fontSize: 12,
                      fontWeight: isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasRecord
                          ? Colors.white
                          : isPast
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: hasRecord
                          ? Icon(
                              Icons.check,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : Text(
                              '${day.day}',
                              style: TextStyle(
                                color: isPast
                                    ? Colors.white54
                                    : Colors.white30,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            '${weekRecords.length}회 완료',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final dynamic record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final pct = (record.completionRate * 100).toInt();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: pct >= 80
                    ? const Color(0xFF2ECC71).withValues(alpha: 0.15)
                    : pct >= 50
                        ? const Color(0xFFFFB300).withValues(alpha: 0.15)
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  pct >= 80 ? '🎉' : pct >= 50 ? '💪' : '📝',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('M월 d일 (E)', 'ko_KR').format(record.date),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  Text(
                    '${record.dayName}  ·  ${record.focus}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${record.completedCount}/${record.totalExercises} 완료',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            _CompletionRing(percent: pct),
          ],
        ),
      ),
    );
  }
}

class _CompletionRing extends StatelessWidget {
  final int percent;
  const _CompletionRing({required this.percent});

  @override
  Widget build(BuildContext context) {
    final color = percent >= 80
        ? const Color(0xFF2ECC71)
        : percent >= 50
            ? const Color(0xFFFFB300)
            : Colors.grey;

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent / 100,
            strokeWidth: 4,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
          Text(
            '$percent%',
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
