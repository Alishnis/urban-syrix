import 'package:flutter/material.dart';
import 'package:hackathon_net/features/shell/app_shell.dart';

class UrbanScoreApp extends StatelessWidget {
  const UrbanScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const AppShell(),
    );
  }
}
