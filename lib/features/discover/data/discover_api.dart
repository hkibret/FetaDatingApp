// lib/features/discover/data/discover_api.dart
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiscoverApi {
  final Dio _dio;

  /// Flip to false to use Supabase backend
  final bool useMock;

  DiscoverApi(this._dio, {this.useMock = true});

  SupabaseClient get _sb => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchCandidates({
    int limit = 50,
    int offset = 0,
  }) async {
    // =========================
    // REAL BACKEND (SUPABASE)
    // =========================
    if (!useMock) {
      final me = _sb.auth.currentUser?.id;

      var q = _sb.from('profiles').select();

      // Only exclude self if logged in
      if (me != null) {
        q = q.neq('id', me);
      }

      final res = await q
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      return (res as List).map<Map<String, dynamic>>((row) {
        final r = Map<String, dynamic>.from(row as Map);

        final photos = (r['photos'] is List)
            ? List<String>.from(r['photos'] as List)
            : const <String>[];

        final photoUrl = photos.isNotEmpty
            ? photos.first
            : 'https://picsum.photos/seed/${r['id']}/600/800';

        final lastActive = (r['updated_at'] ?? r['created_at']);
        final lastActiveIso = lastActive is String
            ? lastActive
            : (lastActive?.toString() ?? DateTime.now().toIso8601String());

        return {
          'id': r['id']?.toString(),
          'name': r['name']?.toString() ?? '',
          'age': r['age'], // repository handles null safely
          'photoUrl': photoUrl,
          'location': (r['location'] ?? 'Unknown').toString(),
          'distanceMiles': null, // add geo later
          'onlineNow': false, // add presence later
          'lastActiveAt': lastActiveIso,
        };
      }).toList();
    }

    // =========================
    // MOCK DATA (UI DEV)
    // =========================
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return [
      {
        'id': 'p1',
        'name': 'Sara',
        'age': 26,
        'photoUrl': 'https://picsum.photos/seed/sara/600/800',
        'location': 'Boston, MA',
        'distanceMiles': 3.4,
        'onlineNow': true,
        'lastActiveAt': DateTime.now().toIso8601String(),
      },
      {
        'id': 'p2',
        'name': 'Miki',
        'age': 29,
        'photoUrl': 'https://picsum.photos/seed/miki/600/800',
        'location': 'Cambridge, MA',
        'distanceMiles': 8.2,
        'onlineNow': false,
        'lastActiveAt': DateTime.now()
            .subtract(const Duration(hours: 3))
            .toIso8601String(),
      },
      {
        'id': 'p3',
        'name': 'Liya',
        'age': 24,
        'photoUrl': 'https://picsum.photos/seed/liya/600/800',
        'location': 'Somerville, MA',
        'distanceMiles': 12.7,
        'onlineNow': false,
        'lastActiveAt': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      },
    ];
  }
}
