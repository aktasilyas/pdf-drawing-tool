import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chrome_theme.dart';
import 'sidebar_fixture.dart';

/// The three editor sizes from the chrome spec (#52, section 9).
const Size kEditorLandscape = Size(1180, 820);
const Size kEditorPortrait = Size(820, 1180);
const Size kEditorPhone = Size(390, 844);

/// Wraps the whole app so a golden captures overlays (popover) too.
const Key kEditorBoundaryKey = ValueKey('editor-harness');

/// Pumps the full [DrawingScreen] at [size] with the brief palette, five
/// pages (page 3 bookmarked) and pre-filled sidebar thumbnails.
///
/// [sidebarOpen] opens the page sidebar before the first frame, so it shows
/// without animating in. [penPanelOpen] opens the ballpoint settings popover
/// after the first frame, the way a tap on the selected pen does.
Future<ProviderContainer> pumpEditor(
  WidgetTester tester, {
  required Size size,
  required SharedPreferences prefs,
  Brightness brightness = Brightness.light,
  bool sidebarOpen = false,
  bool penPanelOpen = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

  final pages = sidebarPages(5, bookmarked: const {2});
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      // v1.0 configuration: audio recording is frozen.
      audioRecordingEnabledProvider.overrideWithValue(false),
    ],
  );
  container.read(pageManagerProvider.notifier).initializeFromDocument(pages);
  container.read(sidebarOpenProvider.notifier).state = sidebarOpen;

  await tester.pumpWidget(
    RepaintBoundary(
      key: kEditorBoundaryKey,
      child: UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: chromeTheme(brightness),
          home: DrawingScreen(
            documentTitle: 'Matematik notlari',
            thumbnailCache: sidebarCache(pages),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));

  if (penPanelOpen) {
    container.read(activePanelProvider.notifier).state = ToolType.ballpointPen;
    await tester.pump();
    // Post-frame show, then the 200ms enter animation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }
  return container;
}
