import 'package:flutter/material.dart';

class SupabaseSetupScreen extends StatelessWidget {
  const SupabaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Supabase is not configured',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Run the app with SUPABASE_URL and SUPABASE_ANON_KEY passed through --dart-define.',
                    ),
                    SizedBox(height: 16),
                    SelectableText(
                      'flutter run -d chrome '
                      '--dart-define=SUPABASE_URL=https://your-project.supabase.co '
                      '--dart-define=SUPABASE_ANON_KEY=your-anon-key',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
