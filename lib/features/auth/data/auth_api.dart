// lib/features/auth/data/auth_api.dart
import 'package:dio/dio.dart';

/// Low-level HTTP calls for authentication.
///
/// Responsibilities:
/// - Call auth endpoints via Dio
/// - Return raw values (token only)
/// - Switch between mock and real backend without refactor
class AuthApi {
  final Dio _dio;

  /// Toggle when backend is ready
  final bool useMock;

  AuthApi(this._dio, {this.useMock = true});

  Future<String> login({
    required String email,
    required String password,
  }) async {
    if (!useMock) {
      final res = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      return res.data['token'] as String;
    }

    // -----------------------------
    // Mock logic (v1)
    // -----------------------------
    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (email.trim().isEmpty || password.isEmpty) {
      throw Exception('Email and password are required.');
    }

    return 'mock_token_${email.trim()}';
  }

  Future<String> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (!useMock) {
      final res = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
        },
      );

      return res.data['token'] as String;
    }

    // -----------------------------
    // Mock logic (v1)
    // -----------------------------
    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (email.trim().isEmpty || password.isEmpty) {
      throw Exception('Email and password are required.');
    }
    if (password != confirmPassword) {
      throw Exception('Passwords do not match.');
    }

    return 'mock_token_${email.trim()}';
  }
}
