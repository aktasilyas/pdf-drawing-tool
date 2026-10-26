import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
    final rects = [
      for (final element in canvases.evaluate())
        tester.getRect(find.byElementPredicate((e) => e == element)),
    ];
    for (final rect in rects) {
      expect(rect.width, greaterThan(0));
      expect(rect.height, greaterThan(0));
    }
    return rects;
  }

  Rect sidebarHostRect(WidgetTester tester) {
    final host = find.ancestor(
      of: find.byType(PageSidebar),
      matching: find.byType(AnimatedContainer),
    );
    return tester.getRect(host.first);
  }

  void expectNoOverlap(List<Rect> canvases, Rect chrome, String what) {
    for (final canvas in canvases) {
      expect(
        canvas.overlaps(chrome),
        isFalse,
        reason: 'canvas $canvas overlaps $what $chrome',
      );
    }
  }

  // Tappable semantics nodes smaller than 48x48, as short "label/size"
  // strings, so a guideline failure names the widget on one log line.
  List<String> smallTapTargets(WidgetTester tester) {
    final found = <String>[];
    void visit(SemanticsNode node) {
      final data = node.getSemanticsData();
      final tap = data.hasAction(SemanticsAction.tap);
      final longPress = data.hasAction(SemanticsAction.longPress);
      final size = node.rect.size;
      final small = size.width < 47.9 || size.height < 47.9;
      if ((tap || longPress) && !node.isMergedIntoParent && small) {
        final parts = [data.label, data.tooltip, data.value];
        final name = parts.where((s) => s.isNotEmpty).join('/');
        final flat = name.replaceAll('\n', ' ');
        final w = size.width.round();
        final h = size.height.round();
        found.add('"$flat" ${w}x$h');
      }
      node.visitChildren((child) {
        visit(child);
        return true;
      });
    }

    for (final view in tester.binding.renderViews) {
      final root = view.owner?.semanticsOwner?.rootSemanticsNode;
      if (root != null) visit(root);
    }
    return found;
  }

  Future<void> expectGuidelines(WidgetTester tester) async {
    final tapTargets = await androidTapTargetGuideline.evaluate(tester);
    expect(
      tapTargets.passed ? '' : smallTapTargets(tester).join(', '),
      isEmpty,
      reason: androidTapTargetGuideline.description,
    );
    final contrast = await textContrastGuideline.evaluate(tester);
    expect(contrast.passed, isTrue, reason: contrast.reason);
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

      // Undo and redo live in the tools capsule; no pill over the page.
      expect(find.byType(FloatingUndoRedo), findsNothing);

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

  testWidgets('phone 390x844: canvas clears both toolbar rows', (tester) async {
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
