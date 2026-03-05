// lib/shared/widgets/app_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _indexForLocation(String location) {
    if (location.startsWith('/discover')) return 0;
    if (location.startsWith('/matches')) return 1;
    if (location.startsWith('/messages') || location.startsWith('/chat')) {
      return 2;
    }

    // ✅ Treat billing as part of Profile tab
    if (location.startsWith('/profile') || location.startsWith('/billing')) {
      return 3;
    }

    return 0;
  }

  String _locationForIndex(int index) {
    switch (index) {
      case 1:
        return '/matches';
      case 2:
        return '/messages';
      case 3:
        return '/profile';
      default:
        return '/discover';
    }
  }

  bool _hideBottomNav(String location) {
    // Hide bottom nav on "detail" / "fullscreen" pages
    if (location.startsWith('/chat/')) return true;

    // Profile detail pages like /profile/:id (but not /profile itself)
    if (location.startsWith('/profile/') && location != '/profile') return true;

    // Optional: hide on edit profile
    if (location == '/profile/edit') return true;

    // ✅ Keep nav visible on /billing (so it feels like an in-app settings screen)
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Safer than GoRouterState.of(context) across versions
    final router = GoRouter.of(context);
    final location = router.routeInformationProvider.value.uri.toString();

    final index = _indexForLocation(location);
    final hideNav = _hideBottomNav(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: hideNav
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) {
                final target = _locationForIndex(i);
                if (target != location) context.go(target);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.explore),
                  label: 'Discover',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite),
                  label: 'Matches',
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline),
                  label: 'Messages',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }
}
