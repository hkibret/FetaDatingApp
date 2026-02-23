// This is a basic Flutter widget test.
//
// Widget tests verify that a widget builds correctly and responds
// to user interaction. They run faster than integration tests
// and do not require a real device or emulator.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import the root application widget directly.
// We intentionally do NOT import main.dart so tests
// can fully control the widget tree.
import 'package:feta_dating/app.dart';

void main() {
  testWidgets('Feta Dating app builds without crashing', (
    WidgetTester tester,
  ) async {
    // Build the widget tree exactly as production:
    // ProviderScope → MyApp
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Allow all frames, animations, and async work to complete
    await tester.pumpAndSettle();

    // Sanity check:
    // Confirms the app root (MaterialApp) was created successfully.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Optional additional check:
    // Confirms the placeholder home text exists.
    expect(find.text('Feta Dating App'), findsOneWidget);
  });
}
