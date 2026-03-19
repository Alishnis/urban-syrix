import 'package:flutter/material.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/features/auth/presentation/auth_controller.dart';
import 'package:hackathon_net/features/auth/presentation/auth_scope.dart';
import 'package:hackathon_net/features/root/root_gate.dart';

class UrbanScoreApp extends StatelessWidget {
  const UrbanScoreApp({super.key, required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: authController,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'UrbanScore',
        theme: AppTheme.theme,
        home: const RootGate(),
      ),
    );
  }
}
