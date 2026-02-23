// lib/features/matches/providers/matches_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../discover/models/profile.dart';
import '../../discover/providers/likes_providers.dart';

/// Matches (Supabase)
///
/// matchedProfilesProvider already joins:
/// - matches view (mutual likes)
/// - profiles table (to get Profile objects)
///
/// So this provider is just an alias your Matches UI can depend on.
final matchesProvider = Provider<AsyncValue<List<Profile>>>((ref) {
  return ref.watch(matchedProfilesProvider);
});
