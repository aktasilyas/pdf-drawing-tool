import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/screens/drawing_screen_viewport.dart';

Size viewport({
  Size screen = const Size(1000, 800),
  bool isTablet = true,
  bool pageSidebarOpen = false,
  int pageCount = 3,
  bool externalOpen = false,
  double canvasHeight = 0,
}) =>
    computeCanvasViewport(
      screenSize: screen,
      isTablet: isTablet,
      isPageSidebarOpen: pageSidebarOpen,
      pageCount: pageCount,
      pageSidebarWidth: 200,
      isExternalSidebarOpen: externalOpen,
      externalSidebarWidth: 300,
      currentCanvasHeight: canvasHeight,
    );

void main() {
  group('computeCanvasViewport', () {
    test('full width and screen height when nothing is open', () {
      expect(viewport(), const Size(1000, 800));
    });

    test('tablet page sidebar shrinks the canvas', () {
      expect(viewport(pageSidebarOpen: true).width, 800);
    });

    test('page sidebar is ignored for single-page documents', () {
      expect(viewport(pageSidebarOpen: true, pageCount: 1).width, 1000);
    });

    test('external sidebar insets the canvas on tablet', () {
      expect(viewport(externalOpen: true).width, 700);
    });

    test('both sidebars add up', () {
      expect(viewport(pageSidebarOpen: true, externalOpen: true).width, 500);
    });

    test('phone sidebars are overlays and take no space', () {
      expect(
        viewport(isTablet: false, pageSidebarOpen: true, externalOpen: true)
            .width,
        1000,
      );
    });

    test('measured canvas height wins over screen height', () {
      expect(viewport(canvasHeight: 640).height, 640);
    });
  });
}
