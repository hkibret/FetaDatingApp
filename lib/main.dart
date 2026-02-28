import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/storage/hive_service.dart';
import 'core/navigation/app_nav_key.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Initialize local storage (Hive)
  await HiveService.init();

  // 2) Read Supabase config from --dart-define
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || !supabaseUrl.startsWith('http')) {
    throw Exception('Missing/invalid SUPABASE_URL. Pass it via --dart-define.');
  }
  if (supabaseAnonKey.isEmpty) {
    throw Exception('Missing SUPABASE_ANON_KEY. Pass it via --dart-define.');
  }

  // 3) Initialize Supabase (PKCE recommended for web)
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Helper: navigate to reset page reliably (router may not be ready immediately).
  Future<void> goResetPassword() async {
    for (var i = 0; i < 25; i++) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        GoRouter.of(ctx).go('/reset-password');
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  // 4) Listen for password recovery
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(goResetPassword());
      });
    }
  });

  // 5) Run app
  runApp(const ProviderScope(child: MyApp()));

  // 6) Cold-start safety (WEB):
  // Only redirect if THIS load includes recovery params in the URL.
  unawaited(_coldStartRecoveryCheck(goResetPassword));
}

Future<void> _coldStartRecoveryCheck(Future<void> Function() goReset) async {
  // Only meaningful on web (mobile deep links need separate setup).
  if (!kIsWeb) return;

  // Let Supabase parse URL tokens (esp. on cold start).
  await Future<void>.delayed(const Duration(milliseconds: 300));

  final uri = Uri.base; // web current URL
  final full = uri.toString();

  bool containsAny(String s, List<String> needles) =>
      needles.any((n) => s.contains(n));

  // Detect recovery link params (query or fragment)
  final isRecoveryLink =
      containsAny(full, [
        'type=recovery',
        'code=',
        'access_token=',
        'refresh_token=',
      ]) ||
      containsAny(uri.fragment, [
        'type=recovery',
        'access_token=',
        'refresh_token=',
      ]) ||
      containsAny(uri.query, ['type=recovery', 'code=']);

  if (!isRecoveryLink) return;

  // If we got here from a recovery link, route to reset page.
  await goReset();
}

// Convenience client
final supabase = Supabase.instance.client;
