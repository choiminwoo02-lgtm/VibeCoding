class ApiConfig {
  // flutter run --dart-define=CLAUDE_API_KEY=your_key_here
  static const apiKey = String.fromEnvironment(
    'CLAUDE_API_KEY',
    defaultValue: '',
  );
}
