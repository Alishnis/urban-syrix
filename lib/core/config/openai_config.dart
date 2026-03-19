class OpenAiConfig {
  const OpenAiConfig._();

  static const apiKey = String.fromEnvironment('OPENAI_API_KEY');

  static bool get isConfigured => apiKey.trim().isNotEmpty;
}
