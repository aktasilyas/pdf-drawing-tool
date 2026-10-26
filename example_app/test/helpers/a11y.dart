import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

// Accessibility assertions shared by the library and settings a11y tests.
// Ported from packages/drawing_ui/test/screens/editor_chrome_layout_test.dart
// so both packages report a guideline failure the same way.

/// Tappable semantics nodes smaller than 48x48, as short "label size"
/// strings, so a guideline failure names the widget on one log line.
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

/// Fails when a tappable node is smaller than the Android 48dp minimum,
/// naming the offenders.
Future<void> expectTapTargets(WidgetTester tester) async {
  final result = await androidTapTargetGuideline.evaluate(tester);
  expect(
    result.passed ? '' : smallTapTargets(tester).join(', '),
    isEmpty,
    reason: androidTapTargetGuideline.description,
  );
}

/// Renders at [scale] times the platform text size for the rest of the test.
void useTextScale(WidgetTester tester, double scale) {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Fails when laying out [what] reported an error (a `RenderFlex` overflow
/// is reported, not thrown, so it would otherwise only surface as noise).
void expectNoOverflow(WidgetTester tester, String what) {
  final error = tester.takeException();
  expect(error, isNull, reason: '$what overflowed: $error');
}
