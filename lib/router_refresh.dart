import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_controller.dart';

/// A ValueNotifier that bumps whenever auth-relevant state changes.
/// GoRouter listens to this and re-runs redirect logic on login/logout.
final goRouterRefreshProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier<int>(0);

  ref.listen<AuthState>(authControllerProvider, (prev, next) {
    final prevLoggedIn = prev?.isLoggedIn ?? false;
    final nextLoggedIn = next.isLoggedIn;

    final prevUserId = prev?.userId;
    final nextUserId = next.userId;

    // Only refresh router when login state (or user identity) changes.
    if (prevLoggedIn != nextLoggedIn || prevUserId != nextUserId) {
      notifier.value++;
    }
  });

  ref.onDispose(notifier.dispose);
  return notifier;
});
