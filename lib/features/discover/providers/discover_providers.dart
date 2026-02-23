// lib/features/discover/providers/discover_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/discover_repository.dart';
import '../models/filters.dart';
import '../models/profile.dart';
import 'discover_ui_providers.dart';

/// ------------------------------
/// Filters controller (Riverpod 3)
/// ------------------------------
final discoverFiltersProvider =
    NotifierProvider<DiscoverFiltersController, DiscoverFilters>(
      DiscoverFiltersController.new,
    );

class DiscoverFiltersController extends Notifier<DiscoverFilters> {
  @override
  DiscoverFilters build() => const DiscoverFilters.defaults();

  void setAgeRange(int min, int max) =>
      state = state.copyWith(minAge: min, maxAge: max);
  void setMaxDistance(double miles) =>
      state = state.copyWith(maxDistanceMiles: miles);
  void setLocationQuery(String value) =>
      state = state.copyWith(locationQuery: value);
  void setOnlineNowOnly(bool value) =>
      state = state.copyWith(onlineNowOnly: value);
  void setLastActiveWithinHours(int hours) =>
      state = state.copyWith(lastActiveWithinHours: hours);

  void reset() => state = const DiscoverFilters.defaults();
}

/// ------------------------------
/// Real profiles provider (Supabase via repository)
/// ------------------------------
/// This replaces mockProfilesProvider + discoverProfilesProvider
final discoverProfilesProvider = FutureProvider<List<Profile>>((ref) async {
  final repo = ref.watch(discoverRepositoryProvider);

  // Pagination: use your limit provider as the fetch limit
  final limit = ref.watch(discoverLimitProvider);
  return repo.getCandidates(limit: limit, offset: 0);
});

/// Profile lookup by id (for profile_detail_page)
final profileByIdProvider = Provider.family<Profile?, String>((ref, id) {
  final asyncProfiles = ref.watch(discoverProfilesProvider);

  return asyncProfiles.maybeWhen(
    data: (profiles) {
      for (final p in profiles) {
        if (p.id == id) return p;
      }
      return null;
    },
    orElse: () => null,
  );
});

/// ------------------------------
/// Filtered + searched + sorted list
/// ------------------------------
/// NOTE: This returns an empty list while loading/error.
/// Your UI can also show a spinner by watching discoverProfilesProvider directly.
final filteredProfilesProvider = Provider<List<Profile>>((ref) {
  final asyncProfiles = ref.watch(discoverProfilesProvider);
  final profiles = asyncProfiles.maybeWhen(
    data: (v) => v,
    orElse: () => const <Profile>[],
  );

  final f = ref.watch(discoverFiltersProvider);
  final search = ref.watch(discoverSearchProvider).trim().toLowerCase();
  final sort = ref.watch(discoverSortProvider);

  final now = DateTime.now();

  final filtered = profiles.where((p) {
    final ageOk = p.age >= f.minAge && p.age <= f.maxAge;

    // distanceMiles is nullable now → treat null as "unknown"
    // For filtering: if distance unknown, we allow it (or you can exclude it).
    final distOk = (p.distanceMiles == null)
        ? true
        : p.distanceMiles! <= f.maxDistanceMiles;

    final locQuery = f.locationQuery.trim().toLowerCase();
    final locOk =
        locQuery.isEmpty || p.location.toLowerCase().contains(locQuery);

    final onlineOk = !f.onlineNowOnly || p.onlineNow;

    final lastActiveOk = f.lastActiveWithinHours == 0
        ? true
        : p.lastActiveAt.isAfter(
            now.subtract(Duration(hours: f.lastActiveWithinHours)),
          );

    final searchOk =
        search.isEmpty ||
        p.name.toLowerCase().contains(search) ||
        p.location.toLowerCase().contains(search);

    return ageOk && distOk && locOk && onlineOk && lastActiveOk && searchOk;
  }).toList();

  filtered.sort((a, b) {
    switch (sort) {
      case DiscoverSort.onlineFirst:
        if (a.onlineNow != b.onlineNow) return a.onlineNow ? -1 : 1;
        return b.lastActiveAt.compareTo(a.lastActiveAt);

      case DiscoverSort.closest:
        // Null distances sort to the end
        final ad = a.distanceMiles;
        final bd = b.distanceMiles;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);

      case DiscoverSort.newestActive:
        return b.lastActiveAt.compareTo(a.lastActiveAt);
    }
  });

  return filtered;
});
