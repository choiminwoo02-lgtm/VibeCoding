# AI 운동 루틴 코치 (Workout Coach)

운동 목표를 입력하면 Claude AI가 맞춤 주간 루틴을 생성하고, 완료 여부를 기록하며 진행 상황을 추적하는 모바일 앱.

## 주요 기능

| 기능 | 설명 |
|------|------|
| 온보딩 | 목표(다이어트/근력/유연성), 주 운동 횟수, 장비 유무 입력 |
| AI 루틴 생성 | Claude AI가 조건에 맞는 주간 운동 루틴 자동 생성 |
| 오늘의 운동 | 오늘 해당하는 운동 목록, 세트/횟수, 완료 체크 |
| 루틴 보기 | 주간 전체 루틴 확인 (요일별 운동 부위 + 상세 운동) |
| 운동 기록 | 날짜별 완료 기록, 이번 주 달성 현황 |
| 로컬 저장 | 모든 데이터 기기 내 SQLite 저장 |

## 기술 스택

| 항목 | 기술 |
|------|------|
| 프레임워크 | Flutter 3.x |
| AI | Claude API (`claude-sonnet-4-20250514`) |
| 로컬 DB | SQLite (sqflite) |
| 상태 관리 | Riverpod 2.x |

## 빠른 시작

### 1. 사전 준비

- Flutter 3.x 설치 → [docs/setup.md](docs/setup.md)
- Anthropic API 키 발급 → [console.anthropic.com](https://console.anthropic.com)

### 2. 저장소 클론 및 의존성 설치

```bash
git clone https://github.com/choiminwoo02-lgtm/VibeCoding.git
cd VibeCoding/workout_coach
flutter pub get
```

### 3. 앱 실행

```bash
flutter run --dart-define=CLAUDE_API_KEY=여기에_API_키_입력
```

> API 키 없이도 실행 가능하나, AI 루틴 생성 기능은 사용 불가합니다.

## 앱 흐름

```
첫 실행 → 온보딩(목표 입력) → AI 루틴 생성
                                    ↓
              오늘의 운동 ← 메인 화면 → 루틴 보기
                                    ↓
                                운동 기록
```

## 문서

- [아키텍처](docs/architecture.md)
- [개발환경 설정](docs/setup.md)
- [빌드 및 배포](docs/deploy.md)
- [AI Agent 설계](AGENTS.md)
