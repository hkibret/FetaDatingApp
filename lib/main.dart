// lib/main.dart
import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/navigation/app_nav_key.dart';
import 'core/storage/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Initialize local storage (Hive)
  await HiveService.init();

  // 2) Read Supabase config from --dart-define
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || !supabaseUrl.startsWith('http')) {
    throw Exception(
      'Missing/invalid SUPABASE_URL.\n'
      'Run with:\n'
      '  --dart-define=SUPABASE_URL=https://<ref>.supabase.co',
    );
  }

  if (supabaseAnonKey.isEmpty) {
    throw Exception(
      'Missing SUPABASE_ANON_KEY.\n'
      'Run with:\n'
      '  --dart-define=SUPABASE_ANON_KEY=<your anon key>',
    );
  }

  if (kDebugMode) {
    debugPrint('SUPABASE_URL from env => $supabaseUrl');
    debugPrint('SUPABASE_ANON_KEY length => ${supabaseAnonKey.length}');
    debugPrint('WEB origin => ${kIsWeb ? Uri.base.origin : "(not web)"}');
  }

  // 3) Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: kDebugMode,
  );

  final supabase = Supabase.instance.client;

  if (kDebugMode) {
    debugPrint('Supabase initialized ✅');
    debugPrint('STARTUP current user => ${supabase.auth.currentUser?.id}');
    debugPrint(
      'STARTUP session exists => ${supabase.auth.currentSession != null}',
    );
    debugPrint(
      'STARTUP token length => ${supabase.auth.currentSession?.accessToken.length ?? 0}',
    );
  }

  // Helper: navigate to reset page reliably (router may not be ready immediately).
  Future<void> goResetPassword() async {
    for (var i = 0; i < 40; i++) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        GoRouter.of(ctx).go('/reset-password');
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    if (kDebugMode) {
      debugPrint('goResetPassword: router context was not ready in time');
    }
  }

  // 4) Listen for auth changes
  supabase.auth.onAuthStateChange.listen((data) {
    if (kDebugMode) {
      debugPrint(
        'Auth event: ${data.event} | session? ${data.session != null}',
      );
      debugPrint('Auth user => ${data.session?.user.id}');
      debugPrint(
        'Auth token length => ${data.session?.accessToken.length ?? 0}',
      );
    }

    if (data.event == AuthChangeEvent.passwordRecovery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(goResetPassword());
      });
    }
  });

  // 5) Run app
  runApp(const ProviderScope(child: MyApp()));

  // 6) Cold-start safety (WEB)
  unawaited(_coldStartRecoveryCheck(goResetPassword));
}

Future<void> _coldStartRecoveryCheck(Future<void> Function() goReset) async {
  if (!kIsWeb) return;

  // Let Supabase parse URL tokens on cold start.
  await Future<void>.delayed(const Duration(milliseconds: 350));

  final uri = Uri.base;
  final full = uri.toString();

  bool containsAny(String s, List<String> needles) =>
      needles.any((n) => s.contains(n));

  final isRecoveryLink =
      containsAny(full, const [
        'type=recovery',
        'code=',
        'access_token=',
        'refresh_token=',
      ]) ||
      containsAny(uri.fragment, const [
        'type=recovery',
        'access_token=',
        'refresh_token=',
      ]) ||
      containsAny(uri.query, const ['type=recovery', 'code=']);

  if (!isRecoveryLink) return;

  if (kDebugMode) {
    debugPrint('Cold-start recovery link detected => $full');
  }

  await goReset();
}
