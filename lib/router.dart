import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'router_refresh.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';

import 'shared/widgets/app_shell.dart';

import 'features/discover/discover_page.dart';
import 'features/matches/matches_page.dart';
import 'features/messages/messages_page.dart';
import 'features/messages/chat_page.dart';
import 'features/profile/profile_page.dart';
import 'features/profile/profile_detail_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Re-check redirects when auth changes.
  final refresh = ref.watch(goRouterRefreshProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,

    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loggedIn = auth.isLoggedIn;

      final location = state.uri.toString();
      final goingToLogin = location == '/login';
      final goingToRegister = location == '/register';

      // Not logged in → force auth pages
      if (!loggedIn && !(goingToLogin || goingToRegister)) {
        return '/login';
      }

      // Logged in → block auth pages
      if (loggedIn && (goingToLogin || goingToRegister)) {
        return '/discover';
      }

      return null;
    },

    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),

      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/discover',
            builder: (context, state) => const DiscoverPage(),
          ),
          GoRoute(
            path: '/matches',
            builder: (context, state) => const MatchesPage(),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const MessagesPage(),
          ),
          GoRoute(
            path: '/chat/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ChatPage(otherUserId: id);
            },
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/profile/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ProfileDetailPage(profileId: id);
            },
          ),
        ],
      ),
    ],
  );
});
