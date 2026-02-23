import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wrapper around FlutterSecureStorage.
/// Purpose:
/// - Centralize how auth tokens are stored
/// - Avoid scattering key strings across the app
/// - Make storage easily replaceable/testable
class SecureStorage {
  // Key used to store auth token securely on device
  static const _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;

  const SecureStorage(this._storage);

  /// Read token from secure storage (returns null if not found)
  Future<String?> readToken() {
    return _storage.read(key: _tokenKey);
  }

  /// Save token securely
  Future<void> writeToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  /// Remove token on logout
  Future<void> deleteToken() {
    return _storage.delete(key: _tokenKey);
  }
}

/// Riverpod provider for SecureStorage
/// Keeps storage accessible throughout the app
final secureStorageProvider = Provider<SecureStorage>((ref) {
  const storage = FlutterSecureStorage();
  return const SecureStorage(storage);
});
