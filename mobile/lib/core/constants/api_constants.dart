class ApiConstants {
  ApiConstants._();

  // Change this to your Railway/Render URL in production
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static String wsUrl(String taskId) {
    final wsBase = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return '$wsBase/jobs/apply/ws/$taskId';
  }
}
