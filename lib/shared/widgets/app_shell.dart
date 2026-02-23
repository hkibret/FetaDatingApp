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
    if (location.startsWith('/profile')) return 3;
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
    // If you want profile detail to be fullscreen too
    if (location.startsWith('/profile/') && location != '/profile') return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexForLocation(location);
    final hideNav = _hideBottomNav(location);

    return Scaffold(
      // Optional: If each page has its own AppBar, remove this AppBar.
      // appBar: AppBar(title: const Text('Feta')),
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
