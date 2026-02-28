import 'dart:async'; // StreamSubscription + unawaited

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/storage/hive_service.dart';

class AuthState {
  final bool isLoggedIn;
  final String? token;
  final String? userId;
  final String? email;

  /// ✅ controls onboarding gate after login
  final bool onboardingCompleted;

  const AuthState({
    required this.isLoggedIn,
    this.token,
    this.userId,
    this.email,
    this.onboardingCompleted = false,
  });

  const AuthState.loggedOut() : this(isLoggedIn: false);

  AuthState copyWith({
    bool? isLoggedIn,
    String? token,
    String? userId,
    String? email,
    bool? onboardingCompleted,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  sb.SupabaseClient get _sb => sb.Supabase.instance.client;

  StreamSubscription<sb.AuthState>? _authSub;

  @override
  AuthState build() {
    // ✅ Ensure we don't register multiple listeners on rebuilds.
    ref.onDispose(() {
      _authSub?.cancel();
      _authSub = null;
    });

    // Keep state synced with Supabase session changes.
    _authSub ??= _sb.auth.onAuthStateChange.listen((sb.AuthState data) async {
      final session = data.session;
      final user = session?.user;

      if (session != null && user != null) {
        final onboardingDone = await _fetchOnboardingCompletedSafe(user.id);

        await HiveService.saveAuth(
          token: session.accessToken,
          email: (user.email ?? '').trim().toLowerCase(),
          userId: user.id,
        );

        state = AuthState(
          isLoggedIn: true,
          token: session.accessToken,
          email: user.email?.trim().toLowerCase(),
          userId: user.id,
          onboardingCompleted: onboardingDone,
        );
      } else {
        await HiveService.clearAuth();
        state = const AuthState.loggedOut();
      }
    });

    // Hive boxes are opened in main() before runApp() so reads are sync.
    final token = HiveService.getToken();
    final email = HiveService.getEmail();
    final userId = HiveService.authBox.get('userId') as String?;

    // Prefer Supabase current session if exists.
    final session = _sb.auth.currentSession;
    final user = _sb.auth.currentUser;

    if (session != null && user != null) {
      // build() can't be async, so return quickly and sync flag after
      final initial = AuthState(
        isLoggedIn: true,
        token: session.accessToken,
        email: user.email?.trim().toLowerCase() ?? email,
        userId: user.id,
        onboardingCompleted: false,
      );

      // Keep Hive in sync (best-effort)
      HiveService.saveAuth(
        token: session.accessToken,
        email: (user.email ?? email ?? '').trim().toLowerCase(),
        userId: user.id,
      );

      // ✅ async sync onboarding flag
      unawaited(_syncOnboardingFlag(user.id));

      return initial;
    }

    // ✅ CRITICAL FIX:
    // Hive token != Supabase session. Do NOT treat Hive token as logged-in.
    // This avoids "Not logged in" when calling Supabase later (like onboarding submit).
    if (token != null && token.isNotEmpty) {
      return AuthState(
        isLoggedIn: false, // ✅ important
        token: token,
        email: email,
        userId: userId,
        onboardingCompleted: false,
      );
    }

    return const AuthState.loggedOut();
  }

  Future<void> _syncOnboardingFlag(String userId) async {
    try {
      final done = await _fetchOnboardingCompletedSafe(userId);
      if (state.isLoggedIn && state.userId == userId) {
        state = state.copyWith(onboardingCompleted: done);
      }
    } catch (_) {
      // ignore; keep false
    }
  }

  /// ✅ Safe: does not throw if profiles row/column isn't ready yet.
  Future<bool> _fetchOnboardingCompletedSafe(String userId) async {
    try {
      final res = await _sb
          .from('profiles')
          .select('onboarding_completed')
          .eq('id', userId)
          .maybeSingle();

      return (res?['onboarding_completed'] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// ✅ Call this after onboarding submit succeeds
  void markOnboardingCompleted() {
    if (!state.isLoggedIn) return;
    state = state.copyWith(onboardingCompleted: true);
  }

  void markOnboardingIncomplete() {
    if (!state.isLoggedIn) return;
    state = state.copyWith(onboardingCompleted: false);
  }

  Future<sb.AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final e = email.trim().toLowerCase();
    final p = password;

    if (e.isEmpty || p.isEmpty) {
      throw Exception('Email and password are required.');
    }

    try {
      final res = await _sb.auth.signInWithPassword(email: e, password: p);

      final session = res.session;
      final user = res.user;

      if (session == null || user == null) {
        throw Exception('Login failed. No session returned.');
      }

      final onboardingDone = await _fetchOnboardingCompletedSafe(user.id);

      await HiveService.saveAuth(
        token: session.accessToken,
        email: (user.email ?? e).trim().toLowerCase(),
        userId: user.id,
      );

      state = AuthState(
        isLoggedIn: true,
        token: session.accessToken,
        email: (user.email ?? e).trim().toLowerCase(),
        userId: user.id,
        onboardingCompleted: onboardingDone,
      );

      return res;
    } on sb.AuthException catch (ex) {
      throw Exception(ex.message);
    } catch (ex) {
      throw Exception(ex.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<sb.AuthResponse> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final e = email.trim().toLowerCase();

    if (e.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      throw Exception('Email and passwords are required.');
    }
    if (password != confirmPassword) {
      throw Exception('Passwords do not match.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    try {
      final res = await _sb.auth.signUp(
        email: e,
        password: password,
        data: const {'name': 'New User'},
      );

      final session = res.session;
      final user = res.user;

      if (user == null) {
        throw Exception('Registration failed. No user returned.');
      }

      // Email confirmation ON: session null but user created -> success
      if (session == null) {
        await HiveService.clearAuth();
        state = const AuthState.loggedOut();
        return res;
      }

      final onboardingDone = await _fetchOnboardingCompletedSafe(user.id);

      await HiveService.saveAuth(
        token: session.accessToken,
        email: (user.email ?? e).trim().toLowerCase(),
        userId: user.id,
      );

      state = AuthState(
        isLoggedIn: true,
        token: session.accessToken,
        email: (user.email ?? e).trim().toLowerCase(),
        userId: user.id,
        onboardingCompleted: onboardingDone,
      );

      return res;
    } on sb.AuthException catch (ex) {
      throw Exception(ex.message);
    } catch (ex) {
      throw Exception(ex.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    try {
      await _sb.auth.signOut();
    } catch (_) {}

    await HiveService.clearAuth();
    state = const AuthState.loggedOut();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
