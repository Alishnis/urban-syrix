import 'package:flutter/material.dart';
import 'package:hackathon_net/features/auth/presentation/auth_scope.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.user;
    final profile = auth.profile;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF143B34), Color(0xFF2E6B5F)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? 'Unknown email',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Chip(
                label: Text(profile?.role.label ?? 'Resident'),
                avatar: const Icon(Icons.badge_outlined, size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Authenticated with Supabase'),
            subtitle: Text(
              'User id: ${user?.id ?? 'Unavailable'}\nRole: ${profile?.role.key ?? 'resident'}',
            ),
          ),
        ),
        if (profile?.role.label == 'Administrator') ...[
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.admin_panel_settings_outlined),
              title: Text('Administrator access enabled'),
              subtitle: Text(
                'This account can be used for moderation and operational controls.',
              ),
            ),
          ),
        ],
        if (profile?.role.label == 'Builder') ...[
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.construction_outlined),
              title: Text('Builder workspace'),
              subtitle: Text(
                'Use this role for contractor and remediation workflows.',
              ),
            ),
          ),
        ],
        if (profile?.role.label == 'Resident') ...[
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.home_outlined),
              title: Text('Resident workspace'),
              subtitle: Text(
                'Use this role for reporting and monitoring local urban issues.',
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: auth.isBusy ? null : auth.signOut,
          icon: const Icon(Icons.logout_rounded),
          label: Text(auth.isBusy ? 'Please wait...' : 'Sign out'),
        ),
      ],
    );
  }
}
