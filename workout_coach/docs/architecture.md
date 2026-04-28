# 아키텍처 문서

## 레이어 구조

```
┌──────────────────────────────────────────────────┐
│                    UI Layer                      │
│  OnboardingScreen · TodayScreen · RoutineScreen  │
│  HistoryScreen                                   │
├──────────────────────────────────────────────────┤
│               State Layer (Riverpod)             │
│  RoutineNotifier · RecordsNotifier               │
│  todayRecordProvider · thisWeekRecordsProvider   │
├──────────────────────┬───────────────────────────┤
│     Local Data       │      Remote Data          │
│  AppDatabase         │    ClaudeClient           │
│  (SQLite/sqflite)    │    (Anthropic API)        │
├──────────────────────┴───────────────────────────┤
│                  Model Layer                     │
│  Routine · RoutineDay · ExerciseItem             │
│  WorkoutRecord · UserGoal                        │
└──────────────────────────────────────────────────┘
```

## 앱 진입 흐름

```
main() → ProviderScope → WorkoutCoachApp
  └→ AppRouter (watches routineProvider)
       ├─ null → OnboardingScreen
       └─ Routine → MainShell (3 탭)
                       ├─ TodayScreen
                       ├─ RoutineScreen
                       └─ HistoryScreen
```

## 루틴 생성 흐름

```
OnboardingScreen
  └→ RoutineNotifier.generateRoutine(UserGoal)
       └→ ClaudeClient.generateRoutine()
            └→ POST /v1/messages (Claude API)
                 └→ JSON 파싱 → Routine 객체
                      └→ AppDatabase.saveRoutine()
                           └→ SQLite INSERT
                                └→ AppRouter 재빌드 → MainShell
```

## 운동 기록 흐름

```
TodayScreen
  └→ 오늘 요일 → RoutineDay 매핑
       └→ AppDatabase.getRecordForDate() 기존 기록 로드
            └→ 체크박스 인터랙션
                 └→ RecordsNotifier.saveRecord()
                      └→ AppDatabase.insertRecord()
                           └→ recordsProvider 갱신
                                └→ todayRecordProvider, thisWeekRecordsProvider 반응
```

## 폴더 구조

```
lib/
├── main.dart                          # 진입점 (locale + ProviderScope)
├── app.dart                           # MaterialApp
├── core/
│   ├── api/claude_client.dart         # Claude API 클라이언트
│   ├── config/api_config.dart         # API 키 (dart-define)
│   ├── db/app_database.dart           # SQLite CRUD
│   ├── models/
│   │   ├── user_goal.dart             # 사용자 목표 모델
│   │   ├── routine.dart               # 루틴·운동 모델 (JSON 직렬화)
│   │   └── workout_record.dart        # 운동 기록 모델
│   └── theme/app_theme.dart           # Material 3 테마
├── features/
│   ├── onboarding/onboarding_screen.dart   # 2단계 온보딩 UI
│   ├── routine/
│   │   ├── routine_provider.dart      # 모든 Riverpod 프로바이더
│   │   └── routine_screen.dart        # 주간 루틴 뷰
│   ├── today/today_screen.dart        # 오늘의 운동 (체크박스)
│   └── history/history_screen.dart    # 기록 및 주간 통계
└── shared/
    ├── goal_constants.dart            # 목표 타입 + 요일 매핑
    ├── app_router.dart                # 루틴 유무에 따른 라우팅
    └── main_shell.dart                # BottomNavigationBar 쉘
```

## 데이터베이스 스키마

```sql
CREATE TABLE routines (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  name              TEXT NOT NULL,          -- AI가 생성한 루틴 이름
  days_per_week     INTEGER NOT NULL,       -- 주당 운동일 수
  weekly_plan_json  TEXT NOT NULL,          -- JSON: List<RoutineDay>
  created_at        TEXT NOT NULL
);

CREATE TABLE workout_records (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  routine_id       INTEGER NOT NULL,
  date             TEXT NOT NULL,           -- ISO 8601
  day_name         TEXT NOT NULL,           -- 예: "월요일"
  focus            TEXT NOT NULL,           -- 예: "가슴/삼두"
  exercises_json   TEXT NOT NULL,           -- JSON: List<ExerciseItem>
  completed_json   TEXT NOT NULL,           -- JSON: List<bool>
  created_at       TEXT NOT NULL
);
```

## 요일 매핑 로직

```
today.weekday (Dart: 1=월 ~ 7=일)
    ↕
dayNameToWeekday { '월요일': 1, ..., '일요일': 7 }
    ↕
routine.weeklyPlan.firstWhereOrNull(d => map[d.day] == weekday)
```
