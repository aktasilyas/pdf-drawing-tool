import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_helpers.dart';

/// Page object for the editor screen (drawing_ui toolbar chrome).
class EditorRobot {
  EditorRobot(this.tester);

  final WidgetTester tester;

  /// Home button of the phone, medium and full toolbar layouts.
  Finder get _homeButton => find.byTooltip('Ana Sayfa');

  /// Waits until the editor chrome is on screen.
  Future<void> waitForEditor() async {
    await tester.pumpUntilFound(
      _homeButton,
      timeout: const Duration(seconds: 30),
    );
  }

  /// Taps the home button; the editor saves and routes to `/documents`.
  Future<void> goHome() async {
    await tester.tapAndWait(_homeButton);
  }
}
