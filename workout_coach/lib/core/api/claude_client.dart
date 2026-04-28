import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/routine.dart';
import '../models/user_goal.dart';

class ClaudeClient {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-20250514';
  static const _systemPrompt =
      '당신은 전문 퍼스널 트레이너입니다. '
      '사용자의 목표와 조건을 보고 다음 JSON 형식으로만 응답하세요: '
      '{"routine_name": "루틴 이름", "days_per_week": 숫자, '
      '"weekly_plan": [{"day": "요일(예: 월요일)", "focus": "운동 부위 또는 유형", '
      '"exercises": [{"name": "운동 이름", "sets": 숫자, '
      '"reps": "횟수 또는 시간", "description": "자세 설명 한 줄"}]}]}';

  Future<Routine> generateRoutine(UserGoal goal) async {
    final apiKey = ApiConfig.apiKey;
    if (apiKey.isEmpty) {
      throw Exception(
        'API 키가 설정되지 않았습니다.\n'
        'flutter run --dart-define=CLAUDE_API_KEY=키 옵션으로 실행하세요.',
      );
    }

    final userMessage = '목표: ${goal.goalType}\n'
        '주당 운동 횟수: ${goal.daysPerWeek}회\n'
        '운동 장비: ${goal.hasEquipment ? "있음 (덤벨, 바벨, 기구 사용 가능)" : "없음 (맨몸 운동만 가능)"}';

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 2048,
        'system': _systemPrompt,
        'messages': [
          {'role': 'user', 'content': userMessage},
        ],
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      final msg = (error['error'] as Map?)?['message'] ?? response.body;
      throw Exception('API 오류 (${response.statusCode}): $msg');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text = (data['content'] as List).first['text'] as String;

    try {
      final cleaned = text.replaceAll(RegExp(r'```(?:json)?\n?'), '').trim();
      return Routine.fromClaudeJson(
        jsonDecode(cleaned) as Map<String, dynamic>,
      );
    } catch (_) {
      final match = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
      if (match != null) {
        return Routine.fromClaudeJson(
          jsonDecode(match.group(0)!) as Map<String, dynamic>,
        );
      }
      throw Exception('루틴 파싱 실패');
    }
  }
}
