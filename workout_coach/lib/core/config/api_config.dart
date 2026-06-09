class ApiConfig {
  // flutter run --dart-define=GEMINI_API_KEY=your_key_here
  static const apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
}
