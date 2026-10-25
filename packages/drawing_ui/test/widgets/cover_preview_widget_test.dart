import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Cover cover, {String? title}) => MaterialApp(
      home: Center(
        child: SizedBox(
          width: 240,
          height: 320,
          child: CoverPreviewWidget(cover: cover, title: title),
        ),
      ),
    );

void main() {
  testWidgets('material cover title lies inside the label plate',
      (tester) async {
    await tester.pumpWidget(_host(CoverFamily.linenSage, title: 'Biology'));

    final root = tester.getRect(find.byType(CoverPreviewWidget));
    final plate = CoverRenderer.labelPlateRect(root.size).shift(root.topLeft);
    final text = tester.getRect(find.text('Biology').last);

    expect(plate.inflate(0.5).contains(text.topLeft), isTrue);
    expect(plate.inflate(0.5).contains(text.bottomRight), isTrue);
  });

  testWidgets('material cover has no ring-dot spine decoration',
      (tester) async {
    await tester.pumpWidget(_host(CoverFamily.feltMustard, title: 'x'));
    expect(find.byType(Column), findsNothing);
  });

  testWidgets('legacy solid cover still shows the ring decoration',
      (tester) async {
    await tester.pumpWidget(_host(
      const Cover(
        id: 'legacy_titled',
        name: 'Legacy',
        style: CoverStyle.solid,
        primaryColor: 0xFF1F2B44,
        showTitle: true,
      ),
      title: 'Math',
    ));
    expect(find.text('Math'), findsOneWidget);
    expect(find.byType(Column), findsOneWidget);
  });

  testWidgets('very long title wraps to at most two lines without overflow',
      (tester) async {
    await tester.pumpWidget(_host(
      CoverFamily.linenSage,
      title: 'An extraordinarily long notebook title that cannot possibly '
          'fit on a single line of the label plate',
    ));

    expect(tester.takeException(), isNull);
    final root = tester.getRect(find.byType(CoverPreviewWidget));
    final plate = CoverRenderer.labelPlateRect(root.size).shift(root.topLeft);
    final text = tester.getRect(find.byType(Text).last);
    expect(plate.inflate(0.5).contains(text.topLeft), isTrue);
    expect(plate.inflate(0.5).contains(text.bottomRight), isTrue);
    final render = tester.renderObject<RenderParagraph>(find.byType(RichText).last);
    expect(render.size.width, lessThanOrEqualTo(plate.width));
    expect(render.didExceedMaxLines, isTrue);
  });
}
