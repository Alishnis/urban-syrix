import 'package:flutter/material.dart';
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
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF3F5EF),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E5B52),
            brightness: Brightness.light,
          ),
        ),
        home: const RootGate(),
      ),
    );
  }
}
