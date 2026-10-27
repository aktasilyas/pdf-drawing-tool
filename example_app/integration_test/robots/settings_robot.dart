import 'package:drawing_ui/drawing_ui.dart' show CanvasDarkMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/features/settings/settings.dart';

import '../helpers/l10n.dart';
import '../helpers/pump_helpers.dart';

/// Page object for the Settings screen (all feature flags off).
///
/// Entries are found by their icons, not their labels, so the robot keeps
/// working once the screen is localized (the emulator locale may be en-US).
class SettingsRobot {
  SettingsRobot(this.tester);

  final WidgetTester tester;

  static const _appThemeIcon = Icons.palette_outlined;
  static const _pinFavoritesIcon = Icons.star_outline;
  static const _crashReportsIcon = Icons.bug_report_outlined;
  static const _versionIcon = Icons.info_outline;
  static const _privacyIcon = Icons.privacy_tip_outlined;
  static const _licensesIcon = Icons.description_outlined;
  static const _feedbackIcon = Icons.mail_outline;

  static const _canvasIcons = {
    CanvasDarkMode.off: Icons.light_mode_outlined,
    CanvasDarkMode.on: Icons.dark_mode_outlined,
    CanvasDarkMode.followSystem: Icons.settings_suggest_outlined,
  };

  Finder get screen => find.byType(SettingsScreen);

  Finder _tile(IconData icon) => find.ancestor(
        of: find.byIcon(icon),
        matching: find.byType(SettingsTile),
      );

  Finder _switch(IconData icon) =>
      find.descendant(of: _tile(icon), matching: find.byType(Switch));

  Finder get _canvasSegments => find.descendant(
        of: find.byType(CanvasThemeSetting),
        matching: find.byType(SegmentedButton<CanvasDarkMode>),
      );

  /// Library header gear button ("Settings").
  Future<void> open() async {
    await tester.tapAndWait(find.byTooltip(tester.l10n.settingsTitle));
    await tester.pumpUntilFound(screen);
  }

  /// Header close button (scrolled back into view); back to the library.
  Future<void> close() async {
    final button = find.descendant(
      of: find.byType(SettingsHeader),
      matching: find.byIcon(Icons.close),
    );
    await _reveal(button, up: true);
    await tester.tapAndWait(button);
    await tester.pumpUntilGone(screen);
  }

  /// Scrolls the settings list (down, or [up]) until [finder] is built and
  /// on screen.
  Future<void> _reveal(Finder finder, {bool up = false}) async {
    await tester.scrollUntilVisible(
      finder,
      up ? -200 : 200,
      scrollable: find
          .descendant(of: screen, matching: find.byType(Scrollable))
          .first,
    );
    await tester.pumpFor(const Duration(milliseconds: 300));
  }

  /// Theme of the settings screen as currently rendered.
  Brightness get brightness => Theme.of(tester.element(screen)).brightness;

  /// "Tema" > the option of [mode] in the dialog (light, dark, system).
  Future<void> setAppTheme(AppThemeMode mode) async {
    await _reveal(_tile(_appThemeIcon));
    await tester.tapAndWait(_tile(_appThemeIcon));
    final dialog = find.byType(AlertDialog);
    await tester.pumpUntilFound(dialog);
    final options =
        find.descendant(of: dialog, matching: find.byType(ListTile));
    await tester.tapAndWait(options.at(AppThemeMode.values.indexOf(mode)));
    await tester.pumpUntilGone(dialog);
  }

  CanvasDarkMode get canvasMode => tester
      .widget<SegmentedButton<CanvasDarkMode>>(_canvasSegments)
      .selected
      .single;

  /// "Canvas Teması" segment of [mode]. The selected segment shows a check
  /// mark instead of its icon, so only an unselected one can be tapped.
  Future<void> setCanvasMode(CanvasDarkMode mode) async {
    await _reveal(_canvasSegments);
    if (canvasMode == mode) return;
    await tester.tapAndWait(find.descendant(
      of: _canvasSegments,
      matching: find.byIcon(_canvasIcons[mode]!),
    ));
    await tester.pumpUntilTrue(
      () => canvasMode == mode,
      reason: 'canvas theme still $canvasMode, expected $mode',
    );
  }

  bool get pinFavorites =>
      tester.widget<Switch>(_switch(_pinFavoritesIcon)).value;

  bool get crashReports =>
      tester.widget<Switch>(_switch(_crashReportsIcon)).value;

  Future<void> setPinFavorites(bool value) =>
      _setSwitch(_pinFavoritesIcon, value, () => pinFavorites);

  Future<void> setCrashReports(bool value) =>
      _setSwitch(_crashReportsIcon, value, () => crashReports);

  Future<void> _setSwitch(
    IconData icon,
    bool value,
    bool Function() current,
  ) async {
    await _reveal(_switch(icon));
    if (current() == value) return;
    await tester.tapAndWait(_switch(icon));
    await tester.pumpUntilTrue(
      () => current() == value,
      reason: 'switch $icon still ${current()}',
    );
  }

  /// "Sürüm" row is shown.
  Future<void> expectVersionRow() async {
    await _reveal(_tile(_versionIcon));
    expect(_tile(_versionIcon), findsOneWidget);
  }

  /// "Gizlilik politikası" opens the in-app policy; system back returns.
  Future<void> openAndClosePrivacyPolicy() async {
    await _openAndGoBack(_privacyIcon, find.byType(PrivacyPolicyScreen));
  }

  /// "Açık kaynak lisansları" opens Flutter's licence page.
  Future<void> openAndCloseLicenses() async {
    await _openAndGoBack(_licensesIcon, find.byType(LicensePage));
  }

  Future<void> _openAndGoBack(IconData icon, Finder page) async {
    await _reveal(_tile(icon));
    await tester.tapAndWait(_tile(icon));
    await tester.pumpUntilFound(page);
    // Android back button.
    await tester.binding.handlePopRoute();
    await tester.pumpUntilGone(page);
    await tester.pumpFor(const Duration(milliseconds: 300));
  }

  /// "Geri bildirim gönder" copies the contact address; returns what the
  /// clipboard holds afterwards.
  Future<String?> copyFeedbackAddress() async {
    await Clipboard.setData(const ClipboardData(text: ''));
    await _reveal(_tile(_feedbackIcon));
    await tester.tapAndWait(_tile(_feedbackIcon));
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }
}
