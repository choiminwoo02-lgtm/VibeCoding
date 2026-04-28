import 'package:flutter/material.dart';

class GoalType {
  final String id;
  final String label;
  final String emoji;
  final String description;
  final Color color;

  const GoalType({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
    required this.color,
  });
}

const List<GoalType> goalTypes = [
  GoalType(
    id: '다이어트',
    label: '다이어트',
    emoji: '🔥',
    description: '체중 감량 및 체지방 감소',
    color: Color(0xFFFF6B6B),
  ),
  GoalType(
    id: '근력',
    label: '근력 향상',
    emoji: '💪',
    description: '근육량 증가 및 근력 강화',
    color: Color(0xFF3A86FF),
  ),
  GoalType(
    id: '유연성',
    label: '유연성',
    emoji: '🧘',
    description: '유연성 향상 및 스트레칭',
    color: Color(0xFF7B6CF6),
  ),
];

const Map<String, int> dayNameToWeekday = {
  '월요일': 1,
  '화요일': 2,
  '수요일': 3,
  '목요일': 4,
  '금요일': 5,
  '토요일': 6,
  '일요일': 7,
};

GoalType goalTypeById(String id) => goalTypes.firstWhere(
      (g) => g.id == id,
      orElse: () => goalTypes[1],
    );
