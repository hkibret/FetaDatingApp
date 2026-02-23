import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

/// Helper: map Supabase profile row -> Profile model (same mapping as Discover)
Profile _profileFromRow(Map<String, dynamic> r) {
  final photos = (r['photos'] is List)
      ? List<String>.from(r['photos'] as List)
      : const <String>[];
  final photoUrl = photos.isNotEmpty
      ? photos.first
      : 'https://picsum.photos/seed/${r['id']}/600/800';

  final lastActive =
      (r['updated_at'] ?? r['created_at'])?.toString() ??
      DateTime.now().toIso8601String();

  return Profile(
    id: r['id']?.toString() ?? '',
    name: r['name']?.toString() ?? '',
    age: (r['age'] as num?)?.toInt() ?? 0,
    location: (r['location'] ?? 'Unknown').toString(),
    distanceMiles: null, // geo later
    onlineNow: false, // presence later
    lastActiveAt: DateTime.parse(lastActive),
    photoUrl: photoUrl,
  );
}

/// ------------------------------
/// LIKED IDS (from Supabase)
/// ------------------------------
final likedIdsProvider = StreamProvider<Set<String>>((ref) {
  final sb = Supabase.instance.client;
  final me = sb.auth.currentUser?.id;

  if (me == null) {
    return Stream.value(<String>{});
  }

  // Realtime stream of "my likes"
  return sb
      .from('likes')
      .stream(primaryKey: ['liker_id', 'liked_id'])
      .eq('liker_id', me)
      .map((rows) => rows.map((r) => r['liked_id'] as String).toSet());
});

/// Toggle like/unlike via Supabase.
/// UI calls: ref.read(likeActionsProvider).toggle(profileId)
final likeActionsProvider = Provider<LikeActions>((ref) {
  return LikeActions(Supabase.instance.client);
});

class LikeActions {
  final SupabaseClient _sb;
  LikeActions(this._sb);

  Future<void> toggle(String likedUserId) async {
    final me = _sb.auth.currentUser?.id;
    if (me == null) throw Exception('Not logged in.');

    // Check if already liked
    final existing = await _sb
        .from('likes')
        .select('liker_id,liked_id')
        .eq('liker_id', me)
        .eq('liked_id', likedUserId)
        .maybeSingle();

    if (existing != null) {
      // Unlike
      await _sb
          .from('likes')
          .delete()
          .eq('liker_id', me)
          .eq('liked_id', likedUserId);
    } else {
      // Like
      await _sb.from('likes').insert({'liker_id': me, 'liked_id': likedUserId});
    }
  }
}

/// Convenience: "is liked?"
final isLikedProvider = Provider.family<bool, String>((ref, profileId) {
  final likedAsync = ref.watch(likedIdsProvider);
  return likedAsync.maybeWhen(
    data: (set) => set.contains(profileId),
    orElse: () => false,
  );
});

/// ------------------------------
/// MATCHED IDS (from matches view)
/// matches view returns rows where:
/// user_id = me, matched_user_id = other
/// ------------------------------
final matchedIdsProvider = StreamProvider<Set<String>>((ref) {
  final sb = Supabase.instance.client;
  final me = sb.auth.currentUser?.id;

  if (me == null) {
    return Stream.value(<String>{});
  }

  return sb
      .from('matches')
      .stream(primaryKey: ['user_id', 'matched_user_id'])
      .eq('user_id', me)
      .map((rows) => rows.map((r) => r['matched_user_id'] as String).toSet());
});

/// Convenience: "is matched?"
final isMatchedProvider = Provider.family<bool, String>((ref, profileId) {
  final matchedAsync = ref.watch(matchedIdsProvider);
  return matchedAsync.maybeWhen(
    data: (set) => set.contains(profileId),
    orElse: () => false,
  );
});

/// ------------------------------
/// LIKED PROFILES (join via profiles)
/// ------------------------------
final likedProfilesProvider = StreamProvider<List<Profile>>((ref) {
  final sb = Supabase.instance.client;
  final me = sb.auth.currentUser?.id;

  if (me == null) {
    return Stream.value(const <Profile>[]);
  }

  // Stream likes, then fetch profiles for those ids
  return ref
      .watch(likedIdsProvider)
      .when(
        data: (ids) async* {
          if (ids.isEmpty) {
            yield const <Profile>[];
            return;
          }

          final rows = await sb
              .from('profiles')
              .select()
              .inFilter('id', ids.toList());
          final list = (rows as List)
              .map((r) => _profileFromRow(Map<String, dynamic>.from(r as Map)))
              .toList(growable: false);

          yield list;
        },
        loading: () async* {
          yield const <Profile>[];
        },
        error: (_, __) async* {
          yield const <Profile>[];
        },
      );
});

/// ------------------------------
/// MATCHED PROFILES (join via profiles)
/// ------------------------------
final matchedProfilesProvider = StreamProvider<List<Profile>>((ref) {
  final sb = Supabase.instance.client;
  final me = sb.auth.currentUser?.id;

  if (me == null) {
    return Stream.value(const <Profile>[]);
  }

  return ref
      .watch(matchedIdsProvider)
      .when(
        data: (ids) async* {
          if (ids.isEmpty) {
            yield const <Profile>[];
            return;
          }

          final rows = await sb
              .from('profiles')
              .select()
              .inFilter('id', ids.toList());
          final list = (rows as List)
              .map((r) => _profileFromRow(Map<String, dynamic>.from(r as Map)))
              .toList(growable: false);

          yield list;
        },
        loading: () async* {
          yield const <Profile>[];
        },
        error: (_, __) async* {
          yield const <Profile>[];
        },
      );
});
