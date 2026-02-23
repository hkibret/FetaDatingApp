import 'package:hive_flutter/hive_flutter.dart';

/// Central place to initialize Hive and access app boxes.
///
/// We store simple Maps/Lists (no TypeAdapters) to move fast:
/// - Auth token/email in `authBox`
/// - Matches list in `matchesBox`
/// - Chats map in `chatsBox`
class HiveService {
  static const String _authBoxName = 'authBox';
  static const String _matchesBoxName = 'matchesBox';
  static const String _chatsBoxName = 'chatsBox';

  static late Box authBox;
  static late Box matchesBox;
  static late Box chatsBox;

  /// Call once in main() before runApp()
  static Future<void> init() async {
    await Hive.initFlutter();

    authBox = await Hive.openBox(_authBoxName);
    matchesBox = await Hive.openBox(_matchesBoxName);
    chatsBox = await Hive.openBox(_chatsBoxName);
  }

  // ---------- Auth ----------
  static String? getToken() => authBox.get('token') as String?;
  static String? getEmail() => authBox.get('email') as String?;

  static Future<void> saveAuth({
    required String token,
    required String email,
    String? userId,
  }) async {
    await authBox.put('token', token);
    await authBox.put('email', email);
    if (userId != null) await authBox.put('userId', userId);
  }

  static Future<void> clearAuth() async {
    await authBox.delete('token');
    await authBox.delete('email');
    await authBox.delete('userId');
  }

  // ---------- Matches ----------
  static List<Map<String, dynamic>> getMatchesRaw() {
    final raw = matchesBox.get('items');
    if (raw is List) {
      return raw.cast<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    return <Map<String, dynamic>>[];
  }

  static Future<void> saveMatchesRaw(List<Map<String, dynamic>> items) async {
    await matchesBox.put('items', items);
  }

  static Future<void> clearMatches() async {
    await matchesBox.delete('items');
  }

  // ---------- Chats ----------
  /// Stored as: { matchId: [ {messageMap}, ... ], ... }
  static Map<String, List<Map<String, dynamic>>> getChatsRaw() {
    final raw = chatsBox.get('threads');
    if (raw is Map) {
      final map = <String, List<Map<String, dynamic>>>{};
      for (final entry in raw.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is List) {
          map[key] = value
              .cast<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
        } else {
          map[key] = <Map<String, dynamic>>[];
        }
      }
      return map;
    }
    return <String, List<Map<String, dynamic>>>{};
  }

  static Future<void> saveChatsRaw(
    Map<String, List<Map<String, dynamic>>> threads,
  ) async {
    await chatsBox.put('threads', threads);
  }

  static Future<void> clearChats() async {
    await chatsBox.delete('threads');
  }

  // ---------- Convenience ----------
  static Future<void> wipeAllUserData() async {
    await clearAuth();
    await clearMatches();
    await clearChats();
  }
}
