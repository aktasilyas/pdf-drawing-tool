import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/panel_harness.dart';

void main() {
  const panel = ImagePanel();

  testWidgets('source rows are one labelled button each', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPanel(tester, panel);
    final c = tester.element(find.byType(ImagePanel)).drawingStrings.canvas;

    for (final (label, hint) in [
      (c.fromGallery, c.fromGalleryHint),
      (c.takePhoto, c.takePhotoHint),
    ]) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('^$label'))),
        isSemantics(
          label: '$label\n$hint',
          isButton: true,
          hasTapAction: true,
        ),
        reason: label,
      );
    }
    handle.dispose();
  });

  testWidgets('panel meets the tap-target guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPanel(tester, panel);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
