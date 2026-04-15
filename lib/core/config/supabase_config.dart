import 'package:hackathon_net/core/config/runtime_env.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static const _urlFromDefine = String.fromEnvironment('SUPABASE_URL');
  static const _anonKeyFromDefine = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url => _urlFromDefine.trim().isNotEmpty
      ? _urlFromDefine
      : RuntimeEnv.value('SUPABASE_URL');

  static String get anonKey => _anonKeyFromDefine.trim().isNotEmpty
      ? _anonKeyFromDefine
      : RuntimeEnv.value('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      url.trim().isNotEmpty && anonKey.trim().isNotEmpty;
}
