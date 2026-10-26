import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/editor_harness.dart';

/// Full-screen proof goldens for the editor chrome (#52, slice 16): the
/// whole DrawingScreen with the brief palette, rendered with the test font
/// so they are stable on CI.
void main() {
  late SharedPreferences prefs;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  void editorGolden(
    String name, {
    required Size size,
    Brightness brightness = Brightness.light,
    bool sidebarOpen = false,
    bool penPanelOpen = false,
  }) {
    testWidgets('editor chrome $name', (tester) async {
      await pumpEditor(
        tester,
        size: size,
        prefs: prefs,
        brightness: brightness,
        sidebarOpen: sidebarOpen,
        penPanelOpen: penPanelOpen,
      );
      await expectLater(
        find.byKey(kEditorBoundaryKey),
        matchesGoldenFile('goldens/ci/editor_chrome_$name.png'),
      );
    });
  }

  // Tablet landscape: sidebar docked and the pen popover open.
  editorGolden(
    'landscape_light',
    size: kEditorLandscape,
    sidebarOpen: true,
    penPanelOpen: true,
  );
  editorGolden(
    'landscape_dark',
    size: kEditorLandscape,
    brightness: Brightness.dark,
    sidebarOpen: true,
    penPanelOpen: true,
  );
  // Tablet portrait: medium toolbar with the sidebar docked.
  editorGolden('portrait_light', size: kEditorPortrait, sidebarOpen: true);
  // Phone: two-row chrome, drawer closed.
  editorGolden('phone_light', size: kEditorPhone);
  editorGolden(
    'phone_dark',
    size: kEditorPhone,
    brightness: Brightness.dark,
  );
}
