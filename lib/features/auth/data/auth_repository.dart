import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hackathon_net/features/auth/domain/app_role.dart';
import 'package:hackathon_net/features/auth/domain/user_profile.dart';

abstract class AuthRepository {
  User? get currentUser;
  Stream<AuthState> get authStateChanges;
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String email,
    required String password,
    required AppRole role,
  });
  Future<void> signOut();
  Future<UserProfile?> fetchProfile();
  Future<void> ensureProfile({
    required User user,
    required AppRole role,
  });
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required AppRole role,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'role': role.key},
    );

    final user = response.user;
    if (user != null) {
      await ensureProfile(user: user, role: role);
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<UserProfile?> fetchProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final response = await _client
        .from('profiles')
        .select('id, email, role')
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return UserProfile.fromMap(response);
  }

  @override
  Future<void> ensureProfile({
    required User user,
    required AppRole role,
  }) async {
    await _client.from('profiles').upsert({
      'id': user.id,
      'email': user.email,
      'role': role.key,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');
  }
}

class UnconfiguredAuthRepository implements AuthRepository {
  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<void> signIn({required String email, required String password}) {
    throw const AuthException('Supabase is not configured.');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required AppRole role,
  }) {
    throw const AuthException('Supabase is not configured.');
  }

  @override
  Future<UserProfile?> fetchProfile() async => null;

  @override
  Future<void> ensureProfile({
    required User user,
    required AppRole role,
  }) async {}
}
