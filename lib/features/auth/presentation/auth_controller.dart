import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hackathon_net/features/auth/data/auth_repository.dart';
import 'package:hackathon_net/features/auth/domain/app_role.dart';
import 'package:hackathon_net/features/auth/domain/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository) {
    _user = _repository.currentUser;
    _syncProfile();
    _subscription = _repository.authStateChanges.listen((state) {
      _user = state.session?.user;
      _syncProfile();
    });
  }

  final AuthRepository _repository;
  StreamSubscription<AuthState>? _subscription;

  User? _user;
  UserProfile? _profile;
  bool _isBusy = false;
  bool _isProfileLoading = false;
  String? _profileError;

  User? get user => _user;
  UserProfile? get profile => _profile;
  AppRole get role => _profile?.role ?? AppRole.resident;
  bool get isBusy => _isBusy;
  bool get isProfileLoading => _isProfileLoading;
  bool get isAuthenticated => _user != null;
  bool get isReady => !isAuthenticated || (!_isProfileLoading && _profile != null);
  String? get profileError => _profileError;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _runBusy(() async {
      await _repository.signIn(email: email, password: password);
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required AppRole role,
  }) async {
    await _runBusy(() async {
      await _repository.signUp(email: email, password: password, role: role);
    });
  }

  Future<void> signOut() async {
    await _runBusy(_repository.signOut);
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    _isBusy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _syncProfile() async {
    if (_user == null) {
      _profile = null;
      _profileError = null;
      _isProfileLoading = false;
      notifyListeners();
      return;
    }

    _isProfileLoading = true;
    _profileError = null;
    notifyListeners();

    try {
      var profile = await _repository.fetchProfile();
      if (profile == null) {
        final role = AppRole.fromKey(
          _user!.userMetadata?['role'] as String?,
        );
        await _repository.ensureProfile(user: _user!, role: role);
        profile = await _repository.fetchProfile();
      }
      _profile = profile;
    } catch (error) {
      _profileError = error.toString();
    } finally {
      _isProfileLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
