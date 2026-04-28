# 개발환경 설정 가이드

## 1. Flutter 설치

### Windows

```powershell
winget install Google.Flutter
```

또는 [flutter.dev](https://docs.flutter.dev/get-started/install/windows) 에서 직접 다운로드.

설치 확인:
```bash
flutter --version   # Flutter 3.x.x 이상
flutter doctor      # 환경 점검
```

### macOS

```bash
brew install --cask flutter
```

---

## 2. Android 개발 환경

1. [Android Studio](https://developer.android.com/studio) 설치
2. SDK Manager에서 Android SDK (API 33 이상) 설치
3. `flutter doctor`로 체크

---

## 3. 에뮬레이터 또는 실제 기기

### 에뮬레이터
Android Studio → AVD Manager → 기기 생성 → 실행

### 실제 기기 (Android)
1. 설정 → 개발자 옵션 → USB 디버깅 활성화
2. USB로 PC에 연결

```bash
flutter devices   # 연결된 기기 확인
```

---

## 4. 프로젝트 설정

```bash
git clone https://github.com/choiminwoo02-lgtm/VibeCoding.git
cd VibeCoding/workout_coach
flutter pub get
```

---

## 5. Anthropic API 키 발급

1. [console.anthropic.com](https://console.anthropic.com) 접속
2. API Keys → Create Key
3. 생성된 키 복사 (한 번만 표시)

---

## 6. 앱 실행

```bash
flutter run --dart-define=CLAUDE_API_KEY=sk-ant-xxxxxx
```

API 키 없이 (AI 루틴 생성 불가):
```bash
flutter run
```

---

## 7. 유용한 개발 명령

```bash
r          # Hot reload
R          # Hot restart
flutter analyze    # 정적 분석
flutter test       # 테스트 실행
flutter pub upgrade # 패키지 업데이트
```
