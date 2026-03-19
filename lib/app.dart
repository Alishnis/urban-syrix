import 'package:flutter/material.dart';
import 'package:hackathon_net/core/localization/language_controller.dart';
import 'package:hackathon_net/core/localization/language_scope.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/features/auth/presentation/auth_controller.dart';
import 'package:hackathon_net/features/auth/presentation/auth_scope.dart';
import 'package:hackathon_net/features/root/root_gate.dart';

class UrbanScoreApp extends StatelessWidget {
  const UrbanScoreApp({
    super.key,
    required this.authController,
    required this.languageController,
  });

  final AuthController authController;
  final LanguageController languageController;

  @override
  Widget build(BuildContext context) {
    return LanguageScope(
      controller: languageController,
      child: AuthScope(
        controller: authController,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'urban syrix',
          theme: AppTheme.theme,
          home: const RootGate(),
        ),
      ),
    );
  }
}
