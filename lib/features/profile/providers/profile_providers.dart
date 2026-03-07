import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/profile_model.dart';
import '../data/profile_repo.dart';

final profileRepoProvider = Provider<ProfileRepo>((ref) {
  return ProfileRepo(Supabase.instance.client);
});

/// Emits current authenticated user id and updates automatically
/// when login / register / logout changes auth state.
final authUserIdProvider = StreamProvider<String?>((ref) async* {
  final client = Supabase.instance.client;

  yield client.auth.currentUser?.id;

  await for (final event in client.auth.onAuthStateChange) {
    yield event.session?.user.id;
  }
});

/// Current user's profile
/// Depends on authUserIdProvider so it refreshes when user changes.
final myProfileProvider = FutureProvider<Profile?>((ref) async {
  final repo = ref.read(profileRepoProvider);
  final userId = await ref.watch(authUserIdProvider.future);

  if (userId == null) return null;
  return repo.fetchProfileById(userId);
});

/// Discover profiles (filtered by gender + interested_in)
/// Also refreshes automatically when logged-in user changes.
final discoverProfilesProvider = FutureProvider<List<Profile>>((ref) async {
  final repo = ref.read(profileRepoProvider);
  final userId = await ref.watch(authUserIdProvider.future);

  if (userId == null) return [];
  return repo.fetchDiscoverProfiles();
});

/// Profile detail page provider
final profileByIdProvider = FutureProvider.family<Profile?, String>((
  ref,
  profileId,
) async {
  final repo = ref.read(profileRepoProvider);
  return repo.fetchProfileById(profileId);
});
