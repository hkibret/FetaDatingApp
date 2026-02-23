// lib/features/discover/data/discover_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../models/profile.dart';
import 'discover_api.dart';

/// Repository layer for Discover feature.
///
/// Responsibilities:
/// - Calls the API layer (DiscoverApi)
/// - Converts raw JSON/maps into strongly-typed Profile objects
/// - Keeps parsing/mapping logic out of UI and providers
class DiscoverRepository {
  final DiscoverApi _api;
  DiscoverRepository(this._api);

  /// Fetch discovery candidates.
  ///
  /// [limit] and [offset] support pagination.
  Future<List<Profile>> getCandidates({int limit = 50, int offset = 0}) async {
    final raw = await _api.fetchCandidates(limit: limit, offset: offset);
    return raw.map(_mapToProfile).toList(growable: false);
  }

  /// Converts a single API map into a Profile model.
  Profile _mapToProfile(Map<String, dynamic> j) {
    try {
      final id = (j['id'] ?? '').toString();
      final name = (j['name'] ?? '').toString();

      if (id.isEmpty || name.isEmpty) {
        throw Exception('Missing required fields (id/name).');
      }

      // Supabase may return nulls for these until you populate them
      final age = (j['age'] as num?)?.toInt() ?? 0;

      final photoUrl = (j['photoUrl'] ?? '').toString();
      final location = (j['location'] ?? 'Unknown').toString();

      final distanceMiles = (j['distanceMiles'] as num?)?.toDouble();
      final onlineNow = (j['onlineNow'] as bool?) ?? false;

      final lastActiveRaw = j['lastActiveAt']?.toString();
      final lastActiveAt = (lastActiveRaw != null)
          ? DateTime.parse(lastActiveRaw)
          : DateTime.now();

      return Profile(
        id: id,
        name: name,
        age: age,
        photoUrl: photoUrl,
        location: location,
        distanceMiles: distanceMiles, // allow null if your Profile supports it
        onlineNow: onlineNow,
        lastActiveAt: lastActiveAt,
      );
    } catch (e) {
      throw Exception('Invalid profile payload from API: $j\nError: $e');
    }
  }
}

/// Provides DiscoverApi (depends on Dio)
final discoverApiProvider = Provider<DiscoverApi>((ref) {
  final Dio dio = ref.watch(dioProvider);

  // Flip this to false to use Supabase
  return DiscoverApi(dio, useMock: false);
});

/// Provides DiscoverRepository (depends on DiscoverApi)
final discoverRepositoryProvider = Provider<DiscoverRepository>((ref) {
  return DiscoverRepository(ref.watch(discoverApiProvider));
});
