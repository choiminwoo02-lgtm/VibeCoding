import '../models/routine.dart';
import '../models/workout_record.dart';

class AppDatabase {
  Routine? _routine;
  final List<WorkoutRecord> _records = [];
  int _nextRecordId = 1;

  Future<Routine?> getActiveRoutine() async => _routine;

  Future<Routine> saveRoutine(Routine routine) async {
    _routine = routine.copyWith(id: 1);
    _records.clear();
    return _routine!;
  }

  Future<Routine> updateRoutine(Routine routine) async {
    _routine = routine.copyWith(id: _routine?.id ?? 1);
    return _routine!;
  }

  Future<List<WorkoutRecord>> getAllRecords() async => List.from(_records);

  Future<WorkoutRecord?> getRecordForDate(DateTime date) async {
    return _records.where((r) =>
        r.date.year == date.year &&
        r.date.month == date.month &&
        r.date.day == date.day).firstOrNull;
  }

  Future<int> insertRecord(WorkoutRecord record) async {
    _records.removeWhere((r) =>
        r.date.year == record.date.year &&
        r.date.month == record.date.month &&
        r.date.day == record.date.day);
    final newRecord = WorkoutRecord(
      id: _nextRecordId++,
      routineId: record.routineId,
      date: record.date,
      dayName: record.dayName,
      focus: record.focus,
      exercises: record.exercises,
      completedList: record.completedList,
      createdAt: record.createdAt,
    );
    _records.add(newRecord);
    return newRecord.id!;
  }

  Future<List<WorkoutRecord>> getRecordsForWeek(DateTime weekStart) async {
    final end = weekStart.add(const Duration(days: 6));
    return _records.where((r) =>
        !r.date.isBefore(weekStart) && !r.date.isAfter(end)).toList();
  }

  Future<void> clearAll() async {
    _routine = null;
    _records.clear();
  }
}
