import 'dart:convert';

class ExerciseItem {
  final String name;
  final int sets;
  final String reps;
  final String description;

  const ExerciseItem({
    required this.name,
    required this.sets,
    required this.reps,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'description': description,
      };

  factory ExerciseItem.fromJson(Map<String, dynamic> json) => ExerciseItem(
        name: json['name'] as String,
        sets: (json['sets'] as num).toInt(),
        reps: json['reps']?.toString() ?? '',
        description: json['description'] as String? ?? '',
      );
}

class RoutineDay {
  final String day;
  final String focus;
  final List<ExerciseItem> exercises;

  const RoutineDay({
    required this.day,
    required this.focus,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
        'day': day,
        'focus': focus,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory RoutineDay.fromJson(Map<String, dynamic> json) => RoutineDay(
        day: json['day'] as String,
        focus: json['focus'] as String? ?? '',
        exercises: (json['exercises'] as List)
            .map((e) => ExerciseItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Routine {
  final int? id;
  final String name;
  final int daysPerWeek;
  final List<RoutineDay> weeklyPlan;
  final DateTime createdAt;

  const Routine({
    this.id,
    required this.name,
    required this.daysPerWeek,
    required this.weeklyPlan,
    required this.createdAt,
  });

  Routine copyWith({int? id}) => Routine(
        id: id ?? this.id,
        name: name,
        daysPerWeek: daysPerWeek,
        weeklyPlan: weeklyPlan,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'days_per_week': daysPerWeek,
        'weekly_plan_json':
            jsonEncode(weeklyPlan.map((d) => d.toJson()).toList()),
        'created_at': createdAt.toIso8601String(),
      };

  factory Routine.fromMap(Map<String, dynamic> map) {
    final planList = jsonDecode(map['weekly_plan_json'] as String) as List;
    return Routine(
      id: map['id'] as int?,
      name: map['name'] as String,
      daysPerWeek: map['days_per_week'] as int,
      weeklyPlan: planList
          .map((d) => RoutineDay.fromJson(d as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory Routine.fromClaudeJson(Map<String, dynamic> json) {
    final planList = json['weekly_plan'] as List;
    return Routine(
      name: (json['routine_name'] ?? json['name'] ?? '맞춤 루틴') as String,
      daysPerWeek:
          (json['days_per_week'] as num?)?.toInt() ?? planList.length,
      weeklyPlan: planList
          .map((d) => RoutineDay.fromJson(d as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.now(),
    );
  }
}
