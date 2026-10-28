import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/providers/selection_capture_actions.dart';
import 'package:drawing_ui/src/widgets/selection_screenshot_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _EnSelection extends SelectionStringsTr {
  const _EnSelection();

  @override
  String get screenshotSaved => 'Screenshot saved';
}

class _EnStrings extends DrawingStringsTr {
  const _EnStrings();

  @override
  SelectionStrings get selection => const _EnSelection();
}

Future<BuildContext> _pump(WidgetTester tester, {DrawingStrings? scope}) async {
  late BuildContext ctx;
  final body = Scaffold(
    body: Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    }),
  );
  await tester.pumpWidget(MaterialApp(
    home:
        scope == null ? body : DrawingStringsScope(strings: scope, child: body),
  ));
  return ctx;
}

void main() {
  testWidgets('shows Turkish text without a scope', (tester) async {
    final ctx = await _pump(tester);
    showSelectionScreenshotFeedback(ctx, SelectionScreenshotOutcome.saved);
    await tester.pump();
    expect(find.text('Ekran resmi galeriye kaydedildi'), findsOneWidget);
  });

  testWidgets('uses the scope strings', (tester) async {
    final ctx = await _pump(tester, scope: const _EnStrings());
    showSelectionScreenshotFeedback(ctx, SelectionScreenshotOutcome.saved);
    await tester.pump();
    expect(find.text('Screenshot saved'), findsOneWidget);
  });

  testWidgets('a null context is ignored', (tester) async {
    await _pump(tester);
    showSelectionScreenshotFeedback(null, SelectionScreenshotOutcome.saved);
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
  });
}
