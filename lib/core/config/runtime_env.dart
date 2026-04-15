import 'package:flutter_dotenv/flutter_dotenv.dart';

class RuntimeEnv {
  const RuntimeEnv._();

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Keep startup resilient when no .env exists.
    }
  }

  static String value(String key, {String fallback = ''}) {
    final fromDotEnv = dotenv.isInitialized ? (dotenv.env[key] ?? '') : '';
    if (fromDotEnv.trim().isNotEmpty) {
      return fromDotEnv;
    }
    return fallback;
  }
}
