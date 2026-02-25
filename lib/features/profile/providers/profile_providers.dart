import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/profile_repo.dart';
import '../data/profile_model.dart';

final profileRepoProvider = Provider<ProfileRepo>((ref) {
  return ProfileRepo(Supabase.instance.client);
});

final myProfileProvider = FutureProvider<Profile?>((ref) async {
  final repo = ref.read(profileRepoProvider);
  return repo.fetchMyProfile();
});
