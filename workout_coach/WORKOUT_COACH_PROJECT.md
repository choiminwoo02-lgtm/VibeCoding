# AI 운동 코치 (Workout Coach) — 프로젝트 완전 문서

## 1. 프로젝트 개요

**앱 이름**: AI 운동 코치 (Workout Coach)  
**플랫폼**: Flutter (Web/Android/iOS/Windows 크로스플랫폼)  
**주요 실행 환경**: Chrome (Web)  
**개발 목적**: 사용자 목표와 조건에 맞는 주간 운동 루틴을 추천하고, 매일 운동 기록을 관리하는 개인 피트니스 코치 앱

---

## 2. 기술 스택

| 항목 | 세부 내용 |
|------|-----------|
| 언어 | Dart (SDK ^3.10.3) |
| 프레임워크 | Flutter (Material Design 3) |
| 상태 관리 | Flutter Riverpod (`AsyncNotifierProvider`, `StateProvider`) |
| 로컬 DB | sqflite (모바일), 메모리 DB (웹) |
| 이미지 | Pexels CDN (종목별 특화 사진 42종) |
| 다크모드 | `themeModeProvider` (StateProvider) |
| 날짜/시간 | intl 패키지 (ko_KR 로케일) |

---

## 3. 전체 파일 구조

```
lib/
├── main.dart                          # 앱 진입점, ProviderScope
├── app.dart                           # WorkoutCoachApp (ConsumerWidget), 라우터
├── core/
│   ├── api/
│   │   └── claude_client.dart         # Claude API 연동 (현재 미사용)
│   ├── db/
│   │   ├── app_database.dart          # 플랫폼별 DB 익스포트
│   │   ├── app_database_real.dart     # SQLite (모바일/데스크탑)
│   │   └── app_database_web.dart      # 메모리 DB (웹)
│   ├── models/
│   │   ├── exercise_db.dart           # 운동 종목 데이터베이스 (7부위, 42종목)
│   │   ├── exercise_visual.dart       # 종목별 이미지/색상/이모지 매핑
│   │   ├── routine.dart               # Routine, RoutineDay, ExerciseItem 모델
│   │   ├── user_goal.dart             # UserGoal 모델
│   │   └── workout_record.dart        # WorkoutRecord 모델
│   └── theme/
│       └── app_theme.dart             # lightTheme / darkTheme 정의
├── features/
│   ├── onboarding/
│   │   └── onboarding_screen.dart     # 첫 실행 화면 (목표 선택 + 운동 계획 2페이지)
│   ├── today/
│   │   └── today_screen.dart          # 오늘 운동 화면 (세트별 편집 포함)
│   ├── routine/
│   │   ├── routine_provider.dart      # 루틴/기록 Riverpod 프로바이더
│   │   └── routine_screen.dart        # 루틴 조회/종목 교체 + RoutinePreviewScreen
│   ├── history/
│   │   └── history_screen.dart        # 월간 통계 + 달력 + 바 차트
│   ├── smart_routine/
│   │   └── smart_routine_screen.dart  # 스마트 루틴 추천 화면
│   └── manual_routine/
│       └── manual_routine_screen.dart # 직접 루틴 만들기 화면
└── shared/
    ├── main_shell.dart                # 하단 탭 네비게이션 (IndexedStack)
    ├── goal_constants.dart            # 목표 타입 상수
    └── theme_provider.dart            # themeModeProvider
```

---

## 4. 화면별 기능 상세

### 4-1. 온보딩 화면 (OnboardingScreen)
- **첫 실행 시에만 표시** (루틴이 없을 때)
- 2페이지 PageView 구성
  - **1페이지**: 운동 목표 선택 (근육 증가/체중 감량/체력 향상/건강 유지)
  - **2페이지**: 운동 요일 선택 (월~일 개별 선택) + 장비 유무
- 오른쪽 상단 다크모드 토글 버튼 (Positioned, Stack 위에 올림)
- 하단 버튼: **스마트 루틴 추천** / **직접 만들기** 두 가지 경로

### 4-2. 스마트 루틴 추천 화면 (SmartRoutineScreen)
- 운동 부위 선택 (7부위, 2열 그리드)
- 하루 종목 수 선택 (3~6개, 원형 버튼)
- **루틴 생성 → 직접 저장하지 않고 미리보기 화면으로 이동**

### 4-3. 루틴 미리보기 화면 (RoutinePreviewScreen) ← NEW
- 생성된 루틴을 저장 전에 확인/편집
- 각 종목의 ↔ 버튼 → 종목 교체 가능
- 로컬 상태(`_routine`)로 관리 — DB 저장 전 자유롭게 수정
- "이 루틴으로 시작하기" 버튼 → DB 저장 후 첫 화면으로

### 4-4. 오늘 운동 화면 (TodayScreen / _WorkoutScreen)
- 오늘 요일에 해당하는 루틴 표시 (없으면 휴식일 화면)
- 상단 히어로 카드: 운동 사진 배경 + 진행률 원형 그래프 + 선형 바
- **각 운동 타일 탭 → 세트 상세 패널 펼치기/접기** ← NEW
  - **세트 수 조절**: - / + 버튼으로 세트 추가/삭제
  - **세트별 횟수 조절**: 각 세트마다 독립적으로 - / + 버튼
  - **세트 완료 체크박스**: 완료 시 +/- 버튼 비활성화, 취소선 표시
  - **전체 완료** 버튼: 한 번에 모든 세트 완료 처리
- 헤더 배지: `N세트×M회` (현재 설정값 실시간 반영)
- 운동 기록 저장 시 수정된 세트 수/평균 횟수 반영

### 4-5. 루틴 탭 (RoutineScreen)
- 저장된 루틴 목록 (요일별 카드, ExpansionTile)
- 각 종목에 ↔ 버튼 → 종목 교체 시트 (아래에서 올라오는 바텀시트)
  - 부위별 가로 스크롤 칩으로 필터
  - 종목별 운동 사진 + 기본 세트/횟수 표시
  - 현재 종목은 "현재" 뱃지로 표시
- AppBar: 다크모드 토글 + 루틴 초기화 버튼

### 4-6. 기록 탭 (HistoryScreen)
- **월간 통계** (_MonthlySummary):
  - `< 월 >` 네비게이션 (미래 월 비활성화)
  - 7열 달력 그리드 — 운동한 날 점 표시, 오늘 강조
  - 운동한 날 배경 색상 = 해당 부위 색상
  - 통계 박스 3개: 운동 횟수 / 평균 완료율 / 완료 종목 수
  - 신체 부위별 바 차트 (상위 5부위, 비율 기반)

### 4-7. 직접 루틴 만들기 (ManualRoutineScreen)
- 요일별 운동 종목 직접 선택
- 각 종목의 세트/횟수 편집

---

## 5. 데이터 모델

### ExerciseItem
```dart
class ExerciseItem {
  final String name;        // 종목명 (예: "벤치프레스")
  final int sets;           // 세트 수 (예: 4)
  final String reps;        // 횟수 문자열 (예: "8-10회")
  final String description; // 수행 방법 설명
}
```

### RoutineDay
```dart
class RoutineDay {
  final String day;                  // 요일 (예: "월요일")
  final String focus;                // 운동 부위 (예: "가슴", "등+하체")
  final List<ExerciseItem> exercises;
}
```

### Routine
```dart
class Routine {
  final int? id;
  final String name;
  final int daysPerWeek;
  final List<RoutineDay> weeklyPlan;
  final DateTime createdAt;
  
  Routine copyWithSwap(int dayIdx, int exIdx, ExerciseItem newEx); // 종목 교체
}
```

### WorkoutRecord
```dart
class WorkoutRecord {
  final int? id;
  final int routineId;
  final DateTime date;
  final String dayName;
  final String focus;
  final List<ExerciseItem> exercises;  // 저장 시점의 세트/횟수 포함
  final List<bool> completedList;      // 운동별 완료 여부
  final DateTime createdAt;
}
```

### _SetData (오늘 화면 로컬 상태)
```dart
class _SetData {
  int reps;   // 현재 세트의 목표 횟수
  bool done;  // 해당 세트 완료 여부
}
```

---

## 6. 상태 관리 (Riverpod)

```dart
// 테마
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

// 루틴 (AsyncNotifierProvider)
final routineProvider = AsyncNotifierProvider<RoutineNotifier, Routine?>(RoutineNotifier.new);

class RoutineNotifier extends AsyncNotifier<Routine?> {
  Future<void> saveManualRoutine(Routine routine); // 루틴 저장 (기록 초기화)
  Future<void> updateRoutine(Routine routine);     // 루틴 수정 (기록 유지) ← NEW
  Future<void> swapExercise(int dayIndex, int exerciseIndex, ExerciseItem newEx); // 종목 교체
  Future<void> resetRoutine();                     // 루틴 초기화
}

// 운동 기록
final recordsProvider = AsyncNotifierProvider<RecordsNotifier, List<WorkoutRecord>>(RecordsNotifier.new);
final todayRecordProvider = Provider<WorkoutRecord?>(...);       // 오늘 기록
final thisWeekRecordsProvider = FutureProvider<List<WorkoutRecord>>(...); // 이번 주 기록

// DB 프로바이더
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());
```

---

## 7. 운동 데이터베이스

총 7개 부위, 42개 종목:

| 부위 | ID | 이모지 | 종목 수 | 종목 예시 |
|------|----|--------|---------|-----------|
| 가슴 | chest | 🫀 | 6 | 벤치프레스, 푸쉬업, 인클라인 벤치프레스, 덤벨 플라이, 딥스, 케이블 크로스오버 |
| 등 | back | 🧗 | 6 | 풀업, 바벨 로우, 랫 풀다운, 시티드 케이블 로우, 데드리프트, 원암 덤벨 로우 |
| 하체 | legs | 🦵 | 7 | 스쿼트, 레그프레스, 런지, 레그 컬, 레그 익스텐션, 카프레이즈, 힙 쓰러스트 |
| 어깨 | shoulders | 🏋️ | 5 | 숄더프레스, 사이드 레터럴레이즈, 프론트 레이즈, 페이스풀, 리어 델트 플라이 |
| 팔 | arms | 💪 | 6 | 바벨 컬, 해머 컬, 트라이셉스 딥, 케이블 푸쉬다운, 스컬크러셔, 컨센트레이션 컬 |
| 복근 | core | 🔥 | 6 | 플랭크, 크런치, 레그레이즈, 러시안 트위스트, 바이시클 크런치, 마운틴클라이머 |
| 유산소 | cardio | 🏃 | 6 | 러닝, 줄넘기, 버피, 자전거, 케틀벨 스윙, 점프 스쿼트 |

---

## 8. 종목 이미지 시스템 (ExerciseVisual)

Pexels CDN 기반 종목별 특화 사진:

```
URL 형식: https://images.pexels.com/photos/{id}/pexels-photo-{id}.jpeg
         ?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop
```

**종목별 Pexels ID (42종)**:
```dart
벤치프레스: 4853666,  푸쉬업: 176782,        인클라인 벤치프레스: 6922168
덤벨 플라이: 3839310, 딥스: 4803875,         케이블 크로스오버: 10754972
풀업: 9644816,        바벨 로우: 3025027,     랫 풀다운: 18060085
시티드 케이블 로우: 6539827, 데드리프트: 4853280, 원암 덤벨 로우: 10021279
스쿼트: 4662331,      레그프레스: 6844939,    런지: 8770407
레그 컬: 4384679,     레그 익스텐션: 3076512, 카프레이즈: 13965339
힙 쓰러스트: 6516221, 숄더프레스: 7289370,   사이드 레터럴레이즈: 6339688
프론트 레이즈: 29793977, 페이스풀: 6285184,  리어 델트 플라이: 3839506
바벨 컬: 14085138,    해머 컬: 9073246,       트라이셉스 딥: 4803913
케이블 푸쉬다운: 5327467, 스컬크러셔: 4803892, 컨센트레이션 컬: 14524650
플랭크: 4945275,      크런치: 6516225,        레그레이즈: 4971061
러시안 트위스트: 8038625, 바이시클 크런치: 7721988, 마운틴클라이머: 8038636
러닝: 2827400,        줄넘기: 4945535,        버피: 30246184
자전거: 19254708,     케틀벨 스윙: 13106615,  점프 스쿼트: 4662333
```

**부위별 색상**:
- 가슴: `#FF6B6B` (빨강), 등: `#4ECDC4` (청록), 하체: `#45B7D1` (파랑)
- 어깨: `#96CEB4` (초록), 팔: `#FFEAA7` (노랑), 복근: `#DDA0DD` (보라)
- 유산소: `#98D8C8` (민트)

---

## 9. 내비게이션 흐름

```
앱 시작
  └─ 루틴 없음 → OnboardingScreen
  │     ├─ [스마트 루틴 추천] → SmartRoutineScreen
  │     │     └─ 루틴 생성 → RoutinePreviewScreen
  │     │           ├─ ↔ 종목 교체 (저장 전)
  │     │           └─ [이 루틴으로 시작하기] → MainShell
  │     └─ [직접 만들기] → ManualRoutineScreen → MainShell
  │
  └─ 루틴 있음 → MainShell (하단 탭 3개)
        ├─ 탭 0: TodayScreen (오늘 운동)
        ├─ 탭 1: RoutineScreen (내 루틴)
        └─ 탭 2: HistoryScreen (기록)
```

---

## 10. 주요 사용자 플로우

### 플로우 1: 스마트 루틴 생성 + 수정
1. 온보딩 → 목표 선택 → 운동 요일/장비 설정
2. "스마트 루틴 추천" 클릭
3. 운동 부위 선택 (복수) + 하루 종목 수 선택
4. **루틴 미리보기** 화면에서 마음에 안 드는 종목 교체
5. "이 루틴으로 시작하기" → 저장 완료

### 플로우 2: 오늘 운동
1. TodayScreen → 오늘 날짜에 해당 루틴 표시
2. 운동 카드 탭 → 세트 상세 펼침
3. 세트 수 조절 (+ / -), 각 세트 횟수 개별 조절
4. 세트 완료 체크 → 체크된 세트는 편집 잠김
5. "운동 기록 저장" → 수정된 세트/횟수 포함 기록 저장

### 플로우 3: 루틴 종목 교체
1. 루틴 탭 → 요일 카드 펼침
2. 종목 우측 ↔ 버튼 탭
3. 바텀시트 → 부위 칩 선택 → 원하는 종목 선택
4. 즉시 교체 + DB 저장 (기록 유지)

### 플로우 4: 월간 통계 확인
1. 기록 탭 → 이번 달 달력 표시
2. 운동한 날 점·색상 확인 (부위별 색상)
3. 운동 횟수 / 평균 완료율 / 완료 종목 카드 확인
4. 신체 부위별 바 차트로 편중 파악
5. `<` `>` 버튼으로 이전 달 조회

---

## 11. UI/UX 특징

### 다크모드
- `themeModeProvider` (StateProvider) 전역 관리
- **온보딩 화면부터** 토글 가능 (오른쪽 상단 아이콘)
- 루틴 탭 AppBar에도 토글 버튼
- `lightTheme` / `darkTheme` 모두 Material 3 기반
  - Light: `scaffoldBackground #F5F7FA`, card `Colors.white`
  - Dark: `scaffoldBackground #0F172A`, card `#1E293B`

### 색상 시스템
- Primary: `#3A86FF` (블루)
- 부위별 색상으로 카드/뱃지/그래프 구분
- 완료된 운동: 부위 색상 10% 투명도 배경 + 테두리

### 애니메이션
- 운동 카드 펼치기/접기: 자연스러운 Column 확장
- 완료 토글: `AnimatedContainer` 300ms
- 세트 체크박스: `AnimatedContainer` 200ms
- 부위 칩 선택: `AnimatedContainer` 150ms

### 반응형
- `ConstrainedBox(maxWidth: 680)` + Center로 태블릿/데스크탑 대응
- 웹 Chrome에서 최적화 레이아웃

---

## 12. 데이터베이스 스키마

### 웹 (인메모리)
```dart
class AppDatabase {
  Routine? _routine;
  List<WorkoutRecord> _records;
  
  Future<Routine> saveRoutine(Routine);   // 루틴 저장 + 기록 초기화
  Future<Routine> updateRoutine(Routine); // 루틴 수정 (기록 유지)
  Future<int> insertRecord(WorkoutRecord);
  Future<void> clearAll();
}
```

### 모바일/데스크탑 (SQLite)
```sql
CREATE TABLE routines (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  days_per_week INTEGER NOT NULL,
  weekly_plan_json TEXT NOT NULL,  -- JSON 직렬화된 List<RoutineDay>
  created_at TEXT NOT NULL
);

CREATE TABLE workout_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  routine_id INTEGER NOT NULL,
  date TEXT NOT NULL,
  day_name TEXT NOT NULL,
  focus TEXT NOT NULL,
  exercises_json TEXT NOT NULL,    -- JSON 직렬화 (세트/횟수 포함)
  completed_json TEXT NOT NULL,    -- JSON [true, false, ...]
  created_at TEXT NOT NULL
);
```

---

## 13. 스마트 루틴 생성 알고리즘

```dart
// 입력: 선택된 부위 IDs, 선택된 요일 목록, 하루 종목 수
// 출력: Routine (weeklyPlan: List<RoutineDay>)

1. 부위 목록 셔플 (Random)
2. 부위 수 vs 일수 비교:
   - 부위 ≤ 일수: 하루에 부위 1개 (순환 배분)
   - 부위 > 일수: 여러 부위를 하루에 묶음
3. 각 요일별 부위에서 종목 랜덤 선택 (exercisesPerDay / 부위수 개씩)
4. RoutineDay 생성 (focus = 부위명 join('+'))
```

---

## 14. 알려진 제약 사항

- **웹**: `sqflite_common_ffi` 대신 인메모리 DB 사용 → 새로고침 시 데이터 초기화
- **한글 경로**: Windows에서 `민우` 포함 경로 시 MSBuild 인코딩 오류 → Chrome 타겟으로 회피
- **폰트 경고**: Noto 폰트 미설치 시 일부 문자 렌더링 경고 (기능 영향 없음)
- **이미지**: Pexels CDN 네트워크 필요, 오프라인 시 색상 폴백

---

## 15. 실행 방법

```bash
# Chrome으로 실행
flutter run -d chrome

# 의존성 설치
flutter pub get

# 분석
flutter analyze
```

### pubspec.yaml 주요 의존성
```yaml
dependencies:
  flutter_riverpod: ^2.x
  sqflite: ^2.x
  sqflite_common_ffi: ^2.x
  intl: ^0.19.x
  path: ^1.x
```

---

## 16. 개발 히스토리 요약

| 단계 | 주요 작업 |
|------|-----------|
| 초기 구현 | 기본 루틴 생성/조회/기록 저장 |
| UI 개선 | Material 3 테마, 카드 UI, 그라디언트, 사진 배경 |
| 종목 사진 | Pexels 종목별 특화 사진 42종 매핑 |
| 다크모드 | lightTheme/darkTheme + themeModeProvider |
| 월간 통계 | 달력 + 3개 통계 박스 + 부위별 바차트 |
| 종목 교체 | 루틴 탭에서 ↔ 버튼으로 종목 변경 + 사진 포함 시트 |
| 미리보기 | 루틴 저장 전 RoutinePreviewScreen에서 편집 |
| 세트 편집 | 오늘 운동에서 세트 수/횟수 실시간 편집 + 체크 |
