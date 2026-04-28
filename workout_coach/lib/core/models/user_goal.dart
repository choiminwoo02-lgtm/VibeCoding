class UserGoal {
  final String goalType; // 다이어트 | 근력 | 유연성
  final int daysPerWeek;
  final bool hasEquipment;

  const UserGoal({
    required this.goalType,
    required this.daysPerWeek,
    required this.hasEquipment,
  });
}
