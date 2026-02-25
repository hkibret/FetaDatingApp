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
    return Profile.fromMap(data);
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

    // Put it under the user folder; overwrite same filename for simplicity.
    final path = '${user.id}/avatar.$ext';

    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );

    // If bucket is public:
    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
    return publicUrl;
  }

  /// Upsert profile fields into `profiles` table.
  /// Your table must have columns: id, name, age, bio, avatar_url
  Future<void> upsertProfile({
    String? name,
    int? age,
    String? bio,
    String? avatarUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final payload = <String, dynamic>{
      'id': user.id,
      'name': name,
      'age': age,
      'bio': bio,
      'avatar_url': avatarUrl, // ✅ this is what makes the photo persist
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _client.from('profiles').upsert(payload);
  }
}
