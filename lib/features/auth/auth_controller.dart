// lib/features/auth/auth_controller.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/storage/hive_service.dart';
import '../profile/providers/profile_providers.dart';

class AuthState {
  final bool isLoggedIn;
  final String? token;
  final String? userId;
  final String? email;

  /// controls onboarding gate after login
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
    ref.onDispose(() {
      _authSub?.cancel();
      _authSub = null;
    });

    _authSub ??= _sb.auth.onAuthStateChange.listen((sb.AuthState data) async {
      if (kDebugMode) {
        debugPrint(
          'Auth event: ${data.event} | session? ${data.session != null}',
        );
      }

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

        _invalidateUserScopedProviders();
      } else {
        await HiveService.clearAuth();
        state = const AuthState.loggedOut();
        _invalidateUserScopedProviders();
      }
    });

    final token = HiveService.getToken();
    final email = HiveService.getEmail();
    final userId = HiveService.authBox.get('userId') as String?;

    final session = _sb.auth.currentSession;
    final user = _sb.auth.currentUser;

    if (session != null && user != null) {
      final initial = AuthState(
        isLoggedIn: true,
        token: session.accessToken,
        email: user.email?.trim().toLowerCase() ?? email,
        userId: user.id,
        onboardingCompleted: false,
      );

      unawaited(
        HiveService.saveAuth(
          token: session.accessToken,
          email: (user.email ?? email ?? '').trim().toLowerCase(),
          userId: user.id,
        ),
      );

      unawaited(_syncOnboardingFlag(user.id));

      return initial;
    }

    if (token != null && token.isNotEmpty) {
      return AuthState(
        isLoggedIn: false,
        token: token,
        email: email,
        userId: userId,
        onboardingCompleted: false,
      );
    }

    return const AuthState.loggedOut();
  }

  void _invalidateUserScopedProviders() {
    ref.invalidate(authUserIdProvider);
    ref.invalidate(myProfileProvider);
    ref.invalidate(discoverProfilesProvider);
  }

  Future<void> _syncOnboardingFlag(String userId) async {
    try {
      final done = await _fetchOnboardingCompletedSafe(userId);
      if (state.isLoggedIn && state.userId == userId) {
        state = state.copyWith(onboardingCompleted: done);
      }
    } catch (_) {
      // ignore
    }
  }

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

  void markOnboardingCompleted() {
    if (!state.isLoggedIn) return;
    state = state.copyWith(onboardingCompleted: true);
    _invalidateUserScopedProviders();
  }

  void markOnboardingIncomplete() {
    if (!state.isLoggedIn) return;
    state = state.copyWith(onboardingCompleted: false);
    _invalidateUserScopedProviders();
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
      await HiveService.clearAuth();
      state = const AuthState.loggedOut();
      _invalidateUserScopedProviders();

      final res = await _sb.auth.signInWithPassword(email: e, password: p);

      final session = res.session;
      final user = res.user;

      if (session == null || user == null) {
        throw Exception('Login failed. No session returned.');
      }

      if (kDebugMode) {
        debugPrint('LOGIN access token length: ${session.accessToken.length}');
        debugPrint('LOGIN user id: ${user.id}');
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

      _invalidateUserScopedProviders();

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
      await HiveService.clearAuth();
      state = const AuthState.loggedOut();
      _invalidateUserScopedProviders();

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

      if (session == null) {
        await HiveService.clearAuth();
        state = const AuthState.loggedOut();
        _invalidateUserScopedProviders();
        return res;
      }

      if (kDebugMode) {
        debugPrint(
          'REGISTER access token length: ${session.accessToken.length}',
        );
        debugPrint('REGISTER user id: ${user.id}');
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

      _invalidateUserScopedProviders();

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
    _invalidateUserScopedProviders();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
