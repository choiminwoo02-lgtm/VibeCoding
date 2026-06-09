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
    final weekAsync = ref.watch(thisWeekRecordsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        title: const Text('운동 기록', style: TextStyle(fontWeight: FontWeight.bold)),
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
                weekAsync.when(
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox(),
                  data: (weekRecords) => _WeekSummary(weekRecords: weekRecords),
                ),
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
      padding: const EdgeInsets.symmetric(vertical: 60),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ─── 주간 요약 ─────────────────────────────────────────────────────────────────
class _WeekSummary extends StatelessWidget {
  final List<dynamic> weekRecords;
  const _WeekSummary({required this.weekRecords});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF3A86FF)],
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
              const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Text(
                '이번 주 운동',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${weekRecords.length}회 완료',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final day = weekStart.add(Duration(days: i));
              final hasRecord = weekRecords.any(
                (r) => r.date.year == day.year &&
                    r.date.month == day.month &&
                    r.date.day == day.day,
              );
              final isToday = day.year == now.year &&
                  day.month == now.month &&
                  day.day == now.day;
              final isPast = !day.isAfter(now);

              return Column(
                children: [
                  Text(
                    ['월', '화', '수', '목', '금', '토', '일'][i],
                    style: TextStyle(
                      color: isToday ? Colors.white : Colors.white60,
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasRecord
                          ? Colors.white
                          : isToday
                              ? Colors.white.withValues(alpha: 0.3)
                              : isPast
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.08),
                      border: isToday
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: hasRecord
                          ? Icon(Icons.check, size: 18, color: const Color(0xFF3A86FF))
                          : Text(
                              '${day.day}',
                              style: TextStyle(
                                color: isPast ? Colors.white54 : Colors.white30,
                                fontSize: 12,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
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
      child: Row(
        children: [
          // 왼쪽 이미지
          SizedBox(
            width: 72,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: color.withValues(alpha: 0.3)),
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
