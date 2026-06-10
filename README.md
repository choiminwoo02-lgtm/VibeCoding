# 🏋️ AI 운동 코치 (Workout Coach)

> 목표와 조건에 맞는 주간 운동 루틴을 추천하고, 세트 단위로 운동을 기록·관리하는 Flutter 기반 피트니스 앱

![Flutter](https://img.shields.io/badge/Flutter-3.10.3-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Web%20%7C%20Android%20%7C%20iOS-green)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## ✨ 주요 기능

| 기능 | 설명 |
|------|------|
| 🎯 스마트 루틴 추천 | 목표(근육/감량/체력/건강) + 요일 + 장비 조건으로 맞춤 주간 루틴 자동 생성 |
| 🔄 종목 교체 | 루틴 저장 전 미리보기에서, 또는 저장 후 루틴 탭에서 원하는 종목으로 교체 |
| 📝 세트별 편집 | 오늘 운동 화면에서 세트 수·횟수를 개별 조절하고 세트 단위로 완료 체크 |
| 📅 월간 통계 | 달력·완료율·신체 부위별 바 차트로 운동 현황 시각화 |
| 🌙 다크모드 | 첫 화면(온보딩)부터 전체 앱 다크모드 전환 지원 |

---

## 🚀 빠른 시작 (Quick Start)

### 요구 사항

- Flutter SDK **3.10.3** 이상
- Dart SDK **3.0** 이상
- Chrome (웹 실행 권장) 또는 Android/iOS 에뮬레이터

### 설치 및 실행

```bash
# 1. 저장소 클론
git clone https://github.com/choiminwoo02-lgtm/VibeCoding.git
cd VibeCoding/workout_coach

# 2. 의존성 설치
flutter pub get

# 3. Chrome으로 실행 (권장)
flutter run -d chrome

# 4. 연결된 모든 디바이스 확인
flutter devices

# 5. Android 실행
flutter run -d android

# 6. iOS 실행 (macOS 필요)
flutter run -d ios
```

### 빌드

```bash
# Web 빌드 (정적 파일 생성)
flutter build web --release
# 결과물: build/web/

# Android APK
flutter build apk --release
# 결과물: build/app/outputs/flutter-apk/app-release.apk

# Android App Bundle (Play Store)
flutter build appbundle --release
```

---

## 🏗 프로젝트 구조

```
workout_coach/
├── lib/
│   ├── main.dart                    # 앱 진입점
│   ├── app.dart                     # 라우터 (루틴 유무 분기)
│   ├── core/
│   │   ├── db/                      # 데이터베이스 (SQLite / 인메모리)
│   │   │   ├── app_database.dart    # 플랫폼별 조건부 export
│   │   │   ├── app_database_real.dart   # SQLite (모바일/데스크탑)
│   │   │   └── app_database_web.dart    # 인메모리 (웹)
│   │   ├── models/
│   │   │   ├── exercise_db.dart     # 7부위 42종목 운동 데이터
│   │   │   ├── exercise_visual.dart # 종목별 이미지·색상·이모지 매핑
│   │   │   ├── routine.dart         # Routine / RoutineDay / ExerciseItem
│   │   │   └── workout_record.dart  # WorkoutRecord
│   │   └── theme/
│   │       └── app_theme.dart       # lightTheme / darkTheme
│   ├── features/
│   │   ├── onboarding/              # 첫 실행 온보딩 (목표 + 일정)
│   │   ├── today/                   # 오늘 운동 + 세트 편집
│   │   ├── routine/                 # 루틴 조회 + 종목 교체 + 미리보기
│   │   ├── history/                 # 월간 통계 달력
│   │   ├── smart_routine/           # 스마트 루틴 추천
│   │   └── manual_routine/          # 직접 루틴 만들기
│   └── shared/
│       ├── main_shell.dart          # 하단 탭 (IndexedStack)
│       ├── goal_constants.dart      # 목표 타입 상수
│       └── theme_provider.dart      # themeModeProvider
├── pubspec.yaml
└── README.md
```

---

## 🛠 기술 스택

| 기술 | 버전 | 용도 |
|------|------|------|
| Flutter | ^3.10.3 | 크로스플랫폼 UI 프레임워크 |
| Dart | ^3.0 | 프로그래밍 언어 |
| flutter_riverpod | ^2.x | 전역 상태 관리 |
| sqflite | ^2.x | 모바일 SQLite |
| sqflite_common_ffi | ^2.x | 데스크탑 SQLite |
| intl | ^0.19 | 날짜·다국어 포맷 |
| Material Design 3 | — | UI 디자인 시스템 |
| Pexels CDN | — | 종목별 사진 42종 |

---

## 🏛 아키텍처

```
┌─────────────────────────────────────┐
│           UI Layer                  │
│  ConsumerWidget / StatefulWidget    │
│  (features/ 하위 각 화면)            │
└────────────────┬────────────────────┘
                 │ ref.watch / ref.read
┌────────────────▼────────────────────┐
│        State Management Layer       │
│  routineProvider (AsyncNotifier)    │
│  recordsProvider (AsyncNotifier)    │
│  themeModeProvider (StateProvider)  │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│           Data Layer                │
│  AppDatabase (플랫폼 자동 분기)       │
│  ├─ app_database_real.dart (SQLite) │
│  └─ app_database_web.dart (Memory)  │
└─────────────────────────────────────┘
```

**핵심 설계 원칙**:
- 플랫폼 DB 분기: `if (dart.library.io)` 조건부 import
- 상태 불변성: `copyWithSwap()` 패턴으로 루틴 수정
- 콜백 기반 재사용: `_DayCard`를 루틴 화면·미리보기 양쪽에서 재사용

---

## 📱 화면 구성

| 화면 | 경로 | 설명 |
|------|------|------|
| 온보딩 | 첫 실행 | 목표 선택 + 요일/장비 설정 |
| 스마트 루틴 추천 | 온보딩 → | 부위 선택 + 종목 수 설정 |
| 루틴 미리보기 | 추천 후 | 저장 전 종목 교체 가능 |
| 오늘 운동 | 탭 0 | 세트 수·횟수 편집 + 완료 체크 |
| 내 루틴 | 탭 1 | 루틴 조회 + 실시간 종목 교체 |
| 기록 | 탭 2 | 월간 달력 + 통계 + 바 차트 |

---

## 🗄 데이터베이스

### 테이블 구조 (SQLite)

```sql
-- 루틴 테이블
CREATE TABLE routines (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  name          TEXT    NOT NULL,
  days_per_week INTEGER NOT NULL,
  weekly_plan_json TEXT NOT NULL,  -- JSON 직렬화
  created_at    TEXT    NOT NULL
);

-- 운동 기록 테이블
CREATE TABLE workout_records (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  routine_id   INTEGER NOT NULL,
  date         TEXT    NOT NULL,
  day_name     TEXT    NOT NULL,
  focus        TEXT    NOT NULL,
  exercises_json TEXT  NOT NULL,  -- 세트/횟수 포함
  completed_json TEXT  NOT NULL,  -- [true, false, ...]
  created_at   TEXT    NOT NULL
);
```

> **웹 환경 참고**: 웹에서는 `sqflite` 미지원으로 인메모리 DB를 사용합니다.
> 새로고침 시 데이터가 초기화됩니다. 영구 저장이 필요하면 IndexedDB 또는 Firebase 연동이 필요합니다.

---

## 🔧 개발 환경 설정

### Flutter 설치

```bash
# Windows
# https://docs.flutter.dev/get-started/install/windows

# macOS
brew install --cask flutter

# 설치 확인
flutter doctor
```

### VS Code 확장

- Flutter (Dart Code)
- Dart (Dart Code)

### 환경 변수 확인

```bash
flutter doctor -v
# Android toolchain, Chrome, VS Code 모두 ✓ 확인
```

---

## 🧪 테스트

```bash
# 정적 분석
flutter analyze

# 단위 테스트 실행
flutter test

# 통합 테스트 (디바이스 필요)
flutter test integration_test/
```

### 주요 테스트 시나리오

- ✅ 루틴 생성 → 미리보기 → 저장 플로우
- ✅ 세트 완료 → 기록 저장 → 통계 반영
- ✅ 종목 교체 → DB 저장 + 기록 유지 확인
- ✅ 다크모드 전환 → 전체 화면 테마 적용

---

## 📋 운동 데이터

7개 부위, 42개 종목 내장:

| 부위 | 종목 수 | 예시 종목 |
|------|---------|----------|
| 가슴 | 6 | 벤치프레스, 푸쉬업, 덤벨 플라이 |
| 등 | 6 | 풀업, 바벨 로우, 데드리프트 |
| 하체 | 7 | 스쿼트, 레그프레스, 힙 쓰러스트 |
| 어깨 | 5 | 숄더프레스, 사이드 레터럴레이즈 |
| 팔 | 6 | 바벨 컬, 트라이셉스 딥 |
| 복근 | 6 | 플랭크, 크런치, 레그레이즈 |
| 유산소 | 6 | 러닝, 줄넘기, 버피 |

---

## 🗺 향후 계획

- [ ] 웹 영구 저장 (IndexedDB / Firebase Firestore)
- [ ] 운동 기록 기반 적응형 루틴 추천
- [ ] 사용자 간 루틴 공유
- [ ] 체중·체지방 트래킹
- [ ] 운동 영상 링크 연동
- [ ] CI/CD (GitHub Actions)

---

## 👨‍💻 개발자

**Minwoo Choi** — choiminwoo02@gmail.com  
VibeCoding 프로젝트

---

## 📄 라이선스

MIT License
