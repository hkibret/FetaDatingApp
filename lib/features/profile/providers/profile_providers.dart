import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/profile_repo.dart';
import '../data/profile_model.dart';

final profileRepoProvider = Provider<ProfileRepo>((ref) {
  return ProfileRepo(Supabase.instance.client);
});

/// Current user's profile
final myProfileProvider = FutureProvider<Profile?>((ref) async {
  final repo = ref.read(profileRepoProvider);
  return repo.fetchMyProfile();
});

/// Discover profiles (filtered by gender + interested_in)
final discoverProfilesProvider = FutureProvider<List<Profile>>((ref) async {
  final repo = ref.read(profileRepoProvider);
  return repo.fetchDiscoverProfiles();
});

/// Profile detail page provider
final profileByIdProvider = FutureProvider.family<Profile?, String>((
  ref,
  profileId,
) async {
  final client = Supabase.instance.client;

  final data = await client
      .from('profiles')
      .select()
      .eq('id', profileId)
      .maybeSingle();

  if (data == null) return null;

  return Profile.fromMap(Map<String, dynamic>.from(data));
});
