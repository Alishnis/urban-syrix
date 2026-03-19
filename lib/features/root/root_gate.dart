import 'package:flutter/material.dart';
import 'package:hackathon_net/core/config/supabase_config.dart';
import 'package:hackathon_net/features/auth/presentation/auth_scope.dart';
import 'package:hackathon_net/features/auth/presentation/auth_screen.dart';
import 'package:hackathon_net/features/auth/presentation/supabase_setup_screen.dart';
import 'package:hackathon_net/features/shell/app_shell.dart';

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) {
      return const SupabaseSetupScreen();
    }

    final auth = AuthScope.of(context);
    if (auth.isAuthenticated && auth.isProfileLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.isAuthenticated && auth.profileError != null) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile setup is incomplete',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Supabase auth works, but the profiles table or its policies are missing.',
                      ),
                      const SizedBox(height: 12),
                      SelectableText(auth.profileError!),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (auth.isAuthenticated) {
      return const AppShell();
    }
    return const AuthScreen();
  }
}
