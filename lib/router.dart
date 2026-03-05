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

// ✅ Billing (Paywall + Stripe redirect pages)
import 'features/billing/upgrade_paywall_page.dart';
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

      // ✅ Billing routes
      final goingToUpgrade = isRoute(state, '/upgrade'); // optional alias
      final goingToBilling = isRoute(state, '/billing'); // main in-app billing
      final goingToUpgradeSuccess = isRoute(state, '/upgrade/success');
      final goingToUpgradeCancel = isRoute(state, '/upgrade/cancel');

      // 🚨 Never block auth callback (Supabase PKCE needs this route)
      if (goingToAuthCallback) return null;

      // 🚨 Always allow reset-password page (recovery flow)
      if (goingToReset) return null;

      // ✅ Always allow Stripe success/cancel pages (avoid redirect loops)
      if (goingToUpgradeSuccess || goingToUpgradeCancel) return null;

      // --- LOGGED OUT ---
      if (!loggedIn) {
        // Block onboarding if logged out
        if (goingToOnboarding) return '/login';

        // If user tries billing/upgrade while logged out, send to login
        if (goingToBilling || goingToUpgrade) return '/login';

        final allowed =
            goingToWelcome || goingToLogin || goingToRegister || goingToForgot;

        if (!allowed) return '/welcome';
        return null;
      }

      // --- LOGGED IN ---
      // 1) Force onboarding until completed
      if (!onboardingDone) {
        if (goingToForgot || goingToReset || goingToAuthCallback) return null;

        // Allow Stripe success/cancel even during onboarding
        if (goingToUpgradeSuccess || goingToUpgradeCancel) return null;

        // Optional: allow billing/upgrade during onboarding
        if (goingToBilling || goingToUpgrade) return null;

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
      GoRoute(
        path: '/auth-callback',
        redirect: (context, state) => '/reset-password',
      ),

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

      // Stripe redirect pages
      GoRoute(
        path: '/upgrade/success',
        builder: (context, state) => const UpgradeSuccessPage(),
      ),
      GoRoute(
        path: '/upgrade/cancel',
        builder: (context, state) => const UpgradeCancelPage(),
      ),

      // Optional alias route: /upgrade → same UI as /billing (paywall)
      GoRoute(
        path: '/upgrade',
        builder: (context, state) => const UpgradePaywallPage(),
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

          // ✅ AfroIntroductions-style Billing route (Paywall UI)
          GoRoute(
            path: '/billing',
            builder: (context, state) => const UpgradePaywallPage(),
          ),
        ],
      ),
    ],
  );
});
