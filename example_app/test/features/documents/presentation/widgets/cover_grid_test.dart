import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/drawing_ui.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/widgets/cover_grid.dart';

Widget _host(ValueChanged<Cover> onSelected, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.light,
    home: Scaffold(
      body: SizedBox(
        width: 1200,
        height: 1600,
        child: CoverGridView(
          selectedCover: CoverRegistry.defaultCover,
          title: 'Biology',
          onCoverSelected: onSelected,
        ),
      ),
    ),
  );
}

void main() {
  void bigView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('lists only the pickable family', (tester) async {
    bigView(tester);
    await tester.pumpWidget(_host((_) {}));
    for (final c in CoverRegistry.pickable) {
      expect(find.text(c.name), findsOneWidget, reason: c.id);
    }
    expect(find.byType(CoverPreviewWidget), findsNWidgets(10));
  });

  testWidgets('tapping felt_mustard reports that cover', (tester) async {
    bigView(tester);
    Cover? picked;
    await tester.pumpWidget(_host((c) => picked = c));
    await tester.tap(find.text(CoverFamily.feltMustard.name));
    expect(picked?.id, 'felt_mustard');
  });

  testWidgets('item hit area is at least 48dp', (tester) async {
    bigView(tester);
    await tester.pumpWidget(_host((_) {}));
    final size = tester.getSize(find.byType(GestureDetector).first);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  test('label plate tokens mirror AppPalette.light', () {
    expect(CoverFamily.labelPlateColor, AppPalette.light.surface.toARGB32());
    expect(CoverFamily.labelInkColor, AppPalette.light.textPrimary.toARGB32());
  });
}
