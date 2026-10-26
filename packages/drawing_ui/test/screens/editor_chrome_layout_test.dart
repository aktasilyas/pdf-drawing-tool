import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../golden/helpers/editor_harness.dart';

/// Chrome spec (#52) hard rule: the toolbar band and the tablet sidebar take
/// layout space, so no canvas ever sits under them.
void main() {
  late SharedPreferences prefs;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  List<Rect> canvasRects(WidgetTester tester) {
    final canvases = find.byType(DrawingCanvas);
    expect(canvases, findsWidgets);
    return [
      for (final element in canvases.evaluate())
        tester.getRect(find.byElementPredicate((e) => e == element)),
    ];
  }

  Rect sidebarHostRect(WidgetTester tester) => tester.getRect(
        find
            .ancestor(
              of: find.byType(PageSidebar),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );

  void expectNoOverlap(List<Rect> canvases, Rect chrome, String what) {
    for (final canvas in canvases) {
      expect(
        canvas.overlaps(chrome),
        isFalse,
        reason: 'canvas $canvas overlaps $what $chrome',
      );
    }
  }

  // Evaluates each guideline directly so a failure names the offending
  // nodes on one line instead of only the guideline's description.
  Future<void> expectGuidelines(WidgetTester tester) async {
    final guidelines = [androidTapTargetGuideline, textContrastGuideline];
    for (final guideline in guidelines) {
      final evaluation = await guideline.evaluate(tester);
      expect(
        (evaluation.reason ?? '').replaceAll('\n', ' | '),
        isEmpty,
        reason: guideline.description,
      );
    }
  }

  const tabletSizes = <String, Size>{
    'landscape 1180x820': kEditorLandscape,
    'portrait 820x1180': kEditorPortrait,
  };

  for (final entry in tabletSizes.entries) {
    testWidgets('${entry.key}: canvas clears the band and the open sidebar',
        (tester) async {
      await pumpEditor(
        tester,
        size: entry.value,
        prefs: prefs,
        sidebarOpen: true,
      );

      final band = tester.getRect(find.byType(AdaptiveToolbar));
      final sidebar = sidebarHostRect(tester);
      expect(sidebar.width, kPageSidebarWidth);
      expect(sidebar.top, greaterThanOrEqualTo(band.bottom));

      final canvases = canvasRects(tester);
      expectNoOverlap(canvases, band, 'toolbar band');
      expectNoOverlap(canvases, sidebar, 'page sidebar');
      for (final canvas in canvases) {
        expect(canvas.top, greaterThanOrEqualTo(band.bottom));
        expect(canvas.left, greaterThanOrEqualTo(sidebar.right));
      }
    });

    testWidgets('${entry.key}: meets tap-target and contrast guidelines',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpEditor(
        tester,
        size: entry.value,
        prefs: prefs,
        sidebarOpen: true,
      );
      await expectGuidelines(tester);
      handle.dispose();
    });
  }

  testWidgets('phone 390x844: canvas clears both toolbar rows',
      (tester) async {
    await pumpEditor(tester, size: kEditorPhone, prefs: prefs);

    final band = tester.getRect(find.byType(AdaptiveToolbar));
    final canvases = canvasRects(tester);
    expectNoOverlap(canvases, band, 'toolbar band');
    for (final canvas in canvases) {
      expect(canvas.top, greaterThanOrEqualTo(band.bottom));
    }
    // The closed drawer is fully off screen.
    expect(
      tester.getRect(find.byType(PageSidebar)).right,
      lessThanOrEqualTo(0),
    );
  });

  testWidgets('phone 390x844: meets tap-target and contrast guidelines',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpEditor(tester, size: kEditorPhone, prefs: prefs);
    await expectGuidelines(tester);
    handle.dispose();
  });
}
