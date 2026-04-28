# 빌드 및 배포 가이드

## Android APK 빌드

### Debug APK (테스트용)

```bash
flutter build apk --debug \
  --dart-define=CLAUDE_API_KEY=여기에_API_키
```

결과: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK

```bash
# 1. 서명 키스토어 생성 (최초 1회)
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. android/key.properties 작성
cat > android/key.properties << EOF
storePassword=<비밀번호>
keyPassword=<비밀번호>
keyAlias=upload
storeFile=<키스토어 경로>
EOF

# 3. 빌드
flutter build apk --release \
  --dart-define=CLAUDE_API_KEY=여기에_API_키
```

결과: `build/app/outputs/flutter-apk/app-release.apk`

---

## App Bundle (Google Play)

```bash
flutter build appbundle --release \
  --dart-define=CLAUDE_API_KEY=여기에_API_키
```

---

## iOS 빌드 (macOS 필요)

```bash
flutter build ios --release \
  --dart-define=CLAUDE_API_KEY=여기에_API_키
```

> Apple Developer 계정 및 Xcode 코드 서명 설정 필요

---

## 발표용 빠른 실행

```bash
# 연결된 기기 확인
flutter devices

# 실행
flutter run -d <device_id> \
  --dart-define=CLAUDE_API_KEY=여기에_API_키
```

---

## API 키 주의사항

- `--dart-define` 값은 Release 빌드 바이너리에 포함됩니다
- 공개 배포 시 서버사이드 프록시를 통한 API 호출 권장
- 발표/데모 목적의 앱은 `--dart-define` 방식으로 충분합니다
