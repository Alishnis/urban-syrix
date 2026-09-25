import 'package:flutter/material.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/core/widgets/city_background.dart';
import 'package:hackathon_net/features/auth/domain/app_role.dart';
import 'package:hackathon_net/features/auth/presentation/auth_scope.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  AppRole _selectedRole = AppRole.resident;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return Scaffold(
      body: CityBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final vertical = constraints.maxWidth < 900;
                    if (vertical) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            _AuthHero(isLogin: _isLogin),
                            const SizedBox(height: 20),
                            _AuthFormCard(
                              formKey: _formKey,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              isLogin: _isLogin,
                              selectedRole: _selectedRole,
                              errorText: _errorText,
                              isBusy: auth.isBusy,
                              onRoleChanged: (value) {
                                setState(() {
                                  _selectedRole = value;
                                });
                              },
                              onSubmit: _submit,
                              onToggleMode: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _errorText = null;
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          flex: 11,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 24),
                            child: _AuthHero(isLogin: _isLogin),
                          ),
                        ),
                        Expanded(
                          flex: 9,
                          child: _AuthFormCard(
                            formKey: _formKey,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            isLogin: _isLogin,
                            selectedRole: _selectedRole,
                            errorText: _errorText,
                            isBusy: auth.isBusy,
                            onRoleChanged: (value) {
                              setState(() {
                                _selectedRole = value;
                              });
                            },
                            onSubmit: _submit,
                            onToggleMode: () {
                              setState(() {
                                _isLogin = !_isLogin;
                                _errorText = null;
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = AuthScope.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _errorText = null;
    });

    try {
      if (_isLogin) {
        await auth.signIn(email: email, password: password);
      } else {
        await auth.signUp(
          email: email,
          password: password,
          role: _selectedRole,
        );
      }
      // When reached by pushing from the public map screen, this reveals
      // the RootGate route underneath, which has already rebuilt into
      // AppShell now that AuthController reports an authenticated user.
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } on AuthException catch (error) {
      setState(() {
        _errorText = error.message;
      });
    } catch (_) {
      setState(() {
        _errorText =
            'Authentication failed. Check Supabase settings and try again.';
      });
    }
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.isLogin});

  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    const cards = [
      _SignalCard(
        title: 'Pipe replacement in district 7',
        body: 'Scheduled utility maintenance with low traffic impact.',
        color: AppTheme.accent,
        icon: Icons.bolt_rounded,
        status: 'ACTIVE',
      ),
      _SignalCard(
        title: 'Gas leak response',
        body: 'Emergency services deployed with active exclusion perimeter.',
        color: AppTheme.danger,
        icon: Icons.warning_amber_rounded,
        status: 'URGENT',
      ),
      _SignalCard(
        title: 'Grid modernization',
        body: 'Substation upgrade in progress with short planned outages.',
        color: AppTheme.info,
        icon: Icons.electrical_services_rounded,
        status: 'IN PROGRESS',
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const SectionEyebrow(label: 'urban syrix control layer'),
          const SizedBox(height: 18),
          Text(
            'Your city,\ndecoded\nin real time.',
            style: TextStyle(
              fontSize: compact ? 44 : 64,
              height: 0.95,
              fontWeight: FontWeight.w900,
              letterSpacing: compact ? -1.6 : -2.8,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isLogin
                ? 'Return to a live operational layer for resident signals, builder workflows and municipal oversight.'
                : 'Create a role-based account and enter the same structural glass interface used across the city workspace.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: compact ? 16 : 18,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 28),
          for (final card in cards) ...[card, const SizedBox(height: 12)],
        ],
      ),
    );
  }
}

class _AuthFormCard extends StatelessWidget {
  const _AuthFormCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLogin,
    required this.selectedRole,
    required this.errorText,
    required this.isBusy,
    required this.onRoleChanged,
    required this.onSubmit,
    required this.onToggleMode,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLogin;
  final AppRole selectedRole;
  final String? errorText;
  final bool isBusy;
  final ValueChanged<AppRole> onRoleChanged;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionEyebrow(label: 'Account access'),
            const SizedBox(height: 18),
            const Text(
              'Welcome to urban syrix.',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isLogin
                  ? 'Sign in to continue into the city operations workspace.'
                  : 'Create an account and choose the role that fits your city workflow.',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your email.';
                }
                if (!value.contains('@')) {
                  return 'Enter a valid email.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!isBusy) onSubmit();
              },
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your password.';
                }
                if (value.length < 6) {
                  return 'Use at least 6 characters.';
                }
                return null;
              },
            ),
            if (!isLogin) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<AppRole>(
                value: selectedRole,
                dropdownColor: AppTheme.bgTertiary,
                decoration: const InputDecoration(labelText: 'Account type'),
                items: const [
                  DropdownMenuItem(
                    value: AppRole.resident,
                    child: Text('Resident'),
                  ),
                  DropdownMenuItem(
                    value: AppRole.builder,
                    child: Text('Builder'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  onRoleChanged(value);
                },
              ),
              const SizedBox(height: 10),
              const Text(
                'Administrator accounts are assigned manually from Supabase.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ],
            if (errorText != null) ...[
              const SizedBox(height: 16),
              Text(
                errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isBusy ? null : onSubmit,
                child: Text(
                  isBusy
                      ? 'Please wait...'
                      : isLogin
                      ? 'Sign in'
                      : 'Create account',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: isBusy ? null : onToggleMode,
                child: Text(
                  isLogin
                      ? 'Need an account? Register'
                      : 'Already have an account? Sign in',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({
    required this.title,
    required this.body,
    required this.color,
    required this.icon,
    required this.status,
  });

  final String title;
  final String body;
  final Color color;
  final IconData icon;
  final String status;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
