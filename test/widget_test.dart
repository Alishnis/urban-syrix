import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_net/app.dart';
import 'package:hackathon_net/core/localization/language_controller.dart';
import 'package:hackathon_net/features/auth/data/auth_repository.dart';
import 'package:hackathon_net/features/auth/domain/app_role.dart';
import 'package:hackathon_net/features/auth/domain/user_profile.dart';
import 'package:hackathon_net/features/auth/presentation/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('Shows supabase setup when auth is not configured', (
    WidgetTester tester,
  ) async {
    final repository = _FakeAuthRepository();
    final controller = AuthController(repository);
    final languageController = LanguageController();

    await tester.pumpWidget(
      UrbanScoreApp(
        authController: controller,
        languageController: languageController,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Supabase is not configured'), findsOneWidget);
    expect(find.textContaining('Run the app with SUPABASE_URL'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required AppRole role,
  }) async {}

  @override
  Future<UserProfile?> fetchProfile() async => null;

  @override
  Future<void> ensureProfile({
    required User user,
    required AppRole role,
  }) async {}
}
