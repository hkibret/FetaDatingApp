// lib/features/discover/models/filters.dart
class DiscoverFilters {
  final int minAge;
  final int maxAge;
  final double maxDistanceMiles;
  final String locationQuery;
  final bool onlineNowOnly;
  final int lastActiveWithinHours; // 0 = any

  const DiscoverFilters({
    required this.minAge,
    required this.maxAge,
    required this.maxDistanceMiles,
    required this.locationQuery,
    required this.onlineNowOnly,
    required this.lastActiveWithinHours,
  });

  const DiscoverFilters.defaults()
    : minAge = 18,
      maxAge = 45,
      maxDistanceMiles = 50,
      locationQuery = "",
      onlineNowOnly = false,
      lastActiveWithinHours = 0;

  DiscoverFilters copyWith({
    int? minAge,
    int? maxAge,
    double? maxDistanceMiles,
    String? locationQuery,
    bool? onlineNowOnly,
    int? lastActiveWithinHours,
  }) {
    return DiscoverFilters(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistanceMiles: maxDistanceMiles ?? this.maxDistanceMiles,
      locationQuery: locationQuery ?? this.locationQuery,
      onlineNowOnly: onlineNowOnly ?? this.onlineNowOnly,
      lastActiveWithinHours:
          lastActiveWithinHours ?? this.lastActiveWithinHours,
    );
  }
}
