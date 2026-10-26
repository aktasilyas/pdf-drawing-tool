import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/widgets/library_tile_frame.dart';
import 'package:example_app/features/documents/presentation/widgets/library_tile_parts.dart';

import '../../../../helpers/a11y.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('a tile cover is one button labelled with the title',
      (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 151,
          height: 252,
          child: LibraryTileFrame(
            cover: const ColoredBox(color: Colors.red),
            info: const LibraryTileInfo(title: 'Kapak', meta: '12 Eki'),
            onTap: () => taps++,
            onLongPress: () {},
            semanticLabel: 'Biyoloji',
          ),
        ),
      ),
    );

    // Only the cover carries the title label; the info block's own text is
    // a separate node ('Kapak' here) so this finder stays unambiguous.
    final cover = find.bySemanticsLabel('Biyoloji');
    expect(cover, findsOneWidget);
    expect(
      tester.getSemantics(cover),
      containsSemantics(
        label: 'Biyoloji',
        isButton: true,
        hasTapAction: true,
        hasLongPressAction: true,
      ),
    );

    await tester.tap(cover);
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('the favourite badge is a labelled 48dp button', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      _host(LibraryFavoriteBadge(onTap: () => taps++)),
    );

    final badge = find.bySemanticsLabel('Favorilerden çıkar');
    expect(badge, findsOneWidget);
    expect(
      tester.getSemantics(badge),
      containsSemantics(isButton: true, hasTapAction: true),
    );
    await expectTapTargets(tester);

    await tester.tap(badge);
    expect(taps, 1);
    handle.dispose();
  });
}
