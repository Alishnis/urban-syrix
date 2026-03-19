import 'package:flutter/material.dart';
import 'package:hackathon_net/core/localization/app_localizations.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/core/widgets/city_background.dart';
import 'package:hackathon_net/features/auth/presentation/auth_scope.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.user;
    final profile = auth.profile;
    final loc = AppLocalizations.of(context);
    final roleKey = profile?.role.key ?? 'resident';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        SectionEyebrow(label: loc.tr('profile')),
        const SizedBox(height: 14),
        GlassPanel(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.tr('operator_profile'),
                style: TextStyle(
                  fontSize: 34,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user?.email ?? loc.tr('unknown_email'),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 16),
              Chip(
                label: Text(loc.roleLabel(roleKey)),
                avatar: const Icon(Icons.badge_outlined, size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassPanel(
          child: ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: Text(loc.tr('authenticated_supabase')),
            subtitle: Text(
              '${loc.tr('user_id')}: ${user?.id ?? loc.tr('unavailable')}\n${loc.tr('role')}: ${loc.roleLabel(roleKey)}',
            ),
          ),
        ),
        if (roleKey == 'admin') ...[
          const SizedBox(height: 16),
          GlassPanel(
            child: ListTile(
              leading: Icon(Icons.admin_panel_settings_outlined),
              title: Text(loc.tr('admin_access')),
              subtitle: Text(loc.tr('admin_access_body')),
            ),
          ),
        ],
        if (roleKey == 'builder') ...[
          const SizedBox(height: 16),
          GlassPanel(
            child: ListTile(
              leading: Icon(Icons.construction_outlined),
              title: Text(loc.tr('builder_workspace')),
              subtitle: Text(loc.tr('builder_workspace_body')),
            ),
          ),
        ],
        if (roleKey == 'resident') ...[
          const SizedBox(height: 16),
          GlassPanel(
            child: ListTile(
              leading: Icon(Icons.home_outlined),
              title: Text(loc.tr('resident_workspace')),
              subtitle: Text(loc.tr('resident_workspace_body')),
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: auth.isBusy ? null : auth.signOut,
          icon: const Icon(Icons.logout_rounded),
          label: Text(
            auth.isBusy ? loc.tr('please_wait') : loc.tr('sign_out'),
          ),
        ),
      ],
    );
  }
}
