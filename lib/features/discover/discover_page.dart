// lib/features/discover/discover_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'models/filters.dart';
import 'models/profile.dart';

import 'providers/discover_providers.dart';
import 'providers/discover_ui_providers.dart';
import 'providers/likes_providers.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(filteredProfilesProvider); // List<Profile>
    final filters = ref.watch(discoverFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            tooltip: 'Matches',
            icon: const Icon(Icons.favorite),
            onPressed: () => context.go('/matches'),
          ),
          PopupMenuButton<DiscoverSort>(
            tooltip: 'Sort',
            onSelected: (v) {
              ref.read(discoverSortProvider.notifier).set(v);
              ref.read(discoverLimitProvider.notifier).reset();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: DiscoverSort.onlineFirst,
                child: Text('Online first'),
              ),
              PopupMenuItem(
                value: DiscoverSort.closest,
                child: Text('Closest'),
              ),
              PopupMenuItem(
                value: DiscoverSort.newestActive,
                child: Text('Newest active'),
              ),
            ],
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            tooltip: 'Filters',
            icon: const Icon(Icons.tune),
            onPressed: () => _openFilters(context),
          ),
        ],
      ),
      body: Column(
        children: [
          const _SearchBar(),
          _ActiveFiltersBar(filters: filters),
          Expanded(
            child: profiles.isEmpty
                ? const Center(
                    child: Text('No matches. Adjust your filters/search.'),
                  )
                : LayoutBuilder(
                    builder: (context, c) {
                      final w = c.maxWidth;
                      final crossAxisCount = w >= 900 ? 4 : (w >= 600 ? 3 : 2);

                      return NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n.metrics.pixels >=
                              n.metrics.maxScrollExtent - 240) {
                            ref
                                .read(discoverLimitProvider.notifier)
                                .loadMore(step: 20);
                          }
                          return false;
                        },
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                          itemCount: profiles.length,
                          itemBuilder: (context, i) => _ProfileCard(
                            profile: profiles[i],
                            onTap: () =>
                                context.go('/profile/${profiles[i].id}'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _FiltersSheet(),
    );
  }
}

class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final search = ref.read(discoverSearchProvider);
    _controller = TextEditingController(text: search);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search name or location',
          border: OutlineInputBorder(),
        ),
        onChanged: (v) {
          ref.read(discoverSearchProvider.notifier).set(v);
          ref.read(discoverLimitProvider.notifier).reset();
        },
      ),
    );
  }
}

class _ActiveFiltersBar extends StatelessWidget {
  final DiscoverFilters filters;
  const _ActiveFiltersBar({required this.filters});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      Chip(label: Text('Age ${filters.minAge}-${filters.maxAge}')),
      Chip(label: Text('≤ ${filters.maxDistanceMiles.toStringAsFixed(0)} mi')),
      if (filters.locationQuery.trim().isNotEmpty)
        Chip(label: Text(filters.locationQuery.trim())),
      if (filters.onlineNowOnly) const Chip(label: Text('Online now')),
      if (filters.lastActiveWithinHours != 0)
        Chip(label: Text('Active ≤ ${filters.lastActiveWithinHours}h')),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Wrap(spacing: 8, runSpacing: 6, children: chips),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  final Profile profile;
  final VoidCallback onTap;
  const _ProfileCard({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In your current likes_providers.dart, these return bool (not AsyncValue)
    final isLiked = ref.watch(isLikedProvider(profile.id));
    final isMatched = ref.watch(isMatchedProvider(profile.id));

    final distanceLabel = profile.distanceMiles == null
        ? 'Distance unknown'
        : '${profile.distanceMiles!.toStringAsFixed(1)} mi';

    return Material(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(16),
      elevation: 1.5,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    profile.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(Icons.person, size: 56),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _OnlineBadge(isOnline: profile.onlineNow),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: isLiked ? 'Unlike' : 'Like',
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.white,
                          ),
                          onPressed: () async {
                            await ref
                                .read(likeActionsProvider)
                                .toggle(profile.id);
                          },
                        ),
                        if (isMatched)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'MATCH',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${profile.name}, ${profile.age}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${profile.location} • $distanceLabel',
                    style: TextStyle(color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _lastActiveLabel(profile),
                    style: TextStyle(color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _lastActiveLabel(Profile p) {
    if (p.onlineNow) return 'Online now';
    final diff = DateTime.now().difference(p.lastActiveAt);
    if (diff.inMinutes < 60) return 'Active ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Active ${diff.inHours}h ago';
    return 'Active ${diff.inDays}d ago';
  }
}

class _OnlineBadge extends StatelessWidget {
  final bool isOnline;
  const _OnlineBadge({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline
            ? Colors.green.withOpacity(0.9)
            : Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOnline ? 'ONLINE' : 'OFFLINE',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _FiltersSheet extends ConsumerStatefulWidget {
  const _FiltersSheet();

  @override
  ConsumerState<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<_FiltersSheet> {
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(discoverFiltersProvider);
    _locationController = TextEditingController(text: filters.locationQuery);
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(discoverFiltersProvider);
    final controller = ref.read(discoverFiltersProvider.notifier);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 6,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            const Text(
              'Filters',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Text(
              'Age: ${filters.minAge} - ${filters.maxAge}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            RangeSlider(
              min: 18,
              max: 70,
              divisions: 52,
              values: RangeValues(
                filters.minAge.toDouble(),
                filters.maxAge.toDouble(),
              ),
              labels: RangeLabels('${filters.minAge}', '${filters.maxAge}'),
              onChanged: (v) {
                controller.setAgeRange(v.start.round(), v.end.round());
                ref.read(discoverLimitProvider.notifier).reset();
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Max distance: ${filters.maxDistanceMiles.toStringAsFixed(0)} mi',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              min: 5,
              max: 200,
              divisions: 39,
              value: filters.maxDistanceMiles,
              label: filters.maxDistanceMiles.toStringAsFixed(0),
              onChanged: (v) {
                controller.setMaxDistance(v);
                ref.read(discoverLimitProvider.notifier).reset();
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Location',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'City, state, or keyword',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                controller.setLocationQuery(v);
                ref.read(discoverLimitProvider.notifier).reset();
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Online now'),
              value: filters.onlineNowOnly,
              onChanged: (v) {
                controller.setOnlineNowOnly(v);
                ref.read(discoverLimitProvider.notifier).reset();
              },
            ),
            const SizedBox(height: 6),
            const Text(
              'Last active within',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _ChoiceChip(
                  label: 'Any',
                  selected: filters.lastActiveWithinHours == 0,
                  onTap: () {
                    controller.setLastActiveWithinHours(0);
                    ref.read(discoverLimitProvider.notifier).reset();
                  },
                ),
                _ChoiceChip(
                  label: '24h',
                  selected: filters.lastActiveWithinHours == 24,
                  onTap: () {
                    controller.setLastActiveWithinHours(24);
                    ref.read(discoverLimitProvider.notifier).reset();
                  },
                ),
                _ChoiceChip(
                  label: '72h',
                  selected: filters.lastActiveWithinHours == 72,
                  onTap: () {
                    controller.setLastActiveWithinHours(72);
                    ref.read(discoverLimitProvider.notifier).reset();
                  },
                ),
                _ChoiceChip(
                  label: '7d',
                  selected: filters.lastActiveWithinHours == 168,
                  onTap: () {
                    controller.setLastActiveWithinHours(168);
                    ref.read(discoverLimitProvider.notifier).reset();
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      controller.reset();
                      ref.read(discoverLimitProvider.notifier).reset();
                      _locationController.text = '';
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
