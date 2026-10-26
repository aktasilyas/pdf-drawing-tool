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
    // A pattern, not an exact label: the cover's annotation can be absorbed
    // into an ancestor node whose label then holds more than the title.
    final cover = find.semantics.byLabel(RegExp('Biyoloji'));
    expect(cover, findsAny, reason: 'labels: ${semanticsLabels(tester)}');
    expect(
      cover.evaluate().first,
      isSemantics(
        isButton: true,
        hasTapAction: true,
        hasLongPressAction: true,
      ),
    );

    // Tap the middle of the cover box (as the frame's own tests do).
    final origin = tester.getTopLeft(find.byType(LibraryTileFrame));
    await tester.tapAt(origin + const Offset(75, 100));
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('the favourite badge is a labelled 48dp button', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      _host(LibraryFavoriteBadge(onTap: () => taps++)),
    );

    final badge = find.semantics.byLabel('Favorilerden çıkar');
    expect(badge, findsOne, reason: 'labels: ${semanticsLabels(tester)}');
    expect(
      badge.evaluate().single,
      isSemantics(isButton: true, hasTapAction: true),
    );
    await expectTapTargets(tester);

    await tester.tap(find.byType(LibraryFavoriteBadge));
    expect(taps, 1);
    handle.dispose();
  });
}
