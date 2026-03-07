import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_model.dart';

class ProfileRepo {
  ProfileRepo(this._client);

  final SupabaseClient _client;

  /// Fetch current user's profile
  Future<Profile?> fetchMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromMap(Map<String, dynamic>.from(data));
  }

  /// Fetch discover profiles using the SQL RPC that filters by:
  /// - my gender
  /// - my interested_in
  /// - candidate gender
  /// - candidate interested_in
  Future<List<Profile>> fetchDiscoverProfiles() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client.rpc('get_discover_profiles');

    final rows = (data as List<dynamic>? ?? const []);
    return rows
        .map((e) => Profile.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Optional fallback if you want to inspect all profiles except me.
  Future<List<Profile>> fetchAllProfilesExceptMe() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client.from('profiles').select().neq('id', user.id);

    final rows = (data as List<dynamic>? ?? const []);
    return rows
        .map((e) => Profile.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Upload avatar bytes to Supabase Storage and return the public URL.
  /// Requires a bucket named `avatars`.
  Future<String> uploadAvatarBytes(
    Uint8List bytes, {
    required String ext,
    required String contentType,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final safeExt = ext.replaceAll('.', '').toLowerCase();
    final path = '${user.id}/avatar.$safeExt';

    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
    return publicUrl;
  }

  /// Upsert profile fields into `profiles` table.
  Future<void> upsertProfile({
    String? name,
    int? age,
    String? bio,
    String? location,
    String? avatarUrl,
    List<String>? photos,
    String? gender,
    String? interestedIn,
    bool? onboardingCompleted,
    String? bodyType,
    int? heightCm,
    String? smoking,
    String? drinking,
    String? datingIntent,
    String? hasKids,
    String? religion,
    String? education,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final payload = <String, dynamic>{
      'id': user.id,
      'email': user.email,
      'name': name,
      'age': age,
      'bio': bio,
      'location': location,
      'avatar_url': avatarUrl,
      'photos': photos,
      'gender': gender?.toLowerCase(),
      'interested_in': interestedIn?.toLowerCase(),
      'onboarding_completed': onboardingCompleted,
      'body_type': bodyType,
      'height_cm': heightCm,
      'smoking': smoking,
      'drinking': drinking,
      'dating_intent': datingIntent,
      'has_kids': hasKids,
      'religion': religion,
      'education': education,
      'updated_at': DateTime.now().toIso8601String(),
    };

    payload.removeWhere((key, value) => value == null);

    await _client.from('profiles').upsert(payload);
  }
}
