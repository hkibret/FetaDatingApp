// lib/router.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'router_refresh.dart';
import 'core/navigation/app_nav_key.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/auth/forgot_password_page.dart';
import 'features/auth/reset_password_page.dart';

import 'features/welcome/welcome_page.dart';

import 'shared/widgets/app_shell.dart';

import 'features/discover/discover_page.dart';
import 'features/matches/matches_page.dart';
import 'features/messages/messages_page.dart';
import 'features/messages/chat_page.dart';

import 'features/profile/profile_page.dart';
import 'features/profile/profile_detail_page.dart';
import 'features/profile/ui/edit_profile_page.dart';

import 'features/onboarding/onboarding_page.dart';

// ✅ Billing (Stripe upgrade flow)
import 'features/billing/upgrade_page.dart';
import 'features/billing/upgrade_success_page.dart';
import 'features/billing/upgrade_cancel_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(goRouterRefreshProvider);

  bool isRoute(GoRouterState state, String path) =>
      state.matchedLocation == path;

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/welcome',
    refreshListenable: refresh,
    debugLogDiagnostics: kIsWeb,

    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);

      final loggedIn = auth.isLoggedIn;
      final onboardingDone = auth.onboardingCompleted;

      // Current route flags
      final goingToAuthCallback = isRoute(state, '/auth-callback');
      final goingToReset = isRoute(state, '/reset-password');

      final goingToWelcome = isRoute(state, '/welcome');
      final goingToLogin = isRoute(state, '/login');
      final goingToRegister = isRoute(state, '/register');
      final goingToForgot = isRoute(state, '/forgot-password');
      final goingToOnboarding = isRoute(state, '/onboarding');

      // ✅ Billing routes (Stripe redirect pages)
      final goingToUpgrade = isRoute(state, '/upgrade');
      final goingToUpgradeSuccess = isRoute(state, '/upgrade/success');
      final goingToUpgradeCancel = isRoute(state, '/upgrade/cancel');

      // 🚨 Never block auth callback (Supabase PKCE needs this route)
      if (goingToAuthCallback) return null;

      // 🚨 Always allow reset-password page (recovery flow)
      if (goingToReset) return null;

      // ✅ Always allow Stripe success/cancel pages (even if logged out)
      // This prevents redirect loops if the user returns from Stripe and session isn't loaded yet.
      if (goingToUpgradeSuccess || goingToUpgradeCancel) return null;

      // --- LOGGED OUT ---
      if (!loggedIn) {
        // ✅ Block onboarding if logged out (prevents "Not logged in" on submit)
        if (goingToOnboarding) return '/login';

        // ✅ Allow Upgrade page if logged out? (optional)
        // Typically you want login first before checkout so we can attach user_id in metadata.
        if (goingToUpgrade) return '/login';

        final allowed =
            goingToWelcome || goingToLogin || goingToRegister || goingToForgot;

        if (!allowed) return '/welcome';
        return null;
      }

      // --- LOGGED IN ---
      // 1) Force onboarding until completed
      if (!onboardingDone) {
        // Allow forgot/reset pages even if logged in (safe)
        if (goingToForgot || goingToReset || goingToAuthCallback) return null;

        // ✅ Allow Stripe success/cancel even during onboarding
        if (goingToUpgradeSuccess || goingToUpgradeCancel) return null;

        // Optional: allow Upgrade page during onboarding (usually fine)
        if (goingToUpgrade) return null;

        if (!goingToOnboarding) return '/onboarding';
        return null;
      }

      // 2) Onboarding done: keep them out of onboarding/auth landing
      if (onboardingDone) {
        if (goingToOnboarding) return '/discover';
        if (goingToWelcome || goingToLogin || goingToRegister) {
          return '/discover';
        }
      }

      return null;
    },

    routes: [
      // ✅ Required for Supabase PKCE (code exchange lands here depending on config)
      GoRoute(
        path: '/auth-callback',
        redirect: (context, state) => '/reset-password',
      ),

      // Welcome (logged-out landing)
      GoRoute(
        path: '/welcome',
        builder: (context, state) => WelcomePage(
          onLogin: () => context.go('/login'),
          onCta: () => context.go('/register'),
        ),
      ),

      // Auth
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordPage(),
      ),

      // ✅ Billing (Stripe)
      GoRoute(
        path: '/upgrade',
        builder: (context, state) => const UpgradePage(),
      ),
      GoRoute(
        path: '/upgrade/success',
        builder: (context, state) => const UpgradeSuccessPage(),
      ),
      GoRoute(
        path: '/upgrade/cancel',
        builder: (context, state) => const UpgradeCancelPage(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // Main app shell
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
            builder: (context, state) =>
                ChatPage(otherUserId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/profile/edit',
            builder: (context, state) => const EditProfilePage(),
          ),
          GoRoute(
            path: '/profile/:id',
            builder: (context, state) =>
                ProfileDetailPage(profileId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});
