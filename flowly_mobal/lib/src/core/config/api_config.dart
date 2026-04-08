import 'package:flutter/foundation.dart';

class ApiConfig {
  // Override with --dart-define=FLOWLY_API_URL=...
  static const String baseUrl = String.fromEnvironment(
    'FLOWLY_API_URL',
    defaultValue: kIsWeb ? 'http://localhost:5000' : 'http://10.0.2.2:5000',
  );
}
