import 'package:hackathon_net/core/config/runtime_env.dart';

class OpenAiConfig {
  const OpenAiConfig._();

  static const _apiKeyFromDefine = String.fromEnvironment('OPENAI_API_KEY');

  static String get apiKey => _apiKeyFromDefine.trim().isNotEmpty
      ? _apiKeyFromDefine
      : RuntimeEnv.value('OPENAI_API_KEY');

  static bool get isConfigured => apiKey.trim().isNotEmpty;
}
