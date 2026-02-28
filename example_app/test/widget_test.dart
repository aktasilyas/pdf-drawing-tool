// Basic widget test for the ElyaNotes Drawing example app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/main.dart';

void main() {
  testWidgets('ElyaNotesApp renders DrawingScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: ElyaNotesApp(),
      ),
    );

    // Wait for all frames to settle
    await tester.pumpAndSettle();

    // Verify that DrawingScreen is rendered (MaterialApp exists)
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify Scaffold exists (from DrawingScreen)
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
