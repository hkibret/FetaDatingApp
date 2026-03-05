// lib/router.dart
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

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

      // 🚨 Never block auth callback (Supabase recovery / PKCE needs this route)
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
        // Allow auth recovery flows even if onboarding isn't completed
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
        builder: (context, state) => const AuthCallbackPage(),
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
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ProfileDetailPage(profileId: id);
            },
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

/// Handles Supabase email redirects (PKCE / recovery / magic link).
/// Whitelist in Supabase:
/// - Site URL: https://feta-dating-app.vercel.app
/// - Additional Redirect URLs:
///   https://feta-dating-app.vercel.app/auth-callback
///   https://feta-dating-app.vercel.app/*
class AuthCallbackPage extends ConsumerStatefulWidget {
  const AuthCallbackPage({super.key});

  @override
  ConsumerState<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends ConsumerState<AuthCallbackPage> {
  StreamSubscription<supabase.AuthState>? _authSub;
  bool _navigated = false;

  supabase.SupabaseClient get _sb => supabase.Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    _authSub = _sb.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      if (event == supabase.AuthChangeEvent.passwordRecovery) {
        _goOnce('/reset-password');
        return;
      }

      if (event == supabase.AuthChangeEvent.signedIn ||
          event == supabase.AuthChangeEvent.tokenRefreshed) {
        final url = Uri.base.toString();
        final looksLikeRecovery =
            url.contains('type=recovery') ||
            url.contains('code=') ||
            url.contains('access_token=') ||
            url.contains('refresh_token=');

        if (looksLikeRecovery) {
          _goOnce('/reset-password');
        }
      }
    });

    unawaited(_resolveCallback());
  }

  Future<void> _resolveCallback() async {
    try {
      debugPrint('AUTH CALLBACK URL => ${Uri.base}');

      // Give Supabase a short moment to process URL tokens/code automatically.
      for (var i = 0; i < 30; i++) {
        if (_sb.auth.currentSession != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }

      if (!mounted || _navigated) return;

      final session = _sb.auth.currentSession;
      final auth = ref.read(authControllerProvider);
      final url = Uri.base.toString();

      final looksLikeRecovery =
          url.contains('type=recovery') ||
          url.contains('code=') ||
          url.contains('access_token=') ||
          url.contains('refresh_token=');

      if (looksLikeRecovery) {
        _goOnce('/reset-password');
        return;
      }

      if (session != null) {
        _goOnce(auth.onboardingCompleted ? '/discover' : '/onboarding');
        return;
      }

      _goOnce('/login');
    } catch (e) {
      debugPrint('AUTH CALLBACK resolve error: $e');
      if (!mounted) return;
      _goOnce('/login');
    }
  }

  void _goOnce(String route) {
    if (!mounted || _navigated) return;
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(route);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = Uri.base.toString();
    final looksLikeRecovery =
        url.contains('type=recovery') ||
        url.contains('code=') ||
        url.contains('access_token=') ||
        url.contains('refresh_token=');

    return Scaffold(
      appBar: AppBar(title: const Text('Signing you in')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                looksLikeRecovery
                    ? 'Processing password reset link…'
                    : 'Processing authentication…',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please wait a moment. You will be redirected automatically.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
