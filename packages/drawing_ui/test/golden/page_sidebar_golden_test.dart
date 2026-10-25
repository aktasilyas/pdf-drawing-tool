import 'package:alchemist/alchemist.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/chrome_theme.dart';
import 'helpers/sidebar_fixture.dart';

const double _height = 640;

/// Phone width and its drawer width: min(280, 85%).
const double _phoneWidth = 390;
const double _drawerWidth = 280;

Widget _scenario({
  required Brightness brightness,
  required SharedPreferences prefs,
  PageSidebarVariant variant = PageSidebarVariant.docked,
  SidebarFilter filter = SidebarFilter.allPages,
  Set<int> bookmarked = const {2},
}) {
  final pages = sidebarPages(5, bookmarked: bookmarked);
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      // v1.0 configuration: audio recording is frozen.
      audioRecordingEnabledProvider.overrideWithValue(false),
    ],
  );
  container.read(pageManagerProvider.notifier).initializeFromDocument(
        pages,
        currentIndex: 1,
      );
  container.read(sidebarFilterProvider.notifier).state = filter;
  final palette =
      brightness == Brightness.dark ? ChromePalette.dark : ChromePalette.light;
  final docked = variant == PageSidebarVariant.docked;
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: chromeTheme(brightness),
      home: Material(
        // Desk band behind the docked card; paper behind the drawer.
        color: docked ? palette.background : palette.paper,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: docked ? kPageSidebarWidth + ChromeSpacing.sm : _phoneWidth,
            height: _height,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: docked ? kPageSidebarWidth : _drawerWidth,
                height: _height,
                child: PageSidebar(
                  thumbnailCache: sidebarCache(pages),
                  variant: variant,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// Only the CI variant has committed baselines; platform goldens stay off.
Future<void> main() => AlchemistConfig.runWithConfig(
      config: const AlchemistConfig(
        platformGoldensConfig: PlatformGoldensConfig(enabled: false),
      ),
      run: _tests,
    );

Future<void> _tests() async {
  late SharedPreferences prefs;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  void sidebarGolden(String name, double width, Widget Function() build) {
    goldenTest(
      'page sidebar $name',
      fileName: 'page_sidebar_$name',
      constraints: BoxConstraints.tightFor(
        width: width + 48,
        height: _height + 64,
      ),
      builder: () => GoldenTestScenario(
        name: name,
        child: build(),
      ),
    );
  }

  const tabletWidth = kPageSidebarWidth + ChromeSpacing.sm;
  sidebarGolden(
    'tablet_light',
    tabletWidth,
    () => _scenario(brightness: Brightness.light, prefs: prefs),
  );
  sidebarGolden(
    'tablet_dark',
    tabletWidth,
    () => _scenario(brightness: Brightness.dark, prefs: prefs),
  );
  sidebarGolden(
    'phone_drawer_light',
    _phoneWidth,
    () => _scenario(
      brightness: Brightness.light,
      prefs: prefs,
      variant: PageSidebarVariant.drawer,
    ),
  );
  sidebarGolden(
    'empty_bookmarks_light',
    tabletWidth,
    () => _scenario(
      brightness: Brightness.light,
      prefs: prefs,
      filter: SidebarFilter.bookmarked,
      bookmarked: const {},
    ),
  );
}
