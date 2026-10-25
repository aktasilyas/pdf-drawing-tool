import 'package:drawing_ui/drawing_ui.dart' show CoverTextureStore;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/constants/storage_keys.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/screens/documents_screen.dart';

import '../../../../helpers/font_loader.dart';
import 'library_fixtures.dart';

typedef _Case = ({
  String name,
  Size size,
  bool dark,
  bool list,
  bool empty,
  bool selection,
});

_Case _case(
  String name,
  Size size, {
  bool dark = false,
  bool list = false,
  bool empty = false,
  bool selection = false,
}) =>
    (
      name: name,
      size: size,
      dark: dark,
      list: list,
      empty: empty,
      selection: selection,
    );

const _tablet = Size(1180, 820);
const _phone = Size(390, 844);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
    await loadManifestFonts();
    await CoverTextureStore.ensureLoaded();
  });

  final cases = <_Case>[
    _case('library_tablet_light_grid', _tablet),
    _case('library_tablet_dark_grid', _tablet, dark: true),
    _case('library_phone_light_grid', _phone),
    _case('library_phone_dark_grid', _phone, dark: true),
    _case('library_tablet_light_list', _tablet, list: true),
    _case('library_tablet_light_empty', _tablet, empty: true),
    _case('library_tablet_light_selection', _tablet, selection: true),
  ];

  for (final c in cases) {
    testWidgets(c.name, (tester) async {
      SharedPreferences.setMockInitialValues(
        c.list ? {StorageKeys.viewMode: 'list'} : {},
      );
      tester.view.physicalSize = c.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: libraryOverrides(empty: c.empty, selection: c.selection),
          child: MaterialApp(
            theme: c.dark ? AppTheme.dark : AppTheme.light,
            debugShowCheckedModeBanner: false,
            home: const DocumentsScreen(),
          ),
        ),
      );
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/${c.name}.png'),
      );
    });
  }
}
