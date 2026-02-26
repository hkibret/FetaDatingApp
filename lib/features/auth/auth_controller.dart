import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/storage/hive_service.dart';

/// Auth state for the app.
///
/// Notes:
/// - We store token/email/userId in Hive for persistence.
/// - Hive is not secure storage. For production, use flutter_secure_storage.
/// - Supabase also persists sessions internally; Hive here is mainly for your app state.
class AuthState {
  final bool isLoggedIn;
  final String? token;
  final String? userId;
  final String? email;

  const AuthState({
    required this.isLoggedIn,
    this.token,
    this.userId,
    this.email,
  });

  const AuthState.loggedOut() : this(isLoggedIn: false);

  AuthState copyWith({
    bool? isLoggedIn,
    String? token,
    String? userId,
    String? email,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      email: email ?? this.email,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  SupabaseClient get _sb => Supabase.instance.client;

  @override
  AuthState build() {
    // Keep state synced with Supabase session changes.
    _sb.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final user = session?.user;

      if (session != null && user != null) {
        await HiveService.saveAuth(
          token: session.accessToken,
          email: user.email ?? '',
          userId: user.id,
        );
        state = AuthState(
          isLoggedIn: true,
          token: session.accessToken,
          email: user.email,
          userId: user.id,
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
      // Keep Hive in sync (best-effort)
      HiveService.saveAuth(
        token: session.accessToken,
        email: user.email ?? email ?? '',
        userId: user.id,
      );

      return AuthState(
        isLoggedIn: true,
        token: session.accessToken,
        email: user.email ?? email,
        userId: user.id,
      );
    }

    // Fallback: Hive-based restore (your app state)
    if (token != null && token.isNotEmpty) {
      return AuthState(
        isLoggedIn: true,
        token: token,
        email: email,
        userId: userId,
      );
    }

    return const AuthState.loggedOut();
  }

  /// Login with Supabase:
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final e = email.trim();
    if (e.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required.');
    }

    try {
      final res = await _sb.auth.signInWithPassword(
        email: e,
        password: password,
      );

      final session = res.session;
      final user = res.user;

      if (session == null || user == null) {
        throw Exception('Login failed. No session returned.');
      }

      await HiveService.saveAuth(
        token: session.accessToken,
        email: user.email ?? e,
        userId: user.id,
      );

      state = AuthState(
        isLoggedIn: true,
        token: session.accessToken,
        email: user.email ?? e,
        userId: user.id,
      );

      return res;
    } on AuthException catch (ex) {
      throw Exception(ex.message);
    } catch (ex) {
      throw Exception(ex.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Register with Supabase:
  ///
  /// ✅ IMPORTANT:
  /// - Do NOT insert into public.profiles here.
  ///   Your database trigger handle_new_user() creates the profile row.
  ///
  /// Behavior:
  /// - If email confirmation is ON, Supabase returns user but session == null.
  ///   That is SUCCESS. We keep user logged out and let UI show "check email".
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final e = email.trim();

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
        // optional metadata
        data: const {'name': 'New User'},
      );

      final session = res.session;
      final user = res.user;

      if (user == null) {
        throw Exception('Registration failed. No user returned.');
      }

      // ✅ Email confirmation ON: session is null but user is created -> success
      if (session == null) {
        // Ensure local auth is cleared (user must confirm then login)
        await HiveService.clearAuth();
        state = const AuthState.loggedOut();
        return res;
      }

      // ✅ Email confirmation OFF: session exists -> logged in immediately
      await HiveService.saveAuth(
        token: session.accessToken,
        email: user.email ?? e,
        userId: user.id,
      );

      state = AuthState(
        isLoggedIn: true,
        token: session.accessToken,
        email: user.email ?? e,
        userId: user.id,
      );

      return res;
    } on AuthException catch (ex) {
      throw Exception(ex.message);
    } catch (ex) {
      throw Exception(ex.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Logout:
  Future<void> logout() async {
    try {
      await _sb.auth.signOut();
    } catch (_) {
      // Ignore signOut errors; we'll still clear local state.
    }

    await HiveService.clearAuth();
    state = const AuthState.loggedOut();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
