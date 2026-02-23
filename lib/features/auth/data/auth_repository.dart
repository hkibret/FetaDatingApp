import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/network/dio_provider.dart';
import 'auth_api.dart';

/// Repository = the layer AuthController talks to.
/// It hides whether auth comes from network, cache, etc.
class AuthRepository {
  final AuthApi _api;
  AuthRepository(this._api);

  Future<String> login({required String email, required String password}) {
    return _api.login(email: email, password: password);
  }

  Future<String> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    return _api.register(
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
  }
}

/// Provides AuthApi (depends on Dio)
final authApiProvider = Provider<AuthApi>((ref) {
  final Dio dio = ref.watch(dioProvider);
  return AuthApi(dio);
});

/// Provides AuthRepository (depends on AuthApi)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.watch(authApiProvider);
  return AuthRepository(api);
});
