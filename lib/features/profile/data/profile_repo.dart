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

    return fetchProfileById(user.id);
  }

  /// Fetch any profile by id
  Future<Profile?> fetchProfileById(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromMap(Map<String, dynamic>.from(data));
  }

  /// Fetch discover profiles using the SQL RPC that filters by:
  /// - my gender
  /// - my interested_in
  /// - candidate gender
  /// - candidate interested_in
  /// - only users with real uploaded images
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

  /// Upload main avatar bytes to Supabase Storage and return the public URL.
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

    return _client.storage.from('avatars').getPublicUrl(path);
  }

  /// Upload one extra gallery photo and return the public URL.
  Future<String> uploadGalleryPhotoBytes(
    Uint8List bytes, {
    required String ext,
    required String contentType,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final safeExt = ext.replaceAll('.', '').toLowerCase();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$safeExt';
    final path = '${user.id}/photos/$fileName';

    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: false, contentType: contentType),
        );

    return _client.storage.from('avatars').getPublicUrl(path);
  }

  /// Save the full gallery list onto the profile row.
  Future<void> updatePhotoGallery(List<String> photos) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client
        .from('profiles')
        .update({
          'photos': photos,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  }

  /// Add a single photo URL to the gallery.
  Future<void> addPhotoToGallery(String photoUrl) async {
    final profile = await fetchMyProfile();
    if (profile == null) throw Exception('Profile not found');

    final photos = [...profile.photos];
    photos.add(photoUrl);

    await updatePhotoGallery(photos);
  }

  /// Remove a single photo URL from the gallery.
  Future<void> removePhotoFromGallery(String photoUrl) async {
    final profile = await fetchMyProfile();
    if (profile == null) throw Exception('Profile not found');

    final photos = [...profile.photos]..remove(photoUrl);

    await updatePhotoGallery(photos);
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
      'gender': gender?.trim().toLowerCase(),
      'interested_in': interestedIn?.trim().toLowerCase(),
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

  /// Clear avatar for the current user
  Future<void> clearAvatar() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client
        .from('profiles')
        .update({
          'avatar_url': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  }

  /// Clear all gallery photos for the current user
  Future<void> clearGallery() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client
        .from('profiles')
        .update({
          'photos': <String>[],
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  }
}
