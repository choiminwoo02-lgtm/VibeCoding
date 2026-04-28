import 'dart:convert';
import 'routine.dart';

class WorkoutRecord {
  final int? id;
  final int routineId;
  final DateTime date;
  final String dayName;
  final String focus;
  final List<ExerciseItem> exercises;
  final List<bool> completedList;
  final DateTime createdAt;

  const WorkoutRecord({
    this.id,
    required this.routineId,
    required this.date,
    required this.dayName,
    required this.focus,
    required this.exercises,
    required this.completedList,
    required this.createdAt,
  });

  int get totalExercises => exercises.length;
  int get completedCount => completedList.where((c) => c).length;
  double get completionRate =>
      totalExercises == 0 ? 0 : completedCount / totalExercises;

  WorkoutRecord copyWith({List<bool>? completedList}) => WorkoutRecord(
        id: id,
        routineId: routineId,
        date: date,
        dayName: dayName,
        focus: focus,
        exercises: exercises,
        completedList: completedList ?? this.completedList,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'routine_id': routineId,
        'date': date.toIso8601String(),
        'day_name': dayName,
        'focus': focus,
        'exercises_json':
            jsonEncode(exercises.map((e) => e.toJson()).toList()),
        'completed_json': jsonEncode(completedList),
        'created_at': createdAt.toIso8601String(),
      };

  factory WorkoutRecord.fromMap(Map<String, dynamic> map) {
    final exercisesList =
        jsonDecode(map['exercises_json'] as String) as List;
    final completedList =
        (jsonDecode(map['completed_json'] as String) as List)
            .map((e) => e as bool)
            .toList();
    return WorkoutRecord(
      id: map['id'] as int?,
      routineId: map['routine_id'] as int,
      date: DateTime.parse(map['date'] as String),
      dayName: map['day_name'] as String,
      focus: map['focus'] as String,
      exercises: exercisesList
          .map((e) => ExerciseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      completedList: completedList,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
