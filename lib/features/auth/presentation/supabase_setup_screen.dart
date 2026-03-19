import 'package:flutter/material.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/core/widgets/city_background.dart';

class SupabaseSetupScreen extends StatelessWidget {
  const SupabaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CityBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GlassPanel(
                  padding: const EdgeInsets.all(28),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionEyebrow(label: 'System setup'),
                      SizedBox(height: 18),
                      Text(
                        'Supabase is not configured',
                        style: TextStyle(
                          fontSize: 34,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Run the app with SUPABASE_URL and SUPABASE_ANON_KEY passed through --dart-define.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      SizedBox(height: 18),
                      SelectableText(
                        'flutter run -d chrome '
                        '--dart-define=SUPABASE_URL=https://your-project.supabase.co '
                        '--dart-define=SUPABASE_ANON_KEY=your-anon-key',
                        style: TextStyle(
                          color: AppTheme.accentStrong,
                          fontFamily: 'monospace',
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
