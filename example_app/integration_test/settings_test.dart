import 'package:drawing_core/drawing_core.dart'
    show BackgroundType, CoverRegistry, TemplateRegistry;
import 'package:drawing_ui/drawing_ui.dart'
    show
        CanvasColorScheme,
        CanvasDarkMode,
        canvasColorSchemeProvider,
        documentProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/constants/storage_keys.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/screens/documents_screen.dart';
import 'package:example_app/features/settings/settings.dart';

import 'helpers/app_harness.dart';
import 'helpers/expectations.dart';
import 'helpers/pump_helpers.dart';
import 'robots/editor_robot.dart';
import 'robots/library_robot.dart';
import 'robots/new_notebook_robot.dart';
import 'robots/settings_robot.dart';

/// Every Settings entry shown with all flags off (audited in #190/#199):
/// it takes visible effect and persists across a relaunch (`relaunchApp`,
/// see persistence_test.dart). Then the dark theme in library and editor.
void main() {
  initE2E();

  testWidgets(
    'settings: every entry takes effect and persists across a relaunch',
    (tester) async {
      await launchApp(tester);
      final library = LibraryRobot(tester);
      final settings = SettingsRobot(tester);
      await library.waitForLibrary();

      // Two notebooks: "Alfa" is a favourite, "Beta" is newer, so by date
      // Beta comes first unless favourites are pinned.
      await _createQuietly(tester, 'Alfa');
      await library.waitListed('Alfa');
      await library.addToFavorites('Alfa');
      await tester.pumpFor(const Duration(seconds: 1));
      await _createQuietly(tester, 'Beta');
      await library.waitListed('Beta');
      _expectFirst(tester, library, 'Beta', 'Alfa');

      await settings.open();
      expect(settings.canvasMode, CanvasDarkMode.off);
      expect(settings.pinFavorites, isFalse);
      expect(settings.crashReports, isTrue);

      // App theme: dark right away.
      await settings.setAppTheme(AppThemeMode.dark);
      await tester.pumpUntilTrue(
        () => settings.brightness == Brightness.dark,
        reason: 'app theme did not switch to dark',
      );

      // Canvas theme, pinned favourites, crash reports.
      await settings.setCanvasMode(CanvasDarkMode.on);
      await settings.setPinFavorites(true);
      await settings.setCrashReports(false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(StorageKeys.crashReportingEnabled), isFalse);

      // About: version row, policy, licences, feedback address.
      await settings.expectVersionRow();
      await settings.openAndClosePrivacyPolicy();
      await settings.openAndCloseLicenses();
      expect(await settings.copyFeedbackAddress(), AppAboutInfo.contactEmail);

      // Pinned favourites reorder the library.
      await settings.close();
      await library.waitForLibrary();
      _expectFirst(tester, library, 'Alfa', 'Beta');

      // Kill and reopen: every value is read back from storage.
      await relaunchApp(tester);
      await library.waitForLibrary();
      await library.waitListed('Beta');
      await library.waitListed('Alfa');
      expect(_brightnessOf(tester, find.byType(DocumentsScreen)),
          Brightness.dark);
      await tester.pumpUntilTrue(
        () => _isFirst(tester, library, 'Alfa', 'Beta'),
        reason: 'pinned favourite not first after relaunch',
      );
      await settings.open();
      expect(settings.brightness, Brightness.dark);
      expect(settings.canvasMode, CanvasDarkMode.on);
      expect(settings.pinFavorites, isTrue);
      expect(settings.crashReports, isFalse);
      await settings.close();
    },
  );

  testWidgets(
    'dark theme: library, notebook picker and editor render without errors',
    (tester) async {
      await launchApp(tester);
      final library = LibraryRobot(tester);
      final settings = SettingsRobot(tester);
      final editor = EditorRobot(tester);
      await library.waitForLibrary();

      await settings.open();
      await settings.setAppTheme(AppThemeMode.dark);
      await settings.setCanvasMode(CanvasDarkMode.followSystem);
      await settings.close();
      await library.waitForLibrary();
      expect(_brightnessOf(tester, find.byType(DocumentsScreen)),
          Brightness.dark);
      expectNoErrorWidgets('dark library');

      // Through the real picker, with a non-default cover and template.
      final cover = CoverRegistry.pickable[2];
      final template = TemplateRegistry.getById('grid')!;
      await NewNotebookRobot(tester).createThroughUi(
        'E2E Koyu',
        cover: cover,
        template: template,
      );
      await editor.waitForEditor();
      await tester.pumpUntilTrue(
        () => editor.read(documentProvider).title == 'E2E Koyu',
        reason: 'new notebook not loaded in the editor',
      );
      expectNoErrorWidgets('dark editor');

      final pages = editor.read(documentProvider).pages;
      expect(pages, hasLength(2));
      expect(pages.first.background.type, BackgroundType.cover);
      expect(pages.first.background.coverId, cover.id);
      expect(pages.last.background.templatePattern, template.pattern);
      // "Sistem" canvas theme follows the dark app theme.
      expect(
        editor.read(canvasColorSchemeProvider),
        CanvasColorScheme.dark(),
      );

      await editor.goHome();
      await library.waitForLibrary();
      await library.waitListed('E2E Koyu');
      expectNoErrorWidgets('dark library after editor');
    },
  );
}

/// Creates a notebook without opening it (no cover, blank paper).
Future<void> _createQuietly(WidgetTester tester, String title) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(DocumentsScreen)),
    listen: false,
  );
  final id = await container
      .read(documentsControllerProvider.notifier)
      .createDocument(title: title, templateId: 'blank', hasCover: false);
  expect(id, isNotNull, reason: 'notebook "$title" was not created');
}

Brightness _brightnessOf(WidgetTester tester, Finder finder) =>
    Theme.of(tester.element(finder.first)).brightness;

/// Whether tile [a] is laid out before tile [b] (rows, then columns).
bool _isFirst(WidgetTester tester, LibraryRobot library, String a, String b) {
  final pa = tester.getTopLeft(library.tileTitle(a));
  final pb = tester.getTopLeft(library.tileTitle(b));
  if ((pa.dy - pb.dy).abs() > 1) return pa.dy < pb.dy;
  return pa.dx < pb.dx;
}

void _expectFirst(
  WidgetTester tester,
  LibraryRobot library,
  String a,
  String b,
) {
  expect(_isFirst(tester, library, a, b), isTrue,
      reason: '"$a" should come before "$b" in the library');
}
