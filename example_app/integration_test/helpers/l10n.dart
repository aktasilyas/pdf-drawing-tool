import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/l10n/l10n.dart';

/// Localized strings of the running app, so robots match on the same copy the
/// UI shows in whatever locale the emulator uses.
extension AppL10nTester on WidgetTester {
  /// Call only once a screen with a [Scaffold] is visible (for example after
  /// the library has loaded); throws before the first `Scaffold` exists.
  AppLocalizations get l10n =>
      AppLocalizations.of(element(find.byType(Scaffold).first));
}
