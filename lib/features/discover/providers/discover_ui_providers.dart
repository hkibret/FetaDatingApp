// lib/features/discover/providers/discover_ui_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sorting modes for the Discover results list/grid.
enum DiscoverSort { onlineFirst, closest, newestActive }

/// ------------------------------
/// Search query (UI state)
/// ------------------------------
final discoverSearchProvider = NotifierProvider<DiscoverSearchNotifier, String>(
  DiscoverSearchNotifier.new,
);

class DiscoverSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
  void clear() => state = '';
}

/// ------------------------------
/// Sort selection (UI state)
/// ------------------------------
final discoverSortProvider =
    NotifierProvider<DiscoverSortNotifier, DiscoverSort>(
      DiscoverSortNotifier.new,
    );

class DiscoverSortNotifier extends Notifier<DiscoverSort> {
  @override
  DiscoverSort build() => DiscoverSort.onlineFirst;

  void set(DiscoverSort value) => state = value;
}

/// ------------------------------
/// Pagination limit (UI state)
/// ------------------------------
final discoverLimitProvider = NotifierProvider<DiscoverLimitNotifier, int>(
  DiscoverLimitNotifier.new,
);

class DiscoverLimitNotifier extends Notifier<int> {
  @override
  int build() => 20;

  void reset() => state = 20;
  void loadMore({int step = 20}) => state = state + step;
}
