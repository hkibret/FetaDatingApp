import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Feta',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.pink),
      builder: (context, child) {
        // Optional: keep UI from blowing up on extreme text scaling.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.2,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
