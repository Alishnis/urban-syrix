import 'package:flutter/material.dart';
import 'package:hackathon_net/app.dart';
import 'package:hackathon_net/core/config/runtime_env.dart';
import 'package:hackathon_net/core/localization/language_controller.dart';
import 'package:hackathon_net/core/config/supabase_config.dart';
import 'package:hackathon_net/features/auth/data/auth_repository.dart';
import 'package:hackathon_net/features/auth/presentation/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RuntimeEnv.load();

  late final AuthRepository authRepository;
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    authRepository = SupabaseAuthRepository(Supabase.instance.client);
  } else {
    authRepository = UnconfiguredAuthRepository();
  }

  final authController = AuthController(authRepository);
  final languageController = LanguageController();

  runApp(
    UrbanScoreApp(
      authController: authController,
      languageController: languageController,
    ),
  );
}
